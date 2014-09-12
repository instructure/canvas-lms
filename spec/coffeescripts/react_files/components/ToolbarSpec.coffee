define [
  'jquery'
  'react'
  'react-router'
  'compiled/react_files/components/Toolbar'
], ($, React, Router, Toolbar) ->

  Simulate = React.addons.TestUtils.Simulate

  module 'Toolbar',
    setup: ->
      @toolbar = React.renderComponent(Toolbar({params: 'foo', query:'', selectedItems: ''}), $('<div>').appendTo('body')[0])
    teardown: ->
      React.unmountComponentAtNode(@toolbar.getDOMNode().parentNode)


  test 'transitions to a search url when search form is submitted', ->
    stubbedTransitionTo = sinon.stub(Router, 'transitionTo')
    searchFieldNode = @toolbar.refs.searchTerm.getDOMNode()

    searchFieldNode.value = 'foo'
    Simulate.submit(searchFieldNode)

    ok Router.transitionTo.calledWith('search', 'foo', {search_term: 'foo'}), 'transitions to correct url when search is submitted'
    stubbedTransitionTo.restore()

  module 'Toolbar Rendering'

  test 'renders multi select action items when there is more than one item selected', ->
    toolbar = React.renderComponent(Toolbar({params: 'foo', query:'', selectedItems: ['foo']}), $('<div>').appendTo('body')[0])
    ok $(toolbar.getDOMNode()).find('.ui-buttonset .ui-button').length, 'shows multiple select action items'
    React.unmountComponentAtNode(toolbar.getDOMNode().parentNode)
