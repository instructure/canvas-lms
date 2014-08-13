define [
  'react'
  'jquery'
  'compiled/react_files/components/ItemCog'
  'compiled/models/Folder'
], (React, $, ItemCog, Folder) ->

  Simulate = React.addons.TestUtils.Simulate

  module 'ItemCog',
    setup: ->

      sampleProps =
        model: new Folder(id: 999)
        startEditingName: -> debugger

      @itemCog = React.renderComponent(ItemCog(sampleProps), $('<div>').appendTo('body')[0])

    teardown: ->
      React.unmountComponentAtNode(@itemCog.getDOMNode().parentNode)


  test 'deletes model when delete link is pressed', ->
    sinon.stub($, 'ajax')
    sinon.stub(window, 'confirm').returns(true)

    Simulate.click(@itemCog.refs.deleteLink.getDOMNode())

    ok window.confirm.calledOnce, 'confirms before deleting'
    ok $.ajax.calledWithMatch({url: '/api/v1/folders/999', type: 'DELETE'}), 'sends DELETE to right url'

    window.confirm.restore()
    $.ajax.restore()

  test 'clicking restricted dialog opens a dialog', ->
    sinon.stub(React, 'renderComponent')
    sinon.spy($.fn, 'dialog')
    Simulate.click(@itemCog.refs.restrictedDialog.getDOMNode())

    ok $.fn.dialog.calledOnce, 'opens a restricted dialog window'
    ok React.renderComponent.calledOnce, 'renders a component inside the dialog'
    $.fn.dialog.restore()
    React.renderComponent.restore()


