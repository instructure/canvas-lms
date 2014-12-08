define [
  'ember'
  'ic-lazy-list'
  'ic-ajax'
], (Ember, LazyList, ajax) ->

  GroupsLazyList = LazyList.IcLazyListComponent.extend
    request: (href) ->
      ajax.raw(href, {dataType: 'json'})
