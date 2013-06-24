define [
  'Backbone'
  'jst/content_migrations/subviews/OverwriteAssessmentContent'
], (Backbone, template) -> 
  class OverwriteAssessmentContentView extends Backbone.View
    template: template
