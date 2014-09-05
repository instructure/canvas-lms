define [
  'react'
  'react-router'
  'compiled/react_files/components/Toolbar'
], (React, Router, Toolbar) ->

  Simulate = React.addons.TestUtils.Simulate

  module 'Toolbar',
    setup: ->
      @toolbar = React.renderComponent(Toolbar({params: 'foo', query:'', selectedItems: ''}), $('#fixtures')[0])
    teardown: ->
      React.unmountComponentAtNode($('#fixtures')[0])

  test 'transitions to a search url when search form is submitted', ->
    sinon.stub(Router, 'transitionTo')
    searchFieldNode = @toolbar.refs.searchTerm.getDOMNode()

    searchFieldNode.value = 'foo'
    Simulate.submit(searchFieldNode)

    ok Router.transitionTo.calledWith('search', 'foo', {search_term: 'foo'}), 'transitions to correct url when search is submitted'
    Router.transitionTo.restore()

  module 'Toolbar Rendering',
    setup: ->
    teardown: ->

  test 'renders multi select action items when there is more than one item selected', ->
    @toolbar = React.renderComponent(Toolbar({params: 'foo', query:'', selectedItems: ['foo']}), $('#fixtures')[0])

    ok $('.ef-selected-items-actions').length, 'shows multiple select action items'

    React.unmountComponentAtNode($('#fixtures')[0])
