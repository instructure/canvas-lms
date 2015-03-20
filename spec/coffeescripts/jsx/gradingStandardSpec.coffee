define [
  'react'
  'jquery'
  'jsx/grading/gradingStandard'
], (React, $, GradingStandard) ->

  Simulate = React.addons.TestUtils.Simulate

  module 'GradingStandard not being edited',
    setup: ->
      props =
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
        onSetEditingStatus: ->
        onDeleteGradingStandard: ->
        onSaveGradingStandard: ->

      @gradingStandard = React.renderComponent(GradingStandard(props), $('<div>').appendTo('body')[0])

    teardown: ->
      React.unmountComponentAtNode(@gradingStandard.getDOMNode().parentNode)

  test 'returns false for assessedAssignment', ->
    deepEqual @gradingStandard.assessedAssignment(), false

  test 'renders the correct title', ->
    #'Grading standard title' is wrapped in a screenreader-only span that this
    #test suite does not ignore. 'Grading standadr title' is not actually displayed
    deepEqual @gradingStandard.refs.title.getDOMNode().textContent, "Grading standard titleTest Grading Standard"

  test 'renders the correct id name', ->
    deepEqual @gradingStandard.renderIdNames(), "grading_standard_1"

  test 'renders the edit link', ->
    ok @gradingStandard.refs.editLink

  test 'calls onSetEditingStatus when edit link is clicked', ->
    setEditingStatus = sinon.spy(@gradingStandard.props, 'onSetEditingStatus')
    Simulate.click(@gradingStandard.refs.editLink.getDOMNode())
    ok setEditingStatus.calledOnce

  test 'renders the delete link', ->
    ok @gradingStandard.refs.deleteLink

  test 'calls onDeleteGradingStandard when delete link is clicked', ->
    deleteGradingStandard = sinon.spy(@gradingStandard.props, 'onDeleteGradingStandard')
    Simulate.click(@gradingStandard.refs.deleteLink.getDOMNode())
    ok deleteGradingStandard.calledOnce

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
        onSetEditingStatus: ->
        onDeleteGradingStandard: ->
        onSaveGradingStandard: ->

      @gradingStandard = React.renderComponent(GradingStandard(props), $('<div>').appendTo('body')[0])

    teardown: ->
      React.unmountComponentAtNode(@gradingStandard.getDOMNode().parentNode)

  test 'displays a cannot manage message', ->
    ok @gradingStandard.refs.cannotManageMessage

  test 'disables edit and delete links', ->
    ok @gradingStandard.refs.disabledLinks

  module "GradingStandard being edited",
    setup: ->
      props =
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
        onSetEditingStatus: ->
        onDeleteGradingStandard: ->
        onSaveGradingStandard: ->

      @gradingStandard = React.renderComponent(GradingStandard(props), $('<div>').appendTo('body')[0])

    teardown: ->
      React.unmountComponentAtNode(@gradingStandard.getDOMNode().parentNode)

  test 'does not render the edit link', ->
    deepEqual @gradingStandard.refs.editLink, undefined

  test 'does not render the delete link', ->
    deepEqual @gradingStandard.refs.deleteLink, undefined

  test 'renders the save button', ->
    ok @gradingStandard.refs.saveButton

  test 'calls onSaveGradingStandard save button is clicked', ->
    saveGradingStandard = sinon.spy(@gradingStandard.props, 'onSaveGradingStandard')
    Simulate.click(@gradingStandard.refs.saveButton.getDOMNode())
    ok saveGradingStandard.calledOnce

  test 'sets the state to saving when the save button is clicked', ->
    deepEqual @gradingStandard.state.saving, false
    Simulate.click(@gradingStandard.refs.saveButton.getDOMNode())
    deepEqual @gradingStandard.state.saving, true

  test 'shows the cancel button', ->
    ok @gradingStandard.refs.cancelButton

  test 'calls onSetEditingStatus when the cancel button is clicked', ->
    setEditingStatus = sinon.spy(@gradingStandard.props, 'onSetEditingStatus')
    Simulate.click(@gradingStandard.refs.cancelButton.getDOMNode())
    ok setEditingStatus.calledOnce

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

  test 'does not alter the standard when deleteDataRow is called (only the editingStandard is altered)', ->
    @gradingStandard.deleteDataRow(1)
    deepEqual @gradingStandard.state.standard.data, [["A", 0.92], ["A-", 0.90], ["F", 0.00]]

  test 'inserts the correct row on the editingStandard when insertGradingStandardRow is called', ->
    @gradingStandard.insertGradingStandardRow(1)
    deepEqual @gradingStandard.state.editingStandard.data, [["A", 0.92], ["A-", 0.90], ["", " "], ["F", 0.00]]

  test 'does not insert a row on the standard when insertGradingStandardRow is called (only the editingStandard is altered)', ->
    @gradingStandard.insertGradingStandardRow(1)
    deepEqual @gradingStandard.state.standard.data, [["A", 0.92], ["A-", 0.90], ["F", 0.00]]

  test 'changes the title on the editingStandard when title input changes', ->
    Simulate.change(@gradingStandard.refs.title.getDOMNode(), {target: {value: 'Brand new title'}})
    deepEqual @gradingStandard.state.editingStandard.title, "Brand new title"

  test 'does not change the title on the standard when title input changes (only the editingStandard is altered)', ->
    Simulate.change(@gradingStandard.refs.title.getDOMNode(), {target: {value: 'Brand new title'}})
    deepEqual @gradingStandard.state.standard.title, "Test Grading Standard"

  test 'changes the min score on the editingStandard when changeRowMinScore is called', ->
    @gradingStandard.changeRowMinScore(2, 0.23)
    deepEqual @gradingStandard.state.editingStandard.data[2], ["F", 0.23]

  test 'does not change the min score on the standard when changeRowMinScore is called (only the editingStandard is altered)', ->
    @gradingStandard.changeRowMinScore(2, 0.23)
    deepEqual @gradingStandard.state.standard.data[2], ["F", 0.00]

  test 'changes the row name on the editingStandard when changeRowName is called', ->
    @gradingStandard.changeRowName(2, "Q")
    deepEqual @gradingStandard.state.editingStandard.data[2], ["Q", 0.00]

  test 'does not change the row name on the standard when changeRowName is called (only the editingStandard is altered)', ->
    @gradingStandard.changeRowName(2, "Q")
    deepEqual @gradingStandard.state.standard.data[2], ["F", 0.00]
