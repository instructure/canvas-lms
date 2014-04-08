define [
  'ember'
  'ic-lazy-list'
  '../models/item'
], (Ember, LazyListComponent, Item) ->

  ModuleItemComponent = LazyListComponent.extend

    normalize: ({response}) ->
      (Item.createRecord(item) for item in response)

