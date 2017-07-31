
class SearchView
  constructor: (scope, options) ->
    @onSelect = options.onSelect

  render: ->
    return """
<div class="search-view">
  <span class="search-view-more fa fa-search-plus"></span>
</div>
"""

  link: (el) ->
    el.find('.search-view-more').click (evt) =>
      evt.toggleClass('fa-search-plus fa-search-minus')
