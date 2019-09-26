define [
  'jquery'
  'Backbone'
  'react'
  'react-dom'
  'jsx/assignments/StudentExemptions',
  'jst/assignments/StudentExemptionsTemplate'
], (
  $,
  Backbone,
  React,
  ReactDOM,
  StudentExemptions,
  StudentExemptionsTemplate
) ->
    class ExcludeStudentsView extends Backbone.View
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
          StudentExemptions,
          syncWithBackbone: @setNewExcludesCollection,
          students: @model.students,
          exemptions: @model.excludes,
          delayMessage: true,
          labelMessage: "Excuse these students from this assignment"
        )
        ReactDOM.render(StudentExemptionsElement, div)
