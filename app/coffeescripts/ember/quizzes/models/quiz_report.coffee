define [
  'ember'
  'ember-data',
  '../mixins/queriable_model'
], (Em, DS, QueriableModel) ->
  {Model, attr, belongsTo} = DS

  Model.extend(QueriableModel, {
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
  })