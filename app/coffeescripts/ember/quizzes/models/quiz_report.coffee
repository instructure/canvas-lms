define [
  'ember'
  'ember-data'
], (Em, DS) ->
  {Model, attr, belongsTo} = DS

  Model.extend
    quiz: belongsTo 'quiz', async: false

    anonymous: attr()
    includesAllVersions: attr()
    reportType: attr()
    createdAt: attr('date')
    updatedAt: attr('date')
    file: attr()
    progress: attr()
    progressUrl: attr()
    url: attr()