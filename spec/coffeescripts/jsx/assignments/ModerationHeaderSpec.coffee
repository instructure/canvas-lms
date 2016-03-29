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
    HeaderElement = React.createElement(Header, @props)
    header = TestUtils.renderIntoDocument(HeaderElement)
    ok header.getDOMNode(), 'the DOM node mounted'
    React.unmountComponentAtNode(header.getDOMNode().parentNode)

  test 'sets buttons to disabled if published prop is true', ->
    @props.published = true
    HeaderElement = React.createElement(Header, @props)
    header = TestUtils.renderIntoDocument(HeaderElement)
    ok header.refs.addReviewerBtn.getDOMNode().disabled == true, 'add reviewers button is disabled'
    ok header.refs.publishBtn.getDOMNode().disabled == true, 'publish button is disabled'
    React.unmountComponentAtNode(header.getDOMNode().parentNode)

  test 'calls onReviewClick prop when review button is clicked', ->
    called = false
    @props.onReviewClick = ->
      called = true
      return
    HeaderElement = React.createElement(Header, @props)
    header = TestUtils.renderIntoDocument(HeaderElement)
    TestUtils.Simulate.click(header.refs.addReviewerBtn.getDOMNode())
    ok called, 'onReviewClick was called'

  test 'show information message when published', ->
    @props.published = true
    HeaderElement = React.createElement(Header, @props)
    header = TestUtils.renderIntoDocument(HeaderElement)
    message = TestUtils.findRenderedDOMComponentWithClass(header, 'ic-notification')
    ok message, 'found the flash messge'
    React.unmountComponentAtNode(header.getDOMNode().parentNode)
