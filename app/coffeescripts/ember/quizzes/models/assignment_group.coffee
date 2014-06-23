define [
  'ember-data'
], (DS) ->

  {attr} = DS

  DS.Model.extend
    groupWeight: attr()
    name: attr()
    links: attr()
    position: attr()
