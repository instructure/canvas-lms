define [
  'jquery'
  'Backbone'
  'jst/ExternalTools/AppReviewView'
], ($, Backbone, template) ->

  class AppReviewView extends Backbone.View
    template: template

    afterRender: ->
      @$('img.avatar_image').error @fixAvatar

    fixAvatar: (event, data) ->
      img = $(event.currentTarget)
      img.attr('src', '/images/avatar-50.png')

    toJSON: ->
      json = super
      unless json.user_avatar_url
        json.user_avatar_url = '/images/avatar-50.png'
      json