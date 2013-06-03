define [
  'i18n!discussions'
  'compiled/views/DialogFormView'
  'compiled/models/UserSettings'
  'jst/DiscussionTopics/UserSettingsView'
], (I18n, DialogFormView, UserSettings, template) ->

  class UserSettingsView extends DialogFormView

    defaults:
      title: I18n.t "edit_settings", "Edit Discussions Settings"

    template: template

    initialize: ->
      super
      @model or= new UserSettings
      @attachModel()
      @fetch()

    attachModel: ->
      @model.on 'change', @render

    fetch: ->
      @$el.disableWhileLoading(@model.fetch())

