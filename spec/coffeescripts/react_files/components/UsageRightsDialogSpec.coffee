define [
  'react'
  'react-dom'
  'react-addons-test-utils'
  'jquery'
  'jsx/files/UsageRightsDialog'
  'compiled/models/File'
  'compiled/models/Folder'
], (React, ReactDOM, TestUtils, $, UsageRightsDialog, File, Folder) ->

  module 'UsageRightsDialog',
    setup: ->
    teardown: ->
      $("#ui-datepicker-div").empty()
      $(".ui-dialog").remove()
      $("div[id^=ui-id-]").remove()

  test 'clicking cancelXButton closes modal', ->
    usage_rights = {
      use_justification: 'choose'
    }

    modalClosed = false
    props = {
      closeModal: -> modalClosed = true
      itemsToManage: [new File(thumbnail_url: 'blah', usage_rights: usage_rights)]
    }

    uRD = TestUtils.renderIntoDocument(React.createElement(UsageRightsDialog, props))
    TestUtils.Simulate.click(uRD.refs.cancelXButton.getDOMNode())

    ok modalClosed

    ReactDOM.unmountComponentAtNode(uRD.getDOMNode().parentNode)
  test 'clicking canel closes the modal', ->
    usage_rights = {
      use_justification: 'choose'
    }

    modalClosed = false
    props = {
      closeModal: -> modalClosed = true
      itemsToManage: [new File(thumbnail_url: 'blah', usage_rights: usage_rights)]
    }

    uRD = TestUtils.renderIntoDocument(React.createElement(UsageRightsDialog, props))
    TestUtils.Simulate.click(uRD.refs.cancelButton.getDOMNode())

    ok modalClosed

    ReactDOM.unmountComponentAtNode(uRD.getDOMNode().parentNode)

  test 'render the file name with multiple items', ->
    usage_rights = {
      use_justification: 'choose'
    }

    props = {
      closeModal: ->
      itemsToManage: [new File(thumbnail_url: 'blah', usage_rights: usage_rights), new File(thumbnail_url: 'blah', usage_rights: usage_rights)]
    }

    uRD = TestUtils.renderIntoDocument(React.createElement(UsageRightsDialog, props))

    equal uRD.refs.fileName.getDOMNode().innerHTML, "2 items selected", "has correct message"

    ReactDOM.unmountComponentAtNode(uRD.getDOMNode().parentNode)

  test 'render the file name with one item', ->
    usage_rights = {
      use_justification: 'choose'
    }

    file = new File(thumbnail_url: 'blah', usage_rights: usage_rights)
    file.displayName = -> "cats"

    props = {
      closeModal: ->
      itemsToManage: [file]
    }

    uRD = TestUtils.renderIntoDocument(React.createElement(UsageRightsDialog, props))

    equal uRD.refs.fileName.getDOMNode().innerHTML, "cats", "has correct message"

    ReactDOM.unmountComponentAtNode(uRD.getDOMNode().parentNode)

  test 'render different right message', ->
    usage_rights = {
      use_justification: 'own_copyright'
    }

    usage_rights2 = {
      use_justification: 'used_by_permission'
    }

    file = new File(thumbnail_url: 'blah', usage_rights: usage_rights)
    file.displayName = -> "cats"

    file2 = new File(thumbnail_url: 'blah', usage_rights: usage_rights)
    file.displayName = -> "cats2"

    props = {
      closeModal: ->
      itemsToManage: [file, file2]
    }

    uRD = TestUtils.renderIntoDocument(React.createElement(UsageRightsDialog, props))

    equal uRD.refs.differentRightsMessage.props.children[1], "Items selected have different usage rights.", "displays correct message"

    ReactDOM.unmountComponentAtNode(uRD.getDOMNode().parentNode)

  test 'do not render different rights message when they are the same', ->
    usage_rights = {
      use_justification: 'own_copyright',
      legal_copyright: ''
    }

    file = new File(thumbnail_url: 'blah', usage_rights: usage_rights)
    file.displayName = -> "cats"

    file2 = new File(thumbnail_url: 'blah', usage_rights: usage_rights)
    file2.displayName = -> "cats"

    props = {
      closeModal: ->
      itemsToManage: [file, file2]
    }

    uRD = TestUtils.renderIntoDocument(React.createElement(UsageRightsDialog, props))
    ok !uRD.refs.differentRightsMessage, "does not show the message"

    ReactDOM.unmountComponentAtNode(uRD.getDOMNode().parentNode)

  test 'render folder message for one folder', ->
    usage_rights = {
      use_justification: 'choose'
    }

    folder = new Folder(usage_rights: usage_rights)
    folder.displayName = -> "some folder"

    props = {
      closeModal: ->
      itemsToManage: [folder]
    }

    uRD = TestUtils.renderIntoDocument(React.createElement(UsageRightsDialog, props))

    equal uRD.refs.folderBulletList.props.children[0].props.children, "some folder", "shows display name"

    ReactDOM.unmountComponentAtNode(uRD.getDOMNode().parentNode)

  test 'render folder tooltip for multiple folders', ->
    usage_rights = {
      use_justification: 'choose'
    }

    folder = new Folder(usage_rights: usage_rights)
    folder.displayName = -> "hello"

    props = {
      closeModal: ->
      itemsToManage: [folder, folder, folder, folder]
    }

    uRD = TestUtils.renderIntoDocument(React.createElement(UsageRightsDialog, props))

    equal uRD.refs.folderTooltip.getDOMNode().getAttribute('data-html-tooltip-title'), "hello<br />hello", "sets title for multple folders"
    equal uRD.refs.folderTooltip.props.children[0], "and 2 more…", "sets count text"

    ReactDOM.unmountComponentAtNode(uRD.getDOMNode().parentNode)

  module 'UploadProgress: Submitting'

  test 'validate they selected usage right', ->
    usage_rights = {
      use_justification: 'choose'
    }

    file = new File(thumbnail_url: 'blah', usage_rights: usage_rights)
    file.displayName = -> "hello"

    props = {
      closeModal: ->
      itemsToManage: [file]
    }

    uRD = TestUtils.renderIntoDocument(React.createElement(UsageRightsDialog, props))

    uRD.refs.usageSelection.getValues = -> {use_justification: "choose"}

    equal uRD.submit(), false, "returns false"

    ReactDOM.unmountComponentAtNode(uRD.getDOMNode().parentNode)
