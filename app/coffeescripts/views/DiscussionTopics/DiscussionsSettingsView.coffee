define [
  'i18n!discussions'
  'compiled/views/DialogFormView'
  'compiled/models/DiscussionsSettings'
  'jst/DiscussionTopics/DiscussionsSettingsView'
], (I18n, DialogFormView, DiscussionsSettings, template) ->

  class DiscussionsSettingsView extends DialogFormView

    defaults:
      title: I18n.t "edit_settings", "Edit Discussions Settings"

    template: template

    initialize: ->
      super
      @model or= new DiscussionsSettings
      @attachModel()
      @fetch()

    attachModel: ->
      @model.on 'change', @render

    fetch: ->
      dfd = @model.fetch()
      @$el.disableWhileLoading dfd

