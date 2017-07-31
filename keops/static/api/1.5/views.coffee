
class SearchMenu
  constructor: (@element, @parent, @options) ->
    @input = @parent.find('.search-view-input')
    @input.on 'input', (evt) =>
      console.log('change val')
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
    @searchView.first()

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
    @groups = []

  add: (item) ->
    if item in @items
      item.facet.addValue(item)
      item.facet.refresh()
    else
      @items.push(item)
      @searchView.renderFacets()
    if item instanceof SearchGroup
      @groups.push(item)
    @searchView.change()

  remove: (item) ->
    @items.splice(@items.indexOf(item), 1)
    item.facet.element.remove()
    delete item.facet
    if item instanceof SearchGroup
      @groups.splice(@groups.indexOf(item), 1)
    @searchView.change()

  getParams: ->
    r = []
    for i in @items
      r = r.concat(i.getParamValues())
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
    s = """<span class="facet-label">#{@item.getFacetLabel()}</span>"""
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
    @label = @item.attr('label') or (@ref and @ref['caption']) or @name

  templateLabel: ->
    """ Pesquisar <i>#{@label}</i> por: <strong>${search.text}</strong>"""

  template: ->
    s = ''
    if @expandable
      s = """<a class="expandable" href="#"></a>"""
    if @value
      s = """<a class="search-menu-item indent" href="#">#{@value[1]}</a>"""
    else
      s += "<a href=\"#\" class=\"search-menu-item\">#{@templateLabel()}</a>"
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
      @select(evt)
    .mouseover (evt) ->
      el = html.parent().find('>li.active')
      if el != html
        el.removeClass('active')
        html.addClass('active')

    @element.data('searchItem', @)

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

  select: (evt) ->
    if evt
      evt.stopPropagation()
      evt.preventDefault()
    @menu.select(evt, @)
    @menu.close()

  getFacetLabel: ->
    return @label

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
  constructor: (name, item, parent, ref, menu) ->
    if ref.type is 'ForeignKey'
      @expandable = true
      @children = []
    else
      @expandable = false
    super name, item, parent, ref, menu


class SearchFilter extends SearchItem


class SearchGroup extends SearchItem
  constructor: (name, item, parent, ref, menu) ->
    super name, item, parent, ref, menu
    ctx = item.attr('context')
    console.log(item)
    if typeof ctx is 'string'
      @context = JSON.parse(ctx)
    else
      @context =
        grouping: [name]

  getFacetLabel: ->
    '<span class="fa fa-bars"></span>'

  templateLabel: ->
    Katrid.i18n.gettext('Group by:') + ' ' + @label

  getDisplayValue: ->
    return @label


class SearchView
  constructor: (@scope, options) ->
    @query = new SearchQuery(@)
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
  <ul class="search-dropdown-menu search-view-menu" role="menu"></ul>
  </div>
</div>
"""

  inputKeyDown: (ev) =>
    switch ev.keyCode
      when Katrid.UI.keyCode.DOWN
        @move(1)
        ev.preventDefault()
      when Katrid.UI.keyCode.UP
        @move(-1)
        ev.preventDefault()
      when Katrid.UI.keyCode.ENTER
        @selectItem(ev, @element.find('.search-view-menu > li.active'))
    return

  move: (distance) ->
    fw = distance > 0
    distance = Math.abs(distance)
    while distance isnt 0
      distance--
      el = @element.find('.search-view-menu > li.active')
      if el.length
        el.removeClass('active')
        if fw
          el = el.next()
        else
          el = el.prev()
        el.addClass('active')
      else
        if fw
          el = @element.find('.search-view-menu > li').first()
        else
          el = @element.find('.search-view-menu > li').last()
        el.addClass('active')
    return

  selectItem: (ev, el) ->
    el.data('searchItem').select(ev)
    return

  link: (scope, el, attrs, controller, $compile) ->
    html = $compile(@template())(scope)
    el.replaceWith(html)
    html.addClass(attrs.class)

    @$compile = $compile
    @view = scope.views.search
    @viewContent = $(@view.content)
    @element = html
    @searchView = html.find('.search-view')
    @searchView.find('.search-view-input').keydown @inputKeyDown


    html.find('.search-view-more').click (evt) =>
      $(evt.target).toggleClass('fa-search-plus fa-search-minus')
      @viewMoreToggle()
    @menu = @createMenu(scope, $(html.find('.search-dropdown-menu.search-view-menu')), html)
    @menu.searchView = @
    @menu.link()

    # input key control events
    @menu.input.on 'keydown', (evt) ->

    # add items to menu
    for item in @viewContent.children()
      @loadItem $(item)
    return

  loadItem: (item, value, parent, cls) ->
    tag = item.prop('tagName')
    if not cls?
      if tag is 'FIELD'
        cls = SearchField
      else if tag is 'FILTER'
        cls = SearchFilter
      else if tag is 'GROUP'
        console.log('group', item)
        for grouping in item.children()
          @loadItem($(grouping), null, null, SearchGroup)
        return

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

  first: ->
    @element.find('.search-view-menu > li.active').removeClass('active')
    @element.find('.search-view-menu > li').first().addClass('active')

  onSelectItem: (evt, obj) =>
    @query.add(obj)

  onRemoveItem: (evt, obj) =>
    @query.remove(obj)

  change: ->
    if @query.groups.length or (@scope.dataSource.groups and @scope.dataSource.groups.length)
      @scope.action.applyGroups(@query.groups)
    if @query.groups.length is 0
      @scope.action.setSearchParams(@query.getParams())


Katrid.UI.Views =
  SearchView: SearchView
  SearchMenu: SearchMenu
