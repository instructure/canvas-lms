define [
  'react'
  'jsx/assignments/ModeratedColumnHeader'
  'jsx/assignments/constants'
], (React, ModeratedColumnHeader, Constants) ->
  TestUtils = React.addons.TestUtils

  module 'ModeratedColumnHeader',
  test 'calls the handleSortByThisColumn fucntion when sort is pressed', ->
    callback = sinon.spy()
    columnHeader = TestUtils.renderIntoDocument(ModeratedColumnHeader(markColumn: 0, currentSortDirection: Constants.sortDirections.HIGHEST, handleSortByThisColumn: callback ))
    headers = TestUtils.scryRenderedDOMComponentsWithClass(columnHeader, 'ColumnHeader__ColumnItem')
    link = TestUtils.findRenderedDOMComponentWithTag(headers[0], 'a')
    TestUtils.Simulate.click(link.getDOMNode())
    ok callback.calledWith(0,{markColumn: 0, currentSortDirection: Constants.sortDirections.HIGHEST, handleSortByThisColumn: callback})
    React.unmountComponentAtNode(columnHeader.getDOMNode().parentNode)

  test 'displays down arrow when sort direction is highest', ->
    columnHeader = TestUtils.renderIntoDocument(ModeratedColumnHeader(markColumn: 0, currentSortDirection: Constants.sortDirections.HIGHEST, handleSortByThisColumn: () => 'nothing here' ))
    headers = TestUtils.scryRenderedDOMComponentsWithClass(columnHeader, 'ColumnHeader__ColumnItem')
    ok TestUtils. findRenderedDOMComponentWithClass(headers[0], 'icon-mini-arrow-down'), 'finds the up arrow'
    React.unmountComponentAtNode(columnHeader.getDOMNode().parentNode)

  test 'displays up arrow when sort direction is lowest', ->
    columnHeader = TestUtils.renderIntoDocument(ModeratedColumnHeader(markColumn: 0, currentSortDirection: Constants.sortDirections.LOWEST, handleSortByThisColumn: () => 'nothing here' ))
    headers = TestUtils.scryRenderedDOMComponentsWithClass(columnHeader, 'ColumnHeader__ColumnItem')
    ok TestUtils. findRenderedDOMComponentWithClass(headers[0], 'icon-mini-arrow-up'), 'finds the up arrow'
    React.unmountComponentAtNode(columnHeader.getDOMNode().parentNode)
