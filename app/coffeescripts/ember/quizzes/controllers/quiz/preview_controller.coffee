define [
  'ember'
  './show_controller'
  'i18n!quiz_show'
], (Ember, ShowController, I18n) ->

  ShowController.extend
    isPreview: true

