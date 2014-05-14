define [
  'i18n!discussions'
  'jquery'
  'compiled/views/DialogFormView'
  'compiled/models/DiscussionsSettings'
  'compiled/models/UserSettings'
  'jst/DiscussionTopics/DiscussionsSettingsView'
], (I18n, $, DialogFormView, DiscussionsSettings, UserSettings, template) ->

  class DiscussionsSettingsView extends DialogFormView

    defaults:
      title: I18n.t "edit_settings", "Edit Discussions Settings"

    template: template

    initialize: ->
      super
      @model      or= new DiscussionsSettings
      @userSettings = new UserSettings
      @fetch()

    render: () ->
      super(arguments)
      @$el
        .find('#manual_mark_as_read')
        .prop('checked', @userSettings.get('manual_mark_as_read'))

    submit: (event) ->
      super(event)
      @userSettings.set('manual_mark_as_read', @$el.find('#manual_mark_as_read').prop('checked'))
      @userSettings.save()

    fetch: ->
      isComplete = $.Deferred()
      $.when(@model.fetch(), @userSettings.fetch()).then =>
        isComplete.resolve()
        @render()
      @$el.disableWhileLoading(isComplete)

