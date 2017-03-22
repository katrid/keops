
class SearchMenu
  constructor: (@element, @parent, @options) ->
    @input = @parent.find('.search-view-input')
    @input.on 'keyup', (evt) =>
      if @input.val().length
        @show()
      else
        @close()
    .on 'keydown', (evt) =>
      switch evt.which
        when $.ui.keyCode.BACKSPACE
          if @input.val() is ''
            item = @searchView.query.items[@searchView.query.items.length-1]
            @searchView.onRemoveItem(evt, item)
          break
    .on 'blur', (evt) =>
      @input.val('')
      @close()

  link: ->
    @element.hide()

  show: ->
    @element.show()

  close: ->
    @element.hide()
    @reset()

  expand: (item) ->
    scope = @searchView.scope
    scope.model.getFieldChoices(item.ref.name, scope.search.text)
    .then (res) =>
      if res.ok
        for obj in res.result
          @searchView.loadItem(item.item, obj, item)

  collapse: (item) ->
    for i in item.children
      i.remove()
    item.children = []

  reset: ->
    for i in @searchView.items
      if i.children and i.children.length
        @collapse(i)
        i.reset()

  select: (evt, item) ->
    if @options.select
      if item.parentItem
        item.parentItem.value = item.value
        item = item.parentItem
      item.searchString = @input.val()
      @options.select(evt, item)
      @input.val('')


class SearchQuery
  constructor: (@searchView) ->
    @items = []

  add: (item) ->
    if item in @items
      item.facet.addValue(item)
      item.facet.refresh()
    else
      @items.push(item)
      @searchView.renderFacets()
    @searchView.change()

  remove: (item) ->
    console.log('remove item', item)
    @items.splice(@items.indexOf(item), 1)
    item.facet.element.remove()
    delete item.facet
    @searchView.change()

  getParams: ->
    r = []
    for i in @items
      r = r.concat(i.getParamValues())
    console.log('params', r)
    return r


# TODO remove this class
class FacetView
  constructor: (@item) ->
    @values = [{searchString: @item.getDisplayValue(), value: @item.value}]

  addValue: (@item) ->
    @values.push({searchString: @item.getDisplayValue(), value: @item.value})

  templateValue: ->
    sep = """ <span class="facet-values-separator">#{Katrid.i18n.gettext('or')}</span> """
    return (s.searchString for s in @values).join(sep)

  template: ->
    s = ''
    if @item.ref
      s = """<span class="facet-label">#{@item.label}</span>"""
    """<div class="facet-view">
#{s}
<span class="facet-value">#{@templateValue()}</span>
<span class="fa fa-sm fa-remove facet-remove"></span>
</div>"""

  link: (searchView) ->
    html = $(@template())
    @item.facet = @
    @element = html
    rm = html.find('.facet-remove')
    rm.click (evt) =>
      searchView.onRemoveItem(evt, @item)
    return html

  refresh: ->
    @element.find('.facet-value').html(@templateValue())


