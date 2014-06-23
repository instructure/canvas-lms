define [
  'ember-data'
], (DS) ->
  {attr, hasMany, belongsTo} = DS

  AssignmentOverride = DS.Model.extend
    dueAt: attr 'date'
    lockAt: attr 'date'
    sectionID: attr()
    unlockAt: attr 'date'
    title: attr()
