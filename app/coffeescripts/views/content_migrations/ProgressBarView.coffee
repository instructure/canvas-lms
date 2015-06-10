define [
  'Backbone'
  'jst/content_migrations/ProgressBar',
  'i18n!progressbar_view'
], (Backbone, template, I18n) ->
  class ProgressBarView extends Backbone.View
    template: template

    els:
      '.progress' : '$progress'

    initialize: =>
      super
      @listenTo @model, "change:completion", =>
        integer = Math.floor @model.changed?.completion
        message = I18n.t('Content migration running, %{percent}% complete',{
            percent: integer
          })
        $.screenReaderFlashMessageExclusive(message)
        @render()

    toJSON: ->
      json = super
      json.completion = @model.get('completion')
      json
