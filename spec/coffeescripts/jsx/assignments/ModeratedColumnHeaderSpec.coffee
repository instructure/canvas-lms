define [
  'react'
  'jsx/assignments/ModeratedColumnHeader'
  'jsx/assignments/constants'
], (React, ModeratedColumnHeader, Constants) ->
  TestUtils = React.addons.TestUtils

  module 'ModeratedColumnHeader',
  test 'calls the handleSortMark1 function when mark1 sort is pressed', ->
    callback = sinon.spy()
    columnHeader = TestUtils.renderIntoDocument(ModeratedColumnHeader(markColumn: Constants.markColumnNames.MARK_ONE, currentSortDirection: Constants.sortDirections.DESCENDING, handleSortMark1: callback ))
    headers = TestUtils.scryRenderedDOMComponentsWithClass(columnHeader, 'ColumnHeader__Mark')
    link = TestUtils.findRenderedDOMComponentWithTag(headers[0], 'a')
    TestUtils.Simulate.click(link.getDOMNode())
    ok callback.called
    React.unmountComponentAtNode(columnHeader.getDOMNode().parentNode)

  test 'calls the handleSortMark2 function when mark2 sort is pressed', ->
    callback = sinon.spy()
    columnHeader = TestUtils.renderIntoDocument(ModeratedColumnHeader(includeModerationSetHeaders:true, markColumn: Constants.markColumnNames.MARK_TWO, currentSortDirection: Constants.sortDirections.DESCENDING, handleSortMark2: callback ))
    headers = TestUtils.scryRenderedDOMComponentsWithClass(columnHeader, 'ColumnHeader__Mark')
    link = TestUtils.findRenderedDOMComponentWithTag(headers[0], 'a')
    TestUtils.Simulate.click(link.getDOMNode())
    ok callback.called
    React.unmountComponentAtNode(columnHeader.getDOMNode().parentNode)

  test 'calls the handleSortMark3 function when mark3 sort is pressed', ->
    callback = sinon.spy()
    columnHeader = TestUtils.renderIntoDocument(ModeratedColumnHeader(includeModerationSetHeaders:true, markColumn: Constants.markColumnNames.MARK_THREE, currentSortDirection: Constants.sortDirections.DESCENDING, handleSortMark3: callback ))
    headers = TestUtils.scryRenderedDOMComponentsWithClass(columnHeader, 'ColumnHeader__Mark')
    link = TestUtils.findRenderedDOMComponentWithTag(headers[1], 'a')
    TestUtils.Simulate.click(link.getDOMNode())
    ok callback.called
    React.unmountComponentAtNode(columnHeader.getDOMNode().parentNode)

  test 'displays down arrow when sort direction is DESCENDING', ->
    columnHeader = TestUtils.renderIntoDocument(ModeratedColumnHeader(markColumn: Constants.markColumnNames.MARK_ONE, sortDirection: Constants.sortDirections.DESCENDING))
    headers = TestUtils.scryRenderedDOMComponentsWithClass(columnHeader, 'ColumnHeader__Mark')
    ok TestUtils. findRenderedDOMComponentWithClass(headers[0], 'icon-mini-arrow-down'), 'finds the down arrow'
    React.unmountComponentAtNode(columnHeader.getDOMNode().parentNode)

  test 'displays up arrow when sort direction is ASCENDING', ->
    columnHeader = TestUtils.renderIntoDocument(ModeratedColumnHeader(markColumn: Constants.markColumnNames.MARK_ONE, sortDirection: Constants.sortDirections.ASCENDING))
    headers = TestUtils.scryRenderedDOMComponentsWithClass(columnHeader, 'ColumnHeader__Mark')
    ok TestUtils. findRenderedDOMComponentWithClass(headers[0], 'icon-mini-arrow-up'), 'finds the up arrow'
    React.unmountComponentAtNode(columnHeader.getDOMNode().parentNode)

  test 'only shows two column when includeModerationSetHeaders is false', ->
    # Tests that name is shown and one grade
    columnHeader = TestUtils.renderIntoDocument(ModeratedColumnHeader(includeModerationSetHeaders: false, markColumn: Constants.markColumnNames.MARK_ONE, sortDirection: Constants.sortDirections.ASCENDING))
    headers = TestUtils.scryRenderedDOMComponentsWithClass(columnHeader, 'ColumnHeader__Item')
    equal headers.length, 2, 'only shows two header columns'
    React.unmountComponentAtNode(columnHeader.getDOMNode().parentNode)

  test 'only shows all columns when includeModerationSetHeaders is true', ->
    columnHeader = TestUtils.renderIntoDocument(ModeratedColumnHeader(includeModerationSetHeaders: true, markColumn: Constants.markColumnNames.MARK_ONE, sortDirection: Constants.sortDirections.ASCENDING))
    headers = TestUtils.scryRenderedDOMComponentsWithClass(columnHeader, 'ColumnHeader__Item')
    equal headers.length, 5, 'show all headers when true'
    React.unmountComponentAtNode(columnHeader.getDOMNode().parentNode)

