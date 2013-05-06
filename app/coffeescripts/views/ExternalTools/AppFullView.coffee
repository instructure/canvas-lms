define [
  'Backbone'
  'jquery'
  'jst/ExternalTools/AppFullView'
  'compiled/views/PaginatedCollectionView'
  'compiled/views/ExternalTools/AppReviewView'
  'compiled/collections/PaginatedCollection'
  'vendor/jquery.raty'
], (Backbone, $, template, PaginatedCollectionView, AppReviewView, PaginatedCollection) ->

  class AppFullView extends PaginatedCollectionView
    template: template
    itemView: AppReviewView
    className: 'app_full'

    events:
      'click .add_app': 'addApp'
      'click .app_cancel': 'cancel'

    initialize: ->
      @collection = new PaginatedCollection
      super

      @render()
      @collection.resourceName = "app_center/apps/#{@model.id}/reviews"
      @collection.fetch()

    afterRender: ->
      @$('.app-star').raty
        readOnly: true
        score: @model.get('avg_rating')
        path: '/images/raty/'

    addApp: (e) =>
      e.preventDefault() if e
      @trigger 'addApp', this

    cancel: (e) ->
      e.preventDefault() if e
      @trigger 'cancel', this