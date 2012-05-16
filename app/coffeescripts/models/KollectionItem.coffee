define [
  'Backbone'
  'underscore'
], (Backbone, _) ->

  class KollectionItem  extends Backbone.Model

    urlRoot: ->
      "/api/v1/collections/#{@kollection.id}/items"

    fetchLinkData: _.once ->
      dfd = $.post '/collection_items/link_data', url: @get('link_url')
      dfd.done (data) =>
        @set data
        @set('image_url', data.images?[0]?.url) unless @get('image_url')

    changeImage: (offset) ->
      images = @get('images')
      image_url = @get('image_url')
      currentImage = _(images).find ({url}) -> url is image_url
      currentIndex = _(images).indexOf currentImage
      newImage = images[(currentIndex + offset + images.length) % images.length]
      @set('image_url', newImage.url)

    toJSON: ->
      res = super
      res.collection_id = @kollection?.get 'id'
      res