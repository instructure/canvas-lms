define [
  'react'
  'jquery'
  'jsx/grading/dataRow'
], (React, $, DataRow) ->

  Simulate = React.addons.TestUtils.Simulate
  SimulateNative = React.addons.TestUtils.SimulateNative

  module 'DataRow not being edited, without a sibling',
    setup: ->
      props =
        key: 0
        uniqueId: 0
        row: ['A', 92.346]
        editing: false

      @dataRow = React.render(DataRow(props), $('<table>').appendTo('body')[0])

    teardown: ->
      React.unmountComponentAtNode(@dataRow.getDOMNode().parentNode)

  test 'renders in "view" mode (as opposed to "edit" mode)', ->
    ok @dataRow.refs.viewContainer

  test 'getRowData() returns the correct name', ->
    deepEqual @dataRow.getRowData().name, 'A'

  test 'getRowData() sets max score to 100 if there is no sibling row', ->
    deepEqual @dataRow.getRowData().maxScore, 100

  test 'renderMinScore() returns the correct score for non-zero scores', ->
    deepEqual @dataRow.renderMinScore(), '92.35'

  test "renderMaxScore() returns a max score of 100 without a '<' sign", ->
    deepEqual @dataRow.renderMaxScore(), '100'

  test 'roundToTwoDecimals() correctly rounds a number', ->
    deepEqual @dataRow.roundToTwoDecimals(92.345), 92.35
    deepEqual @dataRow.roundToTwoDecimals(92.344), 92.34
    deepEqual @dataRow.roundToTwoDecimals(89.999), 90.00

  module 'DataRow being edited',
    setup: ->
      props =
        key: 0
        uniqueId: 0
        row: ['A', 92.346]
        editing: true
        onRowMinScoreChange: ->
        onRowNameChange: ->
        onDeleteRow: ->

      @dataRow = React.renderComponent(DataRow(props), $('<table>').appendTo('body')[0])

    teardown: ->
      React.unmountComponentAtNode(@dataRow.getDOMNode().parentNode)

  test 'renders in "edit" mode (as opposed to "view" mode)', ->
    ok @dataRow.refs.editContainer

  test 'does not accept non-numeric input', ->
    changeMinScore = sinon.spy(@dataRow.props, 'onRowMinScoreChange')
    Simulate.change(@dataRow.refs.minScoreInput.getDOMNode(), {target: {value: 'A'}})
    deepEqual @dataRow.renderMinScore(), '92.35'
    Simulate.change(@dataRow.refs.minScoreInput.getDOMNode(), {target: {value: '*&@%!'}})
    deepEqual @dataRow.renderMinScore(), '92.35'
    Simulate.change(@dataRow.refs.minScoreInput.getDOMNode(), {target: {value: '3B'}})
    deepEqual @dataRow.renderMinScore(), '92.35'
    ok changeMinScore.notCalled

  test 'does not call onRowMinScoreChange if the input is less than 0', ->
    changeMinScore = sinon.spy(@dataRow.props, 'onRowMinScoreChange')
    Simulate.change(@dataRow.refs.minScoreInput.getDOMNode(), {target: {value: '-1'}})
    ok changeMinScore.notCalled

  test 'does not call onRowMinScoreChange if the input is greater than 100', ->
    changeMinScore = sinon.spy(@dataRow.props, 'onRowMinScoreChange')
    Simulate.change(@dataRow.refs.minScoreInput.getDOMNode(), {target: {value: '101'}})
    ok changeMinScore.notCalled

  test 'calls onRowMinScoreChange when input is a number between 0 and 100 (with or without a trailing period), or blank', ->
    changeMinScore = sinon.spy(@dataRow.props, 'onRowMinScoreChange')
    Simulate.change(@dataRow.refs.minScoreInput.getDOMNode(), {target: {value: '88.'}})
    Simulate.change(@dataRow.refs.minScoreInput.getDOMNode(), {target: {value: ''}})
    Simulate.change(@dataRow.refs.minScoreInput.getDOMNode(), {target: {value: '100'}})
    Simulate.change(@dataRow.refs.minScoreInput.getDOMNode(), {target: {value: '0'}})
    Simulate.change(@dataRow.refs.minScoreInput.getDOMNode(), {target: {value: 'A'}})
    Simulate.change(@dataRow.refs.minScoreInput.getDOMNode(), {target: {value: '%*@#($'}})
    deepEqual changeMinScore.callCount, 4

  test 'calls onRowNameChange when input changes', ->
    changeMinScore = sinon.spy(@dataRow.props, 'onRowNameChange')
    Simulate.change(@dataRow.refs.nameInput.getDOMNode(), {target: {value: 'F'}})
    ok changeMinScore.calledOnce

  test 'shows the link to insert a row on focus of the current row', ->
    deepEqual @dataRow.refs.insertRowLink, undefined
    Simulate.focus(@dataRow.refs.editContainer.getDOMNode())
    ok @dataRow.refs.insertRowLink

  test 'shows the link to insert a row on mouseEnter of the current row', ->
    deepEqual @dataRow.refs.insertRowLink, undefined
    #Simulate does not currently support mouseEnter, this is a workaround
    SimulateNative.mouseOver(@dataRow.refs.editContainer.getDOMNode())
    ok @dataRow.refs.insertRowLink

  test 'hides the link to insert a row on mouseLeave', ->
    Simulate.focus(@dataRow.refs.editContainer.getDOMNode())
    ok @dataRow.refs.insertRowLink
    #Simulate does not currently support mouseEnter, this is a workaround
    SimulateNative.mouseOut(@dataRow.refs.editContainer.getDOMNode())
    deepEqual @dataRow.refs.insertRowLink, undefined

  test 'calls onDeleteRow when the delete link is clicked', ->
    deleteRow = sinon.spy(@dataRow.props, 'onDeleteRow')
    Simulate.click(@dataRow.refs.deleteLink.getDOMNode())
    ok deleteRow.calledOnce

  module 'DataRow with a sibling',
    setup: ->
      props =
        key: 1
        row: ['A-', 90.0]
        siblingRow: ['A', 92.346]
        editing: false

      @dataRow = React.renderComponent(DataRow(props), $('<table>').appendTo('body')[0])

    teardown: ->
      React.unmountComponentAtNode(@dataRow.getDOMNode().parentNode)

  test "shows the max score as the sibling's min score", ->
    deepEqual @dataRow.renderMaxScore(), '< 92.35'

  module 'DataRow not being edited with a minScore of 0',
    setup: ->
      props =
        key: 0
        uniqueId: 0
        row: ['F', 0.0]
        editing: false

      @dataRow = React.render(DataRow(props), $('<table>').appendTo('body')[0])

    teardown: ->
      React.unmountComponentAtNode(@dataRow.getDOMNode().parentNode)

  test 'renderMinScore() returns the correct score for scores of 0', ->
    deepEqual @dataRow.renderMinScore(), '0'

  module 'DataRow being edited with a blank min score',
    setup: ->
      props =
        key: 0
        uniqueId: 0
        row: ['F', '']
        editing: true

      @dataRow = React.render(DataRow(props), $('<table>').appendTo('body')[0])

    teardown: ->
      React.unmountComponentAtNode(@dataRow.getDOMNode().parentNode)

  test 'renderMinScore() returns the empty string', ->
    deepEqual @dataRow.renderMinScore(), ''
