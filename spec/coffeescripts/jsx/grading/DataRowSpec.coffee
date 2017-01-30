define [
  'react'
  'react-dom'
  'react-addons-test-utils'
  'jquery'
  'jsx/grading/dataRow'
], (React, ReactDOM, {Simulate, SimulateNative}, $, DataRow) ->

  QUnit.module 'DataRow not being edited, without a sibling',
    setup: ->
      props =
        key: 0
        uniqueId: 0
        row: ['A', 92.346]
        editing: false
        round: (number)-> Math.round(number * 100)/100

      DataRowElement = React.createElement(DataRow, props)
      @dataRow = ReactDOM.render(DataRowElement, $('<table>').appendTo('#fixtures')[0])

    teardown: ->
      ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(@dataRow).parentNode)
      $("#fixtures").empty()

  test 'renders in "view" mode (as opposed to "edit" mode)', ->
    ok @dataRow.refs.viewContainer

  test 'getRowData() returns the correct name', ->
    deepEqual @dataRow.getRowData().name, 'A'

  test 'getRowData() sets max score to 100 if there is no sibling row', ->
    deepEqual @dataRow.getRowData().maxScore, 100

  test 'renderMinScore() rounds the score if not in editing mode', ->
    deepEqual @dataRow.renderMinScore(), '92.35'

  test "renderMaxScore() returns a max score of 100 without a '<' sign", ->
    deepEqual @dataRow.renderMaxScore(), '100'

  QUnit.module 'DataRow being edited',
    setup: ->
      @props =
        key: 0
        uniqueId: 0
        row: ['A', 92.346]
        editing: true
        round: (number)-> Math.round(number * 100)/100
        onRowMinScoreChange: ->
        onRowNameChange: ->
        onDeleteRow: ->

      DataRowElement = React.createElement(DataRow, @props)
      @dataRow = ReactDOM.render(DataRowElement, $('<table>').appendTo('#fixtures')[0])

    teardown: ->
      ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(@dataRow).parentNode)
      $("#fixtures").empty()

  test 'renders in "edit" mode (as opposed to "view" mode)', ->
    ok @dataRow.refs.editContainer

  test 'on change, accepts arbitrary input and saves to state', ->
    changeMinScore = @spy(@props, 'onRowMinScoreChange')
    DataRowElement = React.createElement(DataRow, @props)
    @dataRow = ReactDOM.render(DataRowElement, $('<table>').appendTo('#fixtures')[0])
    Simulate.change(@dataRow.minScoreInput, {target: {value: 'A'}})
    deepEqual @dataRow.renderMinScore(), 'A'
    Simulate.change(@dataRow.minScoreInput, {target: {value: '*&@%!'}})
    deepEqual @dataRow.renderMinScore(), '*&@%!'
    Simulate.change(@dataRow.minScoreInput, {target: {value: '3B'}})
    deepEqual @dataRow.renderMinScore(), '3B'
    ok changeMinScore.notCalled
    changeMinScore.restore()

  test 'on blur, does not call onRowMinScoreChange if the input parsed value is less than 0', ->
    changeMinScore = @spy(@props, 'onRowMinScoreChange')
    DataRowElement = React.createElement(DataRow, @props)
    @dataRow = ReactDOM.render(DataRowElement, $('<table>').appendTo('#fixtures')[0])
    Simulate.change(@dataRow.minScoreInput, {target: {value: '-1'}})
    Simulate.blur(@dataRow.minScoreInput)
    ok changeMinScore.notCalled
    changeMinScore.restore()

  test 'on blur, does not call onRowMinScoreChange if the input parsed value is greater than 100', ->
    changeMinScore = @spy(@props, 'onRowMinScoreChange')
    DataRowElement = React.createElement(DataRow, @props)
    @dataRow = ReactDOM.render(DataRowElement, $('<table>').appendTo('#fixtures')[0])
    Simulate.change(@dataRow.minScoreInput, {target: {value: '101'}})
    Simulate.blur(@dataRow.minScoreInput)
    ok changeMinScore.notCalled
    changeMinScore.restore()

  test 'on blur, calls onRowMinScoreChange when input parsed value is between 0 and 100', ->
    changeMinScore = @spy(@props, 'onRowMinScoreChange')
    DataRowElement = React.createElement(DataRow, @props)
    @dataRow = ReactDOM.render(DataRowElement, $('<table>').appendTo('#fixtures')[0])
    Simulate.change(@dataRow.minScoreInput, {target: {value: '88.'}})
    Simulate.blur(@dataRow.minScoreInput)
    Simulate.change(@dataRow.minScoreInput, {target: {value: ''}})
    Simulate.blur(@dataRow.minScoreInput)
    Simulate.change(@dataRow.minScoreInput, {target: {value: '100'}})
    Simulate.blur(@dataRow.minScoreInput)
    Simulate.change(@dataRow.minScoreInput, {target: {value: '0'}})
    Simulate.blur(@dataRow.minScoreInput)
    Simulate.change(@dataRow.minScoreInput, {target: {value: 'A'}})
    Simulate.blur(@dataRow.minScoreInput)
    Simulate.change(@dataRow.minScoreInput, {target: {value: '%*@#($'}})
    Simulate.blur(@dataRow.minScoreInput)
    deepEqual changeMinScore.callCount, 3
    changeMinScore.restore()

  test 'on blur, does not call onRowMinScoreChange when input has not changed', ->
    changeMinScore = @spy(@props, 'onRowMinScoreChange')
    DataRowElement = React.createElement(DataRow, @props)
    @dataRow = ReactDOM.render(DataRowElement, $('<table>').appendTo('#fixtures')[0])
    Simulate.blur(@dataRow.minScoreInput)
    ok changeMinScore.notCalled
    changeMinScore.restore()

  test 'calls onRowNameChange when input changes', ->
    changeMinScore = @spy(@props, 'onRowNameChange')
    DataRowElement = React.createElement(DataRow, @props)
    @dataRow = ReactDOM.render(DataRowElement, $('<table>').appendTo('#fixtures')[0])
    Simulate.change(@dataRow.refs.nameInput, {target: {value: 'F'}})
    ok changeMinScore.calledOnce
    changeMinScore.restore()

  test 'calls onDeleteRow when the delete button is clicked', ->
    deleteRow = @spy(@props, 'onDeleteRow')
    DataRowElement = React.createElement(DataRow, @props)
    @dataRow = ReactDOM.render(DataRowElement, $('<table>').appendTo('#fixtures')[0])
    Simulate.click(@dataRow.refs.deleteButton.getDOMNode())
    ok deleteRow.calledOnce

  QUnit.module 'DataRow with a sibling',
    setup: ->
      props =
        key: 1
        row: ['A-', 90.0]
        siblingRow: ['A', 92.346]
        editing: false
        round: (number)-> Math.round(number * 100)/100

      DataRowElement = React.createElement(DataRow, props)
      @dataRow = ReactDOM.render(DataRowElement, $('<table>').appendTo('#fixtures')[0])

    teardown: ->
      ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(@dataRow).parentNode)
      $("#fixtures").empty()

  test "shows the max score as the sibling's min score", ->
    deepEqual @dataRow.renderMaxScore(), '< 92.35'
