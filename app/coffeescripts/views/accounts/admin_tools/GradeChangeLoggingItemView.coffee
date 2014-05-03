define [
  'Backbone'
  'jst/accounts/admin_tools/gradeChangeLoggingItem'
], (Backbone, template) ->
  class GradeChangeLoggingItemView extends Backbone.View
    tagName: 'tr'
    className: 'logitem'
    template: template
