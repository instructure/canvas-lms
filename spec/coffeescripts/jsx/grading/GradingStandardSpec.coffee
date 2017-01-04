define [
  'react'
  'react-dom'
  'react-addons-test-utils'
  'jquery'
  'jsx/grading/gradingStandard'
], (React, ReactDOM, {Simulate}, $, GradingStandard) ->

  module 'GradingStandard not being edited',
    setup: ->
      @props =
        key: 1
        standard:
          id: 1
          title: "Test Grading Standard"
          data: [["A", 0.92], ["A-", 0.90], ["F", 0.00]]
        permissions:
          manage: true
        editing: false
        justAdded: false
        othersEditing: false
        round: (number)-> return Math.round(number * 100)/100
        onSetEditingStatus: ->
        onDeleteGradingStandard: ->
        onSaveGradingStandard: ->

      @mountPoint = $('<div>').appendTo('#fixtures')[0]
      GradingStandardElement = React.createElement(GradingStandard, @props)
      @gradingStandard = ReactDOM.render(GradingStandardElement, @mountPoint)

    teardown: ->
      ReactDOM.unmountComponentAtNode(@mountPoint)
      $("#fixtures").empty()

  test 'returns false for assessedAssignment', ->
    deepEqual @gradingStandard.assessedAssignment(), false

  test 'renders the correct title', ->
    #'Grading standard title' is wrapped in a screenreader-only span that this
    #test suite does not ignore. 'Grading standadr title' is not actually displayed
    deepEqual @gradingStandard.refs.title.textContent, "Grading standard titleTest Grading Standard"

  test 'renders the correct id name', ->
    deepEqual @gradingStandard.renderIdNames(), "grading_standard_1"

  test 'renders the edit button', ->
    ok @gradingStandard.refs.editButton

  test 'calls onSetEditingStatus when edit button is clicked', ->
    setEditingStatus = @spy(@props, 'onSetEditingStatus')
    GradingStandardElement = React.createElement(GradingStandard, @props)
    @gradingStandard = ReactDOM.render(GradingStandardElement, @mountPoint)
    Simulate.click(@gradingStandard.refs.editButton)
    ok setEditingStatus.calledOnce
    setEditingStatus.restore()

  test 'renders the delete button', ->
    ok @gradingStandard.refs.deleteButton

  test 'calls onDeleteGradingStandard when delete button is clicked', ->
    deleteGradingStandard = @spy(@props, 'onDeleteGradingStandard')
    GradingStandardElement = React.createElement(GradingStandard, @props)
    @gradingStandard = ReactDOM.render(GradingStandardElement, @mountPoint)
    Simulate.click(@gradingStandard.refs.deleteButton)
    ok deleteGradingStandard.calledOnce
    deleteGradingStandard.restore()

  test 'does not show a message about not being able to manage', ->
    deepEqual @gradingStandard.refs.cannotManageMessage, undefined

  test 'does not show the save button', ->
    deepEqual @gradingStandard.refs.saveButton, undefined

  test 'does not show the cancel button', ->
    deepEqual @gradingStandard.refs.cancelButton, undefined

  module "GradingStandard without 'manage' permissions",
    setup: ->
      props =
        key: 1
        standard:
          id: 1
          title: "Test Grading Standard"
          data: [["A", 0.92], ["A-", 0.90], ["F", 0.00]]
          context_type: "Account"
        permissions:
          manage: false
        editing: false
        justAdded: false
        othersEditing: false
        round: (number)-> return Math.round(number * 100)/100
        onSetEditingStatus: ->
        onDeleteGradingStandard: ->
        onSaveGradingStandard: ->

      GradingStandardElement = React.createElement(GradingStandard, props)
      @gradingStandard = ReactDOM.render(GradingStandardElement, $('<div>').appendTo('#fixtures')[0])

    teardown: ->
      ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(@gradingStandard).parentNode)
      $("#fixtures").empty()

  test 'displays a cannot manage message', ->
    ok @gradingStandard.refs.cannotManageMessage

  test 'disables edit and delete buttons', ->
    ok @gradingStandard.refs.disabledButtons

  module "GradingStandard being edited",
    setup: ->
      @props =
        key: 1
        standard:
          id: 1
          title: "Test Grading Standard"
          data: [["A", 0.92], ["A-", 0.90], ["F", 0.00]]
        permissions:
          manage: true
        editing: true
        justAdded: false
        othersEditing: false
        round: (number)-> return Math.round(number * 100)/100
        onSetEditingStatus: ->
        onDeleteGradingStandard: ->
        onSaveGradingStandard: sinon.spy()

      @mountPoint = $('<div>').appendTo('#fixtures')[0]
      GradingStandardElement = React.createElement(GradingStandard, @props)
      @gradingStandard = ReactDOM.render(GradingStandardElement, @mountPoint)

    teardown: ->
      ReactDOM.unmountComponentAtNode(@mountPoint)

  test 'does not render the edit button', ->
    deepEqual @gradingStandard.refs.editButton, undefined

  test 'does not render the delete button', ->
    deepEqual @gradingStandard.refs.deleteButton, undefined

  test 'renders the save button', ->
    ok @gradingStandard.refs.saveButton

  test 'rowNamesAreValid() returns true with non-empty, unique row names', ->
    deepEqual @gradingStandard.rowNamesAreValid(), true

  test 'rowDataIsValid() returns true with non-empty, unique, non-overlapping row values', ->
    deepEqual @gradingStandard.rowDataIsValid(), true

  test 'calls onSaveGradingStandard save button is clicked', ->
    Simulate.click(@gradingStandard.refs.saveButton)
    ok @gradingStandard.props.onSaveGradingStandard.calledOnce

  test 'sets the state to saving when the save button is clicked', ->
    deepEqual @gradingStandard.state.saving, false
    Simulate.click(@gradingStandard.refs.saveButton)
    deepEqual @gradingStandard.state.saving, true

  test 'shows the cancel button', ->
    ok @gradingStandard.refs.cancelButton

  test 'calls onSetEditingStatus when the cancel button is clicked', ->
    setEditingStatus = @spy(@props, 'onSetEditingStatus')
    GradingStandardElement = React.createElement(GradingStandard, @props)
    @gradingStandard = ReactDOM.render(GradingStandardElement, @mountPoint)
    Simulate.click(@gradingStandard.refs.cancelButton)
    ok setEditingStatus.calledOnce
    setEditingStatus.restore()

  test 'deletes the correct row on the editingStandard when deleteDataRow is called', ->
    @gradingStandard.deleteDataRow(1)
    deepEqual @gradingStandard.state.editingStandard.data, [["A", 0.92], ["F", 0.00]]

  test 'does not delete the row if it is the last data row remaining', ->
    @gradingStandard.deleteDataRow(1)
    deepEqual @gradingStandard.state.editingStandard.data, [["A", 0.92], ["F", 0.00]]
    @gradingStandard.deleteDataRow(0)
    deepEqual @gradingStandard.state.editingStandard.data, [["F", 0.00]]
    @gradingStandard.deleteDataRow(0)
    deepEqual @gradingStandard.state.editingStandard.data, [["F", 0.00]]

  test 'inserts the correct row on the editingStandard when insertGradingStandardRow is called', ->
    @gradingStandard.insertGradingStandardRow(1)
    deepEqual @gradingStandard.state.editingStandard.data, [["A", 0.92], ["A-", 0.90], ["", ""], ["F", 0.00]]

  test 'changes the title on the editingStandard when title input changes', ->
    Simulate.change(@gradingStandard.refs.title, {target: {value: 'Brand new title'}})
    deepEqual @gradingStandard.state.editingStandard.title, "Brand new title"

  test 'changes the min score on the editingStandard when changeRowMinScore is called', ->
    @gradingStandard.changeRowMinScore(2, '23')
    deepEqual @gradingStandard.state.editingStandard.data[2], ["F", '23']

  test 'changes the row name on the editingStandard when changeRowName is called', ->
    @gradingStandard.changeRowName(2, "Q")
    deepEqual @gradingStandard.state.editingStandard.data[2], ["Q", 0.00]

  module "GradingStandard being edited with blank names",
    setup: ->
      props =
        key: 1
        standard:
          id: 1
          title: "Test Grading Standard"
          data: [["A", 0.92], ["", 0.90], ["F", 0.00]]
        permissions:
          manage: true
        editing: true
        justAdded: false
        othersEditing: false
        round: (number)-> return Math.round(number * 100)/100
        onSetEditingStatus: ->
        onDeleteGradingStandard: ->
        onSaveGradingStandard: ->

      GradingStandardElement = React.createElement(GradingStandard, props)
      @gradingStandard = ReactDOM.render(GradingStandardElement, $('<div>').appendTo('#fixtures')[0])

    teardown: ->
      ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(@gradingStandard).parentNode)
      $("#fixtures").empty()

  test 'rowNamesAreValid() returns false with empty row names', ->
    deepEqual @gradingStandard.rowNamesAreValid(), false

  test 'alerts the user that the input is invalid when they try to save', ->
    Simulate.click(@gradingStandard.refs.saveButton)
    ok @gradingStandard.refs.invalidStandardAlert

  test 'shows a messsage describing why the input is invalid', ->
    Simulate.click(@gradingStandard.refs.saveButton)
    deepEqual @gradingStandard.refs.invalidStandardAlert.textContent,
      "Cannot have duplicate or empty row names. Fix the names and try clicking 'Save' again."

  module "GradingStandard being edited with duplicate names",
    setup: ->
      props =
        key: 1
        standard:
          id: 1
          title: "Test Grading Standard"
          data: [["A", 0.92], ["A", 0.90], ["F", 0.00]]
        permissions:
          manage: true
        editing: true
        justAdded: false
        othersEditing: false
        round: (number)-> return Math.round(number * 100)/100
        onSetEditingStatus: ->
        onDeleteGradingStandard: ->
        onSaveGradingStandard: ->

      GradingStandardElement = React.createElement(GradingStandard, props)
      @gradingStandard = ReactDOM.render(GradingStandardElement, $('<div>').appendTo('#fixtures')[0])

    teardown: ->
      ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(@gradingStandard).parentNode)
      $("#fixtures").empty()

  test 'rowNamesAreValid() returns false with duplicate row names', ->
    deepEqual @gradingStandard.rowNamesAreValid(), false

  test 'alerts the user that the input is invalid when they try to save', ->
    Simulate.click(@gradingStandard.refs.saveButton)
    ok @gradingStandard.refs.invalidStandardAlert

  test 'shows a messsage describing why the input is invalid', ->
    Simulate.click(@gradingStandard.refs.saveButton)
    deepEqual @gradingStandard.refs.invalidStandardAlert.textContent,
      "Cannot have duplicate or empty row names. Fix the names and try clicking 'Save' again."

  module "GradingStandard being edited with empty values",
    setup: ->
      props =
        key: 1
        standard:
          id: 1
          title: "Test Grading Standard"
          data: [["A", 0.92], ["B", 0.90], ["F", ""]]
        permissions:
          manage: true
        editing: true
        justAdded: false
        othersEditing: false
        round: (number)-> return Math.round(number * 100)/100
        onSetEditingStatus: ->
        onDeleteGradingStandard: ->
        onSaveGradingStandard: ->

      GradingStandardElement = React.createElement(GradingStandard, props)
      @gradingStandard = ReactDOM.render(GradingStandardElement, $('<div>').appendTo('#fixtures')[0])

    teardown: ->
      ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(@gradingStandard).parentNode)
      $("#fixtures").empty()

  test 'rowDataIsValid() returns false with empty values', ->
    deepEqual @gradingStandard.rowDataIsValid(), false

  test 'alerts the user that the input is invalid when they try to save', ->
    Simulate.click(@gradingStandard.refs.saveButton)
    ok @gradingStandard.refs.invalidStandardAlert

  test 'shows a messsage describing why the input is invalid', ->
    Simulate.click(@gradingStandard.refs.saveButton)
    deepEqual @gradingStandard.refs.invalidStandardAlert.textContent,
      "Cannot have overlapping or empty ranges. Fix the ranges and try clicking 'Save' again."

  module "GradingStandard being edited with duplicate values",
    setup: ->
      props =
        key: 1
        standard:
          id: 1
          title: "Test Grading Standard"
          data: [["A", 0.92], ["B", 0.92], ["F", 0.00]]
        permissions:
          manage: true
        editing: true
        justAdded: false
        othersEditing: false
        round: (number)-> return Math.round(number * 100)/100
        onSetEditingStatus: ->
        onDeleteGradingStandard: ->
        onSaveGradingStandard: ->

      GradingStandardElement = React.createElement(GradingStandard, props)
      @gradingStandard = ReactDOM.render(GradingStandardElement, $('<div>').appendTo('#fixtures')[0])

    teardown: ->
      ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(@gradingStandard).parentNode)
      $("#fixtures").empty()

  test 'rowDataIsValid() returns false with duplicate values', ->
    deepEqual @gradingStandard.rowDataIsValid(), false

  test 'alerts the user that the input is invalid when they try to save', ->
    Simulate.click(@gradingStandard.refs.saveButton)
    ok @gradingStandard.refs.invalidStandardAlert

  test 'shows a messsage describing why the input is invalid', ->
    Simulate.click(@gradingStandard.refs.saveButton)
    deepEqual @gradingStandard.refs.invalidStandardAlert.textContent,
      "Cannot have overlapping or empty ranges. Fix the ranges and try clicking 'Save' again."

  module "GradingStandard being edited with values that round to the same number",
    setup: ->
      props =
        key: 1
        standard:
          id: 1
          title: "Test Grading Standard"
          data: [["A", 0.92], ["B", 0.91996], ["F", 0.00]]
        permissions:
          manage: true
        editing: true
        justAdded: false
        othersEditing: false
        round: (number)-> return Math.round(number * 100)/100
        onSetEditingStatus: ->
        onDeleteGradingStandard: ->
        onSaveGradingStandard: ->

      GradingStandardElement = React.createElement(GradingStandard, props)
      @gradingStandard = ReactDOM.render(GradingStandardElement, $('<div>').appendTo('#fixtures')[0])

    teardown: ->
      ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(@gradingStandard).parentNode)
      $("#fixtures").empty()

  test 'rowDataIsValid() returns false with if values round to the same number (91.996 rounds to 92)', ->
    deepEqual @gradingStandard.rowDataIsValid(), false

  test 'alerts the user that the input is invalid when they try to save', ->
    Simulate.click(@gradingStandard.refs.saveButton)
    ok @gradingStandard.refs.invalidStandardAlert

  test 'shows a messsage describing why the input is invalid', ->
    Simulate.click(@gradingStandard.refs.saveButton)
    deepEqual @gradingStandard.refs.invalidStandardAlert.textContent,
      "Cannot have overlapping or empty ranges. Fix the ranges and try clicking 'Save' again."

  module "GradingStandard being edited with overlapping values",
    setup: ->
      props =
        key: 1
        standard:
          id: 1
          title: "Test Grading Standard"
          data: [["A", 0.92], ["B", 0.93], ["F", 0.00]]
        permissions:
          manage: true
        editing: true
        justAdded: false
        othersEditing: false
        round: (number)-> return Math.round(number * 100)/100
        onSetEditingStatus: ->
        onDeleteGradingStandard: ->
        onSaveGradingStandard: ->

      GradingStandardElement = React.createElement(GradingStandard, props)
      @gradingStandard = ReactDOM.render(GradingStandardElement, $('<div>').appendTo('#fixtures')[0])

    teardown: ->
      ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(@gradingStandard).parentNode)
      $("#fixtures").empty()

  test 'rowDataIsValid() returns false if scheme values overlap', ->
    deepEqual @gradingStandard.rowDataIsValid(), false

  test 'alerts the user that the input is invalid when they try to save', ->
    Simulate.click(@gradingStandard.refs.saveButton)
    ok @gradingStandard.refs.invalidStandardAlert

  test 'shows a messsage describing why the input is invalid', ->
    Simulate.click(@gradingStandard.refs.saveButton)
    deepEqual @gradingStandard.refs.invalidStandardAlert.textContent,
      "Cannot have overlapping or empty ranges. Fix the ranges and try clicking 'Save' again."
