define [
  'react'
  'jsx/assignments/ModeratedColumnHeader'
  'jsx/assignments/constants'
], (React, ModeratedColumnHeader, Constants) ->
  TestUtils = React.addons.TestUtils

  module 'ModeratedColumnHeader',
    setup: ->
      @props =
        markColumn: Constants.markColumnNames.MARK_ONE
        currentSortDirection: Constants.sortDirections.DESCENDING
        includeModerationSetHeaders:true
        handleSortMark1: ->
        handleSortMark2: ->
        handleSortMark3: ->
        handleSelectAll: ->
    teardown: ->
      @props = null

  test 'calls the handleSortMark1 function when mark1 sort is pressed', ->
    callback = sinon.spy()

    @props.handleSortMark1 = callback
    @props.includeModerationSetHeaders = false

    columnHeader = TestUtils.renderIntoDocument(React.createElement(ModeratedColumnHeader, @props))
    link = TestUtils.findRenderedDOMComponentWithTag(columnHeader, 'a')
    TestUtils.Simulate.click(link)
    ok callback.called
    React.unmountComponentAtNode(columnHeader.getDOMNode().parentNode)

  test 'calls the handleSortMark2 function when mark2 sort is pressed', ->
    callback = sinon.spy()

    @props.markColumn = Constants.markColumnNames.MARK_TWO
    @props.handleSortMark2 = callback

    columnHeader = TestUtils.renderIntoDocument(React.createElement(ModeratedColumnHeader, @props))
    links = TestUtils.scryRenderedDOMComponentsWithTag(columnHeader, 'a')
    TestUtils.Simulate.click(links[1])
    ok callback.called
    React.unmountComponentAtNode(columnHeader.getDOMNode().parentNode)

  test 'calls the handleSortMark3 function when mark3 sort is pressed', ->
    callback = sinon.spy()

    @props.markColumn = Constants.markColumnNames.MARK_THREE
    @props.currentSortDirection = Constants.sortDirections.DESCENDING
    @props.handleSortMark3 = callback

    columnHeader = TestUtils.renderIntoDocument(React.createElement(ModeratedColumnHeader, @props))
    links = TestUtils.scryRenderedDOMComponentsWithTag(columnHeader, 'a')
    TestUtils.Simulate.click(links[2])
    ok callback.called
    React.unmountComponentAtNode(columnHeader.getDOMNode().parentNode)

  test 'calls the handleSelectAll function when the select all checkbox is checked', ->
    callback = sinon.spy()

    @props.handleSelectAll = callback

    columnHeader = TestUtils.renderIntoDocument(React.createElement(ModeratedColumnHeader, @props))
    checkbox = TestUtils.findRenderedDOMComponentWithTag(columnHeader, 'input')
    TestUtils.Simulate.change(checkbox.getDOMNode())
    ok callback.called
    React.unmountComponentAtNode(columnHeader.getDOMNode().parentNode)


  test 'displays down arrow when sort direction is DESCENDING', ->
    @props.markColumn = Constants.markColumnNames.MARK_ONE
    @props.sortDirection = Constants.sortDirections.DESCENDING
    @props.includeModerationSetHeaders = false

    columnHeader = TestUtils.renderIntoDocument(React.createElement(ModeratedColumnHeader, @props))
    ok TestUtils. findRenderedDOMComponentWithClass(columnHeader, 'icon-mini-arrow-down'), 'finds the down arrow'
    React.unmountComponentAtNode(columnHeader.getDOMNode().parentNode)

  test 'displays up arrow when sort direction is ASCENDING', ->
    @props.markColumn = Constants.markColumnNames.MARK_ONE
    @props.sortDirection = Constants.sortDirections.ASCENDING
    @props.includeModerationSetHeaders = false

    columnHeader = TestUtils.renderIntoDocument(React.createElement(ModeratedColumnHeader, @props))
    ok TestUtils. findRenderedDOMComponentWithClass(columnHeader, 'icon-mini-arrow-up'), 'finds the up arrow'
    React.unmountComponentAtNode(columnHeader.getDOMNode().parentNode)

  test 'only shows two column when includeModerationSetHeaders is false', ->
    # Tests that name is shown and one grade
    @props.includeModerationSetHeaders = false

    columnHeader = TestUtils.renderIntoDocument(React.createElement(ModeratedColumnHeader, @props))
    headers = TestUtils.scryRenderedDOMComponentsWithClass(columnHeader, 'ColumnHeader__Item')
    equal headers.length, 2, 'only shows two header columns'
    React.unmountComponentAtNode(columnHeader.getDOMNode().parentNode)

  test 'only shows all columns when includeModerationSetHeaders is true', ->
    columnHeader = TestUtils.renderIntoDocument(React.createElement(ModeratedColumnHeader, @props))
    headers = TestUtils.scryRenderedDOMComponentsWithClass(columnHeader, 'ColumnHeader__Item')
    equal headers.length, 5, 'show all headers when true'
    React.unmountComponentAtNode(columnHeader.getDOMNode().parentNode)

