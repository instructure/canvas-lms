define [
  'Backbone'
  'jst/content_migrations/ProgressBar'
], (Backbone, template) -> 
  class ProgressBarView extends Backbone.View
    template: template

    els:
      '.progress' : '$progress'

    afterRender: -> 
      @model.on 'change:completion', => @render()

    toJSON: -> 
      json = super
      json.completion = @model.get('completion')
      json
