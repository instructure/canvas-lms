define [
  'react'
  'jquery'
  'compiled/react_files/components/ItemCog'
  'compiled/models/Folder'
], (React, $, ItemCog, Folder) ->

  Simulate = React.addons.TestUtils.Simulate

  module 'ItemCog',
    setup: ->

      @sampleProps = (canManageFiles = false) ->
        model: new Folder(id: 999)
        modalOptions:
          closeModal: ->
          openModal: ->
        startEditingName: ->
        userCanManageFilesForContext: canManageFiles


      @buttonsEnabled = (itemCog, config) ->
        valid = true
        for prop of config
          button = if typeof itemCog.refs?[prop] isnt 'undefined' then $(itemCog.refs?[prop].getDOMNode()).length else false
          if (config[prop] is true and !!button) or (config[prop] is false and !button)
            continue
          else
            valid = false
        valid

      @readOnlyConfig =
        'download': true
        'editName': false
        'restrictedDialog': false
        'move': false
        'deleteLink': false

      @manageFilesConfig =
        'download': true
        'editName': true
        'restrictedDialog': true
        'move': true
        'deleteLink': true

      @itemCog = React.render(ItemCog(@sampleProps(true)), $('<div>').appendTo('#fixtures')[0])

    teardown: ->
      React.unmountComponentAtNode(@itemCog.getDOMNode().parentNode)
      $("#fixtures").empty()

  test 'deletes model when delete link is pressed', ->
    ajaxSpy = @spy($, 'ajax')
    @stub(window, 'confirm').returns(true)

    Simulate.click(@itemCog.refs.deleteLink.getDOMNode())

    ok window.confirm.calledOnce, 'confirms before deleting'
    ok ajaxSpy.calledWithMatch({url: '/api/v1/folders/999', type: 'DELETE', data: {force: 'true'}}), 'sends DELETE to right url'

  test 'only shows download button for limited users', ->
    readOnlyItemCog = React.render(ItemCog(@sampleProps(false)), $('<div>').appendTo('#fixtures')[0])
    ok @buttonsEnabled(readOnlyItemCog, @readOnlyConfig), 'only download button is shown'

  test 'shows all buttons for users with manage_files permissions', ->
    ok @buttonsEnabled(@itemCog, @manageConfig), 'all buttons are shown'
