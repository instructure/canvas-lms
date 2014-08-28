define [
  'ember'
  'ic-lazy-list'
  '../models/item'
], (Ember, LazyList, Item) ->

  ModuleItemComponent = LazyList.IcLazyListComponent.extend

    normalize: ({response}) ->
      (Item.createRecord(item) for item in response)

