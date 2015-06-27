
define [
  'react'
  'jquery'
  'compiled/react_files/components/UsageRightsDialog'
  'compiled/models/File'
  'compiled/models/Folder'
], (React, $, UsageRightsDialog, File, Folder) ->

  TestUtils = React.addons.TestUtils
  UsageRightsDialog = React.createFactory(UsageRightsDialog)

  module 'UploadProgress',

  test 'clicking cancelXButton closes modal', ->
    usage_rights = {
      use_justification: 'choose'
    }

    modalClosed = false
    props = {
      closeModal: -> modalClosed = true
      itemsToManage: [new File(thumbnail_url: 'blah', usage_rights: usage_rights)]
    }

    uRD = TestUtils.renderIntoDocument(UsageRightsDialog(props))
    TestUtils.Simulate.click(uRD.refs.cancelXButton.getDOMNode())

    ok modalClosed

    React.unmountComponentAtNode(uRD.getDOMNode().parentNode)
  test 'clicking canel closes the modal', ->
    usage_rights = {
      use_justification: 'choose'
    }

    modalClosed = false
    props = {
      closeModal: -> modalClosed = true
      itemsToManage: [new File(thumbnail_url: 'blah', usage_rights: usage_rights)]
    }

    uRD = TestUtils.renderIntoDocument(UsageRightsDialog(props))
    TestUtils.Simulate.click(uRD.refs.cancelButton.getDOMNode())

    ok modalClosed

    React.unmountComponentAtNode(uRD.getDOMNode().parentNode)

  test 'render the file name with multiple items', ->
    usage_rights = {
      use_justification: 'choose'
    }

    props = {
      closeModal: ->
      itemsToManage: [new File(thumbnail_url: 'blah', usage_rights: usage_rights), new File(thumbnail_url: 'blah', usage_rights: usage_rights)]
    }

    uRD = TestUtils.renderIntoDocument(UsageRightsDialog(props))

    equal uRD.refs.fileName.getDOMNode().innerHTML, "2 items selected", "has correct message"

    React.unmountComponentAtNode(uRD.getDOMNode().parentNode)

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

    uRD = TestUtils.renderIntoDocument(UsageRightsDialog(props))

    equal uRD.refs.fileName.getDOMNode().innerHTML, "cats", "has correct message"

    React.unmountComponentAtNode(uRD.getDOMNode().parentNode)

  test 'render different right message', ->
    usage_rights = {
      use_justification: 'choose'
    }

    file = new File(thumbnail_url: 'blah', usage_rights: usage_rights)
    file.displayName = -> "cats"

    props = {
      closeModal: ->
      itemsToManage: [file, file]
    }

    uRD = TestUtils.renderIntoDocument(UsageRightsDialog(props))

    equal uRD.refs.differentRightsMessage.props.children[1], "Items selected have different usage rights.", "displays correct message"

    React.unmountComponentAtNode(uRD.getDOMNode().parentNode)

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

    uRD = TestUtils.renderIntoDocument(UsageRightsDialog(props))

    equal uRD.refs.folderBulletList.props.children[0].props.children, "some folder", "shows display name"

    React.unmountComponentAtNode(uRD.getDOMNode().parentNode)

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

    uRD = TestUtils.renderIntoDocument(UsageRightsDialog(props))

    equal uRD.refs.folderTooltip.getDOMNode().getAttribute('title'), "hello<br />hello", "sets title for multple folders"
    equal uRD.refs.folderTooltip.props.children[0], "and 2 more…", "sets count text"

    React.unmountComponentAtNode(uRD.getDOMNode().parentNode)

  module 'UploadProgress: Submitting',

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

    uRD = TestUtils.renderIntoDocument(UsageRightsDialog(props))

    uRD.refs.usageSelection.getValues = -> {use_justification: "choose"}

    equal uRD.submit(), false, "returns false"

    React.unmountComponentAtNode(uRD.getDOMNode().parentNode)
