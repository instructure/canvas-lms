define [
  'Backbone'
  'jst/accounts/admin_tools/gradeChangeLoggingItem'
  'i18n!auth_logging'
], (Backbone, template, I18n) ->
  class GradeChangeLoggingItemView extends Backbone.View
    tagName: 'tr'
    className: 'logitem'
    template: template