class SearchItem
  constructor: (@name, @item, @parent, @ref, @menu) ->
    if @ref.type is 'ForeignKey'
      @expandable = true
      @children = []
    else
      @expandable = false

    @label = @item.attr('caption') or (@ref and @ref['caption']) or @name

  template: ->
    s = ''
    if @expandable
      s = """<a class="expandable" href="#"></a>"""
    if @value
      s = """<a class="search-menu-item indent" href="#">#{@value[1]}</a>"""
    else
      lbl = @label
      if lbl
        s += "<a href=\"#\" class=\"search-menu-item\"> Pesquisar <i>#{lbl}</i> por: <strong>${search.text}</strong></a>"
    return """<li>#{s}</li>"""

  link: (scope, $compile, parent) ->
    html = $compile(@template())(scope)
    if parent?
      html.insertAfter(parent.element)
      parent.children.push(@)
      @parentItem = parent
    else
      html.appendTo(@parent)

    @element = html

    @itemEl = html.find('.search-menu-item').click (evt) ->
      evt.preventDefault()
    .mousedown (evt) =>
      evt.stopPropagation()
      evt.preventDefault()
      @menu.select(evt, @)
      @menu.close()

    @expand = html.find('.expandable').on 'mousedown', (evt) =>
      @expanded = not @expanded
      evt.stopPropagation()
      evt.preventDefault()
      $(evt.target).toggleClass('expandable expanded')
      if @expanded
        @searchView.menu.expand(@)
      else
        @searchView.menu.collapse(@)
    .click (evt) ->
      evt.preventDefault()
    return false

  getDisplayValue: ->
    if @value
      return @value[1]
    return @searchString

  getValue: ->
    return (s.value or s.searchString for s in @facet.values)

  getParamValue: (name, value) ->
    r = {}
    if $.isArray(value)
      r[name] = value[0]
    else
      r[name + '__icontains'] = value
    return r

  getParamValues: ->
    r = []
    for v in @getValue()
      r.push(@getParamValue(@name, v))
    if r.length > 1
      return [{'OR': r}]
    return r

  remove: ->
    @element.remove()

  reset: ->
    @expanded = false
    @expand.removeClass('expanded')
    @expand.addClass('expandable')


class SearchField extends SearchItem


class SearchFilter extends SearchItem


class SearchView

  constructor: (@scope, options) ->
    @query = new SearchQuery(@)
    console.log(@)
    @items = []

  createMenu: (scope, el, parent) ->
    menu = new SearchMenu(el, parent, {select: @onSelectItem})
    menu.searchView = @
    return menu

  template: ->
    html = """
<div class="search-area">
  <div class="search-view">
    <div class="search-view-facets"></div>
    <input class="search-view-input" role="search" placeholder="#{Katrid.i18n.gettext('Search...')}" ng-model="search.text">
    <span class="search-view-more fa fa-search-plus"></span>
  </div>
  <div class="col-sm-12">
  <ul class="dropdown-menu search-view-menu" role="menu"></ul>
  </div>
</div>
"""

  link: (scope, el, attrs, controller, $compile) ->
    html = $compile(@template())(scope)
    el.replaceWith(html)
    html.addClass(attrs.class)

    @$compile = $compile
    @view = scope.views.search
    searchView = $(@view.content)
    @element = html
    @searchView = html.find('.search-view')
    html.find('.search-view-more').click (evt) =>
      $(evt.target).toggleClass('fa-search-plus fa-search-minus')
      @viewMoreToggle()
    @menu = @createMenu(scope, $(html.find('.dropdown-menu.search-view-menu')), html)
    @menu.searchView = @
    @menu.link()

    # input key control events
    @menu.input.on 'keydown', (evt) ->

    # add items to menu
    for item in searchView.children()
      @loadItem $(item)
    return

  loadItem: (item, value, parent) ->
    console.log('item', value, parent)
    tag = item.prop('tagName')
    if tag is 'FIELD'
      cls = SearchField
    else if tag is 'FILTER'
      cls = SearchFilter

    name = item.attr('name')
    item = new cls(name, item, @menu.element, @view.fields[name], @menu)
    item.searchView = @
    if value
      item.expandable = false
      item.value = value
    item.link(@scope, @$compile, parent)

    @items.push(item)

  renderFacets: ->
    for item in @query.items
      if not item.facet
        f = new FacetView(item)
        el = f.link(@)
        el.insertBefore(@menu.input)

  viewMoreToggle: ->
    @viewMore = not @viewMore
    @scope.$apply =>
      console.log(@viewMore)
      @scope.search.viewMoreButtons = @viewMore

  onSelectItem: (evt, obj) =>
    @query.add(obj)

  onRemoveItem: (evt, obj) =>
    @query.remove(obj)

  change: ->
    @scope.action.setSearchParams(@query.getParams())


Katrid.UI.Views =
  SearchView: SearchView
  SearchMenu: SearchMenu
