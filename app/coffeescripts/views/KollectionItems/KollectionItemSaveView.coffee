define [
  'Backbone'
  'underscore'
  'compiled/fn/preventDefault'
  'compiled/models/KollectionItem'
  'compiled/views/KollectionItems/LinkDataView'
  'compiled/views/Kollections/SelectKollectionView'
  'compiled/collections/KollectionCollection'
  'jst/KollectionItems/KollectionItemSaveView'
  'jquery.disableWhileLoading'
  'jst/_avatar'
], (Backbone, _, preventDefault, KollectionItem, LinkDataView, SelectKollectionView, KollectionCollection, KollectionItemSaveViewTemplate) ->

  class KollectionItemSaveView extends Backbone.View

    template: KollectionItemSaveViewTemplate

    events:
      'submit form' : 'save'
      'change [name=user_comment]' : 'setUserComment'

    initialize: ->
      @kollections = new KollectionCollection
      @kollections.fetch()
      @render()
      @model.on 'sync', @render

    render: =>
      locals = @model.toJSON()

      # TODO: handle this in a better way
      locals.avatar_image_url = "/images/users/#{@model.get('user_id')}"

      @$el.html @template(locals)
      @linkDataView = new LinkDataView
        el: @$('.linkDataView')
        model: @model
      new SelectKollectionView
        el: @$('.SelectKollectionView')
        model: @model
        collection: @kollections

    save: preventDefault ->
      @$el.disableWhileLoading @model.save()

    setUserComment: (event) ->
      @model.set 'user_comment', event.target.value
