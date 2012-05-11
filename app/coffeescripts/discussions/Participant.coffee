define ['Backbone', 'i18n!discussions.participant'], (Backbone, I18n) ->

  class Participant extends Backbone.Model

    defaults:
      avatar_image_url: ''
      display_name: I18n.t('anonymous_user', 'Anonymous')
      id: null

