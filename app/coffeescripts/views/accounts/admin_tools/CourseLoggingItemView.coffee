define [
  'jquery'
  'Backbone'
  'i18n!course_logging'
  'jst/accounts/admin_tools/courseLoggingItem'
], ($, Backbone, I18n, template) ->
  class CourseLoggingItemView extends Backbone.View
    tagName: 'tr'
    className: 'logitem'
    template: template