define [
  'jquery'
  'underscore'
  'Backbone'
  'sfu_course_form/compiled/models/Term'
], ($, _, Backbone, Term) ->

  class TermList extends Backbone.Collection

    model: Term

    fetchAllCourses: (@userId) -> @each @fetchCoursesForTerm, this

    fetchCoursesForTerm: (term) -> term.fetchCourses @userId
