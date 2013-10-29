define [
  'Backbone'
  'jst/content_migrations/subviews/OverwriteAssessmentContent'
], (Backbone, template) -> 
  class OverwriteAssessmentContentView extends Backbone.View
    template: template

    events:
      "change #overwriteAssessmentContent" : "setAttribute"

    setAttribute: =>
      settings = @model.get('settings') || {}
      settings.overwrite_quizzes = !!@$el.find('#overwriteAssessmentContent').is(":checked")
      @model.set('settings', settings)
