define [
  'react'
  'jquery'
  'compiled/react_files/components/ColumnHeaders'
  'compiled/models/Folder'
  'react-router'
], (React, $, ColumnHeaders, Folder, ReactRouter) ->
  Simulate = React.addons.TestUtils.Simulate

  module 'ColumnHeaders#queryParamsFor',
    setup: ->
    teardown: ->

  test 'returns object with sort property set from the passed in variable', ->
    sinon.stub(ReactRouter, 'Link').returns("some link")
    @columnHeaders = React.renderComponent(ColumnHeaders(query:{}), $('<div>').appendTo('body')[0])
    propertyString = 'some property string'
    queryParams = @columnHeaders.queryParamsFor(propertyString)

    equal queryParams.sort, propertyString, 'sort property is equal to the passed in property'

    ReactRouter.Link.restore()
    React.unmountComponentAtNode(@columnHeaders.getDOMNode().parentNode)

  test 'toggle order to ascending when property passed in is name and query.order is desc', ->
    sinon.stub(ReactRouter, 'Link').returns("some link")
    @columnHeaders = React.renderComponent(ColumnHeaders(query:{order: 'desc'}), $('<div>').appendTo('body')[0])
    propertyString = 'name'
    queryParams = @columnHeaders.queryParamsFor(propertyString)

    equal queryParams.order, 'asc', 'sets order to asc'

    ReactRouter.Link.restore()
    React.unmountComponentAtNode(@columnHeaders.getDOMNode().parentNode)

  test 'toggle order to descending when property passed in is not name or query.order is not desc', ->
    sinon.stub(ReactRouter, 'Link').returns("some link")
    @columnHeaders = React.renderComponent(ColumnHeaders(query:{order: 'asc'}), $('<div>').appendTo('body')[0])
    propertyString = 'foo'
    queryParams = @columnHeaders.queryParamsFor(propertyString)

    equal queryParams.order, 'desc', 'sets order to desc'

    ReactRouter.Link.restore()
    React.unmountComponentAtNode(@columnHeaders.getDOMNode().parentNode)
