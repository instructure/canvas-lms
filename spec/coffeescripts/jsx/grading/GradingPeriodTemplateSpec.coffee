define [
  'react'
  'react-dom'
  'react-addons-test-utils'
  'underscore'
  'jsx/grading/gradingPeriodTemplate'
], (React, ReactDOM, {Simulate}, _, GradingPeriod) ->

  defaultProps =
    title: "Spring"
    weight: 50
    weighted: false
    startDate: new Date("2015-03-01T00:00:00Z")
    endDate: new Date("2015-05-31T00:00:00Z")
    closeDate: new Date("2015-06-07T00:00:00Z")
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

  wrapper = document.getElementById('fixtures')

  QUnit.module 'GradingPeriod with read-only permissions',
    renderComponent: (opts = {}) ->
      readOnlyProps =
        permissions: {
          update: false
          delete: false
        }

      props = _.defaults(opts, readOnlyProps, defaultProps)
      GradingPeriodElement = React.createElement(GradingPeriod, props)
      ReactDOM.render(GradingPeriodElement, wrapper)

    teardown: ->
      ReactDOM.unmountComponentAtNode(wrapper)

  test 'isNewGradingPeriod returns false if the id does not contain "new"', ->
    gradingPeriod = @renderComponent()
    equal gradingPeriod.isNewGradingPeriod(), false

  test 'isNewGradingPeriod returns true if the id contains "new"', ->
    gradingPeriod = @renderComponent(id: "new1")
    ok gradingPeriod.isNewGradingPeriod()

  test 'does not render a delete button', ->
    gradingPeriod = @renderComponent()
    notOk gradingPeriod.refs.deleteButton

  test 'renders attributes as read-only', ->
    gradingPeriod = @renderComponent()
    notEqual gradingPeriod.refs.title.type, "INPUT"
    notEqual gradingPeriod.refs.startDate.type, "INPUT"
    notEqual gradingPeriod.refs.endDate.type, "INPUT"

  test 'displays the correct attributes', ->
    gradingPeriod = @renderComponent()
    equal gradingPeriod.refs.title.textContent, "Spring"
    equal gradingPeriod.refs.startDate.textContent, "Mar 1, 2015"
    equal gradingPeriod.refs.endDate.textContent, "May 31, 2015"
    equal gradingPeriod.refs.weight, null

  test 'displays the assigned close date', ->
    gradingPeriod = @renderComponent()
    equal gradingPeriod.refs.closeDate.textContent, "Jun 7, 2015"

  test 'uses the end date when close date is not defined', ->
    gradingPeriod = @renderComponent(closeDate: null)
    equal gradingPeriod.refs.closeDate.textContent, "May 31, 2015"

  test 'displays weight only when weighted is true', ->
    gradingPeriod = @renderComponent(weighted: true)
    equal gradingPeriod.refs.weight.textContent, "50%"

  QUnit.module "GradingPeriod with 'readOnly' set to true",
    renderComponent: (opts = {}) ->
      readOnlyProps =
        readOnly: true

      props = _.defaults(opts, readOnlyProps, defaultProps)
      GradingPeriodElement = React.createElement(GradingPeriod, props)
      ReactDOM.render(GradingPeriodElement, wrapper)

    teardown: ->
      ReactDOM.unmountComponentAtNode(wrapper)

  test 'isNewGradingPeriod returns false if the id does not contain "new"', ->
    gradingPeriod = @renderComponent()
    equal gradingPeriod.isNewGradingPeriod(), false

  test 'isNewGradingPeriod returns true if the id contains "new"', ->
    gradingPeriod = @renderComponent(id: "new1")
    ok gradingPeriod.isNewGradingPeriod()

  test 'does not render a delete button', ->
    gradingPeriod = @renderComponent()
    notOk gradingPeriod.refs.deleteButton

  test 'renders attributes as read-only', ->
    gradingPeriod = @renderComponent()
    notEqual gradingPeriod.refs.title.type, "INPUT"
    notEqual gradingPeriod.refs.startDate.type, "INPUT"
    notEqual gradingPeriod.refs.endDate.type, "INPUT"
    equal gradingPeriod.refs.weight, null

  test 'displays the correct attributes', ->
    gradingPeriod = @renderComponent()
    equal gradingPeriod.refs.title.textContent, "Spring"
    equal gradingPeriod.refs.startDate.textContent, "Mar 1, 2015"
    equal gradingPeriod.refs.endDate.textContent, "May 31, 2015"
    equal gradingPeriod.refs.weight, null

  test 'displays the assigned close date', ->
    gradingPeriod = @renderComponent()
    equal gradingPeriod.refs.closeDate.textContent, "Jun 7, 2015"

  test 'uses the end date when close date is not defined', ->
    gradingPeriod = @renderComponent(closeDate: null)
    equal gradingPeriod.refs.closeDate.textContent, "May 31, 2015"

  QUnit.module 'editable GradingPeriod',
    renderComponent: (opts = {}) ->
      props = _.defaults(opts, defaultProps)
      GradingPeriodElement = React.createElement(GradingPeriod, props)
      ReactDOM.render(GradingPeriodElement, wrapper)

    teardown: ->
      ReactDOM.unmountComponentAtNode(wrapper)

  test 'renders a delete button', ->
    gradingPeriod = @renderComponent()
    ok gradingPeriod.refs.deleteButton

  test 'renders with input fields', ->
    gradingPeriod = @renderComponent()
    equal gradingPeriod.refs.title.tagName, "INPUT"
    equal gradingPeriod.refs.startDate.tagName, "INPUT"
    equal gradingPeriod.refs.endDate.tagName, "INPUT"
    equal gradingPeriod.refs.weight, null

  test 'displays the correct attributes', ->
    gradingPeriod = @renderComponent()
    equal gradingPeriod.refs.title.value, "Spring"
    equal gradingPeriod.refs.startDate.value, "Mar 1, 2015"
    equal gradingPeriod.refs.endDate.value, "May 31, 2015"
    equal gradingPeriod.refs.weight, null

  test 'uses the end date for close date', ->
    gradingPeriod = @renderComponent()
    equal gradingPeriod.refs.closeDate.textContent, "May 31, 2015"

  test "calls onClick handler for clicks on 'delete grading period'", ->
    deleteSpy = sinon.spy()
    gradingPeriod = @renderComponent(onDeleteGradingPeriod: deleteSpy)
    Simulate.click(gradingPeriod.refs.deleteButton)
    ok deleteSpy.calledOnce

  test "ignores clicks on 'delete grading period' when disabled", ->
    deleteSpy = sinon.spy()
    gradingPeriod = @renderComponent(onDeleteGradingPeriod: deleteSpy, disabled: true)
    Simulate.click(gradingPeriod.refs.deleteButton)
    notOk deleteSpy.called

  QUnit.module 'custom prop validation for editable periods',
    renderComponent: (opts = {}) ->
      props = _.defaults(opts, defaultProps)
      GradingPeriodElement = React.createElement(GradingPeriod, props)
      ReactDOM.render(GradingPeriodElement, wrapper)

    setup: ->
      @consoleError = @stub(console, 'error')

    teardown: ->
      ReactDOM.unmountComponentAtNode(wrapper)

  test 'does not warn of invalid props if all required props are present and of the correct type', ->
    @renderComponent()
    ok @consoleError.notCalled

  test 'warns if required props are missing', ->
    @renderComponent(disabled: null)
    ok @consoleError.calledOnce

  test 'warns if required props are of the wrong type', ->
    @renderComponent(onDeleteGradingPeriod: "invalid-type")
    ok @consoleError.calledOnce
