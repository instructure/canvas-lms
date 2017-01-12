define [
  'react'
  'underscore'
  'jsx/grading/gradingPeriodTemplate'
], (React, _, GradingPeriod) ->

  TestUtils = React.addons.TestUtils

  module 'GradingPeriod with read-only permissions',
    renderComponent: (opts) ->
      defaultProps =
        title: "Spring"
        startDate: new Date("2015-03-01T00:00:00Z")
        endDate: new Date("2015-05-31T00:00:00Z")
        id: "1"
        readOnly: false
        permissions: {
          update: false
          delete: false
        }
        onDeleteGradingPeriod: ->

      @props = _.defaults(opts || {}, defaultProps)
      GradingPeriodElement = React.createElement(GradingPeriod, @props)
      @gradingPeriod = TestUtils.renderIntoDocument(GradingPeriodElement)

    teardown: ->
      React.unmountComponentAtNode(@gradingPeriod.getDOMNode().parentNode)

  test 'isNewGradingPeriod returns false if the id does not contain "new"', ->
    gradingPeriod = @renderComponent()
    equal gradingPeriod.isNewGradingPeriod(), false

  test 'isNewGradingPeriod returns true if the id contains "new"', ->
    gradingPeriod = @renderComponent(id: "new1")
    ok gradingPeriod.isNewGradingPeriod()

  test 'does not render a delete button', ->
    gradingPeriod = @renderComponent()
    notOk gradingPeriod.refs.deleteButton

  test 'renderTitle returns a non-input element (since the grading period is readonly)', ->
    gradingPeriod = @renderComponent()
    notEqual gradingPeriod.renderTitle().type, "input"

  test 'renderStartDate returns a non-input element (since the grading period is readonly)', ->
    gradingPeriod = @renderComponent()
    notEqual gradingPeriod.renderStartDate().type, "input"

  test 'renderEndDate returns a non-input element (since the grading period is readonly)', ->
    gradingPeriod = @renderComponent()
    notEqual gradingPeriod.renderEndDate().type, "input"

  test 'displays the correct title', ->
    gradingPeriod = @renderComponent()
    titleNode = React.findDOMNode(gradingPeriod.refs.title)
    equal titleNode.textContent, "Spring"

  test 'displays the correct start date', ->
    gradingPeriod = @renderComponent()
    startDateNode = React.findDOMNode(gradingPeriod.refs.startDate)
    equal startDateNode.textContent, "Mar 1, 2015 at 12am"

  test 'displays the correct end date', ->
    gradingPeriod = @renderComponent()
    endDateNode = React.findDOMNode(gradingPeriod.refs.endDate)
    equal endDateNode.textContent, "May 31, 2015 at 12am"

  module "GradingPeriod with 'readOnly' set to true",
    renderComponent: (opts) ->
      defaultProps =
        title: "Spring"
        startDate: new Date("2015-03-01T00:00:00Z")
        endDate: new Date("2015-05-31T00:00:00Z")
        id: "1"
        readOnly: true
        permissions: {
          update: true
          delete: true
        }
        disabled: false
        onDeleteGradingPeriod: ->
        onDateChange: ->
        onTitleChange: ->

      @props = _.defaults(opts || {}, defaultProps)
      GradingPeriodElement = React.createElement(GradingPeriod, @props)
      @gradingPeriod = TestUtils.renderIntoDocument(GradingPeriodElement)

    teardown: ->
      React.unmountComponentAtNode(@gradingPeriod.getDOMNode().parentNode)

  test 'isNewGradingPeriod returns false if the id does not contain "new"', ->
    gradingPeriod = @renderComponent()
    equal gradingPeriod.isNewGradingPeriod(), false

  test 'isNewGradingPeriod returns true if the id contains "new"', ->
    gradingPeriod = @renderComponent(id: "new1")
    ok gradingPeriod.isNewGradingPeriod()

  test 'does not render a delete button', ->
    gradingPeriod = @renderComponent()
    notOk gradingPeriod.refs.deleteButton

  test 'renderTitle returns a non-input element (since the grading period is readonly)', ->
    gradingPeriod = @renderComponent()
    notEqual gradingPeriod.renderTitle().type, "input"

  test 'renderStartDate returns a non-input element (since the grading period is readonly)', ->
    gradingPeriod = @renderComponent()
    notEqual gradingPeriod.renderStartDate().type, "input"

  test 'renderEndDate returns a non-input element (since the grading period is readonly)', ->
    gradingPeriod = @renderComponent()
    notEqual gradingPeriod.renderEndDate().type, "input"

  test 'displays the correct title', ->
    gradingPeriod = @renderComponent()
    titleNode = React.findDOMNode(gradingPeriod.refs.title)
    equal titleNode.textContent, "Spring"

  test 'displays the correct start date', ->
    gradingPeriod = @renderComponent()
    startDateNode = React.findDOMNode(gradingPeriod.refs.startDate)
    equal startDateNode.textContent, "Mar 1, 2015 at 12am"

  test 'displays the correct end date', ->
    gradingPeriod = @renderComponent()
    endDateNode = React.findDOMNode(gradingPeriod.refs.endDate)
    equal endDateNode.textContent, "May 31, 2015 at 12am"

  module 'editable GradingPeriod',
    setup: ->
      @props =
        title: "Spring"
        startDate: new Date("2015-03-01T00:00:00Z")
        endDate: new Date("2015-05-31T00:00:00Z")
        id: "1"
        permissions: {
          update: true
          delete: true
        }
        disabled: false
        readOnly: false
        onDeleteGradingPeriod: ->
        onDateChange: ->
        onTitleChange: ->

      GradingPeriodElement = React.createElement(GradingPeriod, @props)
      @gradingPeriod = TestUtils.renderIntoDocument(GradingPeriodElement)

    teardown: ->
      React.unmountComponentAtNode(@gradingPeriod.getDOMNode().parentNode)

  test 'renders a delete button', ->
    ok @gradingPeriod.renderDeleteButton()

  test 'renderTitle returns an input element (since the grading period is editable)', ->
    equal @gradingPeriod.renderTitle().type, "input"

  test 'renderStartDate returns an input element (since the grading period is editable)', ->
    equal @gradingPeriod.renderStartDate().type, "input"

  test 'renderEndDate returns an input element (since the grading period is editable)', ->
    equal @gradingPeriod.renderEndDate().type, "input"

  test 'displays the correct title', ->
    titleNode = React.findDOMNode(@gradingPeriod.refs.title)
    equal titleNode.value, "Spring"

  test 'displays the correct start date', ->
    startDateNode = React.findDOMNode(@gradingPeriod.refs.startDate)
    equal startDateNode.value, "Mar 1, 2015 at 12am"

  test 'displays the correct end date', ->
    endDateNode = React.findDOMNode(@gradingPeriod.refs.endDate)
    equal endDateNode.value, "May 31, 2015 at 12am"

  module 'custom prop validation for editable periods',
    setup: ->
      @consoleWarn = @stub(console, 'warn')
      @props =
        title: "Spring"
        startDate: new Date("2015-03-01T00:00:00Z")
        endDate: new Date("2015-05-31T00:00:00Z")
        id: "1"
        permissions: {
          update: true
          delete: true
        }
        disabled: false
        readOnly: false
        onDeleteGradingPeriod: ->
        onDateChange: ->
        onTitleChange: ->

  test 'does not warn of invalid props if all required props are present and of the correct type', ->
    React.createElement(GradingPeriod, @props)
    ok @consoleWarn.notCalled

  test 'warns if required props are missing', ->
    delete @props.disabled
    React.createElement(GradingPeriod, @props)
    ok @consoleWarn.calledOnce

  test 'warns if required props are of the wrong type', ->
    @props.onDeleteGradingPeriod = "a/s/l?"
    React.createElement(GradingPeriod, @props)
    ok @consoleWarn.calledOnce
