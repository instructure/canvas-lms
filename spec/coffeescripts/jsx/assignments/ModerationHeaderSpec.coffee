define [
  'react'
  'jsx/assignments/ModerationHeader'
], (React, Header) ->

  TestUtils = React.addons.TestUtils

  module 'ModerationHeader',
    setup: ->
      @props =
        onPublishClick: ->
        onReviewClick: ->
        published: false

    teardown: ->
      @props = null

  test 'it renders', ->
    header = TestUtils.renderIntoDocument(Header(@props))
    ok header.getDOMNode(), 'the DOM node mounted'
    React.unmountComponentAtNode(header.getDOMNode().parentNode)

  test 'sets buttons to disabled if published prop is true', ->
    @props.published = true
    header = TestUtils.renderIntoDocument(Header(@props))
    ok header.refs.addReviewerBtn.getDOMNode().disabled == true, 'add reviewers button is disabled'
    ok header.refs.publishBtn.getDOMNode().disabled == true, 'publish button is disabled'
    React.unmountComponentAtNode(header.getDOMNode().parentNode)

  test 'calls onReviewClick prop when review button is clicked', ->
    called = false
    @props.onReviewClick = -> called = true
    header = TestUtils.renderIntoDocument(Header(@props))
    TestUtils.Simulate.click(header.refs.addReviewerBtn.getDOMNode())
    ok called, 'onReviewClick was called'

  test 'show information message when published', ->
    @props.published = true
    header = TestUtils.renderIntoDocument(Header(@props))
    message = TestUtils.findRenderedDOMComponentWithClass(header, 'ic-notification')
    ok message, 'found the flash messge'
    React.unmountComponentAtNode(header.getDOMNode().parentNode)

