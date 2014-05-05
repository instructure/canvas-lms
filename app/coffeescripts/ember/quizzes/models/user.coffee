define [
  'ember'
  'ember-data'
], (Em, DS, ajax) ->

  {alias, equal, any} = Em.computed
  {belongsTo, hasMany, Model, attr} = DS

  User = Model.extend
    quizSubmissions: hasMany 'quiz_submission', async: false
    name: attr()
    shortName: attr()
    sortableName: attr()
