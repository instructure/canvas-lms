define [
  'underscore'
  'Backbone'
  'compiled/collections/PaginatedCollection'
  'compiled/models/WikiPageRevision'
], (_, Backbone, PaginatedCollection, WikiPageRevision) ->

  revisionOptions = ['parentModel']

  class WikiPageRevisionsCollection extends PaginatedCollection
    model: WikiPageRevision

    url: ->
      "#{@parentModel.url()}/revisions"

    initialize: (models, options) ->
      super
      _.extend(this, _.pick(options || {}, revisionOptions))

      if @parentModel
        collection = @
        parentModel = collection.parentModel
        setupModel = (model) ->
          model.page = parentModel
          model.pageUrl = parentModel.get('url')
          model.contextAssetString = parentModel.contextAssetString
          collection.latest = model if !!model.get('latest')

        @on 'reset', (models) ->
          models.each setupModel
        @on 'add', (model) ->
          setupModel(model)
