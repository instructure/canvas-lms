define [
  'jquery'
  'Backbone'
  'react'
  'react-dom'
  'jsx/assignments/StudentUnassign',
  'jst/assignments/StudentExemptionsTemplate'
], (
  $,
  Backbone,
  React,
  ReactDOM,
  StudentUnassignments,
  StudentExemptionsTemplate
) ->
  class UnassignStudentsView extends Backbone.View
    template: StudentExemptionsTemplate
# ==============================
#     syncing with react data
# ==============================

    setNewExcludesCollection: (newExcludes) =>
      @model.resetExcludes(newExcludes)

    getExcludedStudents: () =>
      @model.excludes

    render: ->
      div = @$el[0]
      return unless div
      StudentExemptionsElement = React.createElement(
        StudentUnassignments,
        syncWithBackbone: @setNewExcludesCollection,
        students: @model.students,
        exemptions: @model.excludes,
        delayMessage: false,
        labelMessage: "Remove these students from this assignment"
      )
      ReactDOM.render(StudentExemptionsElement, div)
