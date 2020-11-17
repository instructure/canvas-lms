define [
    'backbone',
    'jsx/courses/DueDateWizard',
    'react',
    'react-dom'
    ], (Backbone, DueDateWizard, React, ReactDOM) ->

    class DueDateWizardView extends Backbone.View
      el:
        document.getElementById('due-date-wizard')

      initialize: (options) ->
        @render()

      render: ->
        DueDateWizardElement = React.createElement(
          DueDateWizard,
          course: ENV.course
        )
        ReactDOM.render(DueDateWizardElement, @el)