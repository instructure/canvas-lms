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
          exemptions: @model.excludes
        )
        ReactDOM.render(StudentExemptionsElement, div)
