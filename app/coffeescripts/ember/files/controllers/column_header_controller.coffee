define [
  'ember'
], (Ember) ->

  ColumnHeaderController = Ember.ObjectController.extend
    sortColumn: Ember.computed.alias("parentController.sortedColumn")
    sortAscending: Ember.computed.alias("parentController.sortAscending")
    sortDescending: Ember.computed.not("sortAscending")
    isSorted: Ember.computed 'sortColumn', 'property', -> @get('sortColumn') is @get('property')
    sortedAsc: Ember.computed.and("sortAscending", "isSorted")
    sortedDesc: Ember.computed.and("sortDescending", "isSorted")