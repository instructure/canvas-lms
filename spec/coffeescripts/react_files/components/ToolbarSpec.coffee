define [
  'jquery'
  'react'
  'react-router'
  'compiled/react_files/components/Toolbar'
  'compiled/react_files/routes'
], ($, React, Router, Toolbar, routes) ->

  Simulate = React.addons.TestUtils.Simulate

  # module 'Toolbar',
  #   setup: ->
  #     @routes = React.addons.TestUtils.renderIntoDocument(routes)
  #     debugger
  #     @toolbar = React.renderComponent(Toolbar({params: 'foo', query:'', selectedItems: '', contextId: "1", contextType: "courses"}), $('<div>').appendTo('body')[0])
  #   teardown: ->
  #     React.unmountComponentAtNode(@toolbar.getDOMNode().parentNode)


  # test 'transitions to a search url when search form is submitted', ->
  #   stubbedTransitionTo = sinon.stub(Router, 'transitionTo')
  #   searchFieldNode = @toolbar.refs.searchTerm.getDOMNode()

  #   searchFieldNode.value = 'foo'
  #   Simulate.submit(searchFieldNode)

  #   ok Router.transitionTo.calledWith('search', 'foo', {search_term: 'foo'}), 'transitions to correct url when search is submitted'
  #   stubbedTransitionTo.restore()

  # module 'Toolbar Rendering'

  # test 'renders multi select action items when there is more than one item selected', ->
  #   toolbar = React.renderComponent(Toolbar({params: 'foo', query:'', selectedItems: ['foo'], contextId: "1", contextType: "courses"}), $('<div>').appendTo('body')[0])
  #   ok $(toolbar.getDOMNode()).find('.ui-buttonset .ui-button').length, 'shows multiple select action items'
  #   React.unmountComponentAtNode(toolbar.getDOMNode().parentNode)

  # module 'Toolbar Permissions',
  #   setup: ->
  #     @buttonsEnabled = ($toolbar, config) ->
  #       valid = true
  #       for prop of config
  #         button = $toolbar.find(prop).length
  #         if (config[prop] is true and !!button) or (config[prop] is false and !button)
  #           continue
  #         else
  #           valid = false
  #       valid

  #     @toolbarComponent = require 'compiled/react_files/components/Toolbar'
  #     Folder = require 'compiled/models/Folder'
  #     @courseFolder = new Folder({context_type: "Course", context_id: 1})
  #     @userFolder = new Folder({context_type: "User", context_id: 2})

  #     @readConfig =
  #       ".btn-view": true
  #       ".btn-download": true
  #       ".btn-move": false
  #       ".btn-restrict": false
  #       ".btn-delete": false
  #       ".btn-add-folder": false
  #       ".btn-upload": false

  #     @manageConfig =
  #       ".btn-view": true
  #       ".btn-download": true
  #       ".btn-move": true
  #       ".btn-restrict": true
  #       ".btn-delete": true
  #       ".btn-add-folder": true
  #       ".btn-upload": true

  # test 'renders only view and download buttons for limited users', ->
  #   toolbar = React.renderComponent(@toolbarComponent({params: 'foo', query:'', selectedItems: ['foo'], currentFolder: @userFolder, contextId: "2", contextType: "users", userCanManageFilesForContext: false}), $('<div>').appendTo('body')[0])
  #   ok @buttonsEnabled($(toolbar.getDOMNode()), @readConfig), "only view and download buttons are shown"

  # test 'renders all buttons for users with manage_files permissions', ->
  #   toolbar = React.renderComponent(@toolbarComponent({params: 'foo', query:'', selectedItems: ['foo'], currentFolder: @courseFolder, contextId: "1", contextType: "courses", userCanManageFilesForContext: true}), $('<div>').appendTo('body')[0])
  #   ok @buttonsEnabled($(toolbar.getDOMNode()), @manageConfig), "move, restrict access, delete, add folder, and upload file buttons are additionally shown for users with manage_files permissions"