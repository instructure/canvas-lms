define [
  'jquery'
  'underscore'
  'Backbone'
  'jst/roles/courseRoles'
], ($, _, Backbone, template) -> 
  class CourseRolesView extends Backbone.View
    template: template
