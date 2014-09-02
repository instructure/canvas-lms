define [
  'i18n!outcomes'
  'underscore'
  'Backbone'
  'jst/grade_summary/progress_bar'
], (I18n, _, Backbone, template) ->
  class ProgressBarView extends Backbone.View
    className: 'bar'
    template: template
