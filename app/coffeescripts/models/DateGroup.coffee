define [
  'Backbone'
  'underscore'
  'jquery'
  'i18n!assignments'
], (Backbone, _, $, I18n) ->

  class DateGroup extends Backbone.Model

    defaults:
      title: I18n.t('everyone_else', 'Everyone else')
      due_at: null
      unlock_at: null
      lock_at: null
