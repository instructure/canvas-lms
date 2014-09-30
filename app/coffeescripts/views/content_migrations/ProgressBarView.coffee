define [
  'Backbone'
  'jst/content_migrations/ProgressBar'
], (Backbone, template) -> 
  class ProgressBarView extends Backbone.View
    template: template

    els:
      '.progress' : '$progress'

    initialize: =>
      super
      @listenTo @model, "change:completion", => @render()

    toJSON: -> 
      json = super
      json.completion = @model.get('completion')
      json
