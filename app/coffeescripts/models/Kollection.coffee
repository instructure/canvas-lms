define [
  'Backbone'
  'underscore'
  'compiled/collections/KollectionItemCollection'
  'vendor/jquery.ba-tinypubsub'
], (Backbone, _, KollectionItemCollection, {subscribe}) ->

  class Kollection  extends Backbone.Model

    urlRoot: '/api/v1/collections'

    initialize: ->
      @kollectionItems ||= new KollectionItemCollection
      @kollectionItems.url = => "/api/v1/collections/#{encodeURIComponent(@id)}/items"

      _.each ['follow', 'unfollow'], (action) =>
        subscribe action, (followableId, followableType) =>
          if followableId == @id && followableType == 'collection'
            @set 'followed_by_user', action is 'follow'
