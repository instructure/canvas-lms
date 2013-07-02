define [
  'jquery'
  'Backbone'
  'jst/Modules/ModuleItemView'
  'i18n!context_modules'
], ($, Backbone, template, I18n) ->

  class ModuleItemView extends Backbone.View

    template: template