define [
  'ember-data'
  '../mixins/queriable_model'
], (DS, QueriableModel) ->
  {attr} = DS

  DS.Model.extend(QueriableModel, {
    quiz: DS.belongsTo 'quiz', async: false

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