define [
  'react'
  'react-dom'
  'react-addons-test-utils'
  'jquery'
  'jsx/files/FilePreviewInfoPanel'
  'compiled/models/File'
  'compiled/react_files/utils/getFileStatus'
], (React, ReactDOM, TestUtils, $, FilePreviewInfoPanel, File, getFileStatus) ->

  QUnit.module 'File Preview Info Panel Specs',
    setup: ->
      @file = new File
              'content-type': 'text/plain'
              size: '1232'
              updated_at: new Date(1431724289)
              user: {html_url: "http://fun.com", display_name: "Jim Bob"}
              created_at: new Date(1431724289)
              name: 'some file'
              usage_rights: {legal_copyright: "copycat", license_name: 'best license ever'}

      @fPIP = React.createFactory(FilePreviewInfoPanel)
      @rendered = TestUtils.renderIntoDocument(@fPIP(displayedItem: @file, usageRightsRequiredForContext: true))

    teardown: ->
      ReactDOM.unmountComponentAtNode(@rendered.getDOMNode().parentNode)
      @file = null

  test 'displays item name', ->
    equal @rendered.refs.displayName.props.children, "some file", "rendered the display name"
  test 'displays status', ->
    equal @rendered.refs.status.props.children, "Published", "rendered the Status"
  test 'displays content type', ->
    equal @rendered.refs.contentType.props.children, "Plain text", "rendered the Kind (content-type)"
  test 'displays size', ->
    equal @rendered.refs.size.props.children, "1 KB", "rendered size"
  test 'displays date modified', ->
    equal $(this.rendered.getDOMNode()).find('#dateModified').text(), "Jan 17, 19701/17/1970", "rendered date modified"
  test 'displays date created', ->
    equal $(this.rendered.getDOMNode()).find('#dateCreated').text(), "Jan 17, 19701/17/1970", "rendered date created"
  test 'displays modifed by name with link', ->
    equal @rendered.refs.modifedBy.props.children.props.href, "http://fun.com", "make sure its a link to the correct place"
    equal @rendered.refs.modifedBy.props.children.props.children, "Jim Bob", "check that the name was inserted"
  test 'displays legal copy', ->
    equal @rendered.refs.licenseName.props.children, "best license ever", "license name"
  test 'displays license name', ->
    equal @rendered.refs.legalCopyright.props.children, "copycat", "display the copyright"
