define [
  'Backbone'
  'underscore'
  'vendor/jquery.ba-tinypubsub'
  'compiled/models/Topic'
], (Backbone, _, {subscribe}, Topic) ->

  class KollectionItem  extends Backbone.Model


    # non-standard url handling
    parse: ->
      res = super
      @url = res.url if res.url
      res

    # same as Backbone's default url function but reverses the priority of
    # this.collection.url and this.rootUrl
    url: ->
      if @isNew()
        _.result(this.collection, 'url')
      else
        "/api/v1/collections/items/#{encodeURIComponent(@id)}"

    initialize: ->
      @commentTopic = new Topic
      @commentTopic.url = => "/api/v1/collection_items/#{@id}/discussion_topics/self"
      _.each ['upvote', 'deupvote'], (action) =>
        subscribe "#{action}Item", (itemId) =>
          @set('upvoted_by_user', action is 'upvote') if itemId == @id

    fetchLinkData: ->
      @set 'state', 'loading'
      @lastDfd?.abort()
      @lastDfd = $.post '/collection_items/link_data', url: @get('link_url')
      @lastDfd.done (data) =>
        if data.title
          @set 'state', 'loaded'
        else
          @set 'state', 'noData'
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
      res.collection_id ||= @kollection?.get('id')
      res
