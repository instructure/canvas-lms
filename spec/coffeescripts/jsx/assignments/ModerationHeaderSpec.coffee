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
        published: false,
        selectedStudentCount: 0,
        inflightAction: {
          review: false,
          publish: false
        }

    teardown: ->
      @props = null

  test 'it renders', ->
    HeaderElement = React.createElement(Header, @props)
    header = TestUtils.renderIntoDocument(HeaderElement)
    headerNode = React.findDOMNode(header)

    ok headerNode, 'the DOM node mounted'
    React.unmountComponentAtNode(headerNode.parentNode)

  test 'sets buttons to disabled if published prop is true', ->
    @props.published = true
    HeaderElement = React.createElement(Header, @props)
    header = TestUtils.renderIntoDocument(HeaderElement)
    headerNode = React.findDOMNode(header)
    addReviewerBtnNode = React.findDOMNode(header.refs.addReviewerBtn)
    publishBtnNode = React.findDOMNode(header.refs.publishBtn)

    ok addReviewerBtnNode.disabled, 'add reviewers button is disabled'
    ok publishBtnNode.disabled, 'publish button is disabled'
    React.unmountComponentAtNode(headerNode.parentNode)

  test 'disables Publish button if publish action is in flight', ->
    @props.inflightAction.publish = true
    HeaderElement = React.createElement(Header, @props)
    header = TestUtils.renderIntoDocument(HeaderElement)
    headerNode = React.findDOMNode(header)
    publishBtnNode = React.findDOMNode(header.refs.publishBtn)

    ok publishBtnNode.disabled, 'publish button is disabled'
    React.unmountComponentAtNode(headerNode.parentNode)

  test 'disables Add Reviewer button if selectedStudentCount is 0', ->
    HeaderElement = React.createElement(Header, @props)
    header = TestUtils.renderIntoDocument(HeaderElement)
    headerNode = React.findDOMNode(header)
    addReviewerBtnNode = React.findDOMNode(header.refs.addReviewerBtn)

    ok addReviewerBtnNode.disabled, 'add reviewers button is disabled'
    React.unmountComponentAtNode(headerNode.parentNode)

  test 'enables Add Reviewer button if selectedStudentCount > 0', ->
    @props.selectedStudentCount = 1
    HeaderElement = React.createElement(Header, @props)
    header = TestUtils.renderIntoDocument(HeaderElement)
    headerNode = React.findDOMNode(header)
    addReviewerBtnNode = React.findDOMNode(header.refs.addReviewerBtn)

    notOk addReviewerBtnNode.disabled, 'add reviewers button is disabled'
    React.unmountComponentAtNode(headerNode.parentNode)

  test 'disables Add Reviewer button if review action is in flight', ->
    @props.selectedStudentCount = 1
    @props.inflightAction.review = true
    HeaderElement = React.createElement(Header, @props)
    header = TestUtils.renderIntoDocument(HeaderElement)
    headerNode = React.findDOMNode(header)
    addReviewerBtnNode = React.findDOMNode(header.refs.addReviewerBtn)

    ok addReviewerBtnNode.disabled, 'add reviewers button is disabled'
    React.unmountComponentAtNode(headerNode.parentNode)

  test 'calls onReviewClick prop when review button is clicked', ->
    called = false
    @props.selectedStudentCount = 1 # Since the default (0) means the button will be disabled
    @props.onReviewClick = ->
      called = true
      return
    HeaderElement = React.createElement(Header, @props)
    header = TestUtils.renderIntoDocument(HeaderElement)
    addReviewerBtnNode = React.findDOMNode(header.refs.addReviewerBtn)

    TestUtils.Simulate.click(addReviewerBtnNode)
    ok called, 'onReviewClick was called'

  test 'show information message when published', ->
    @props.published = true
    HeaderElement = React.createElement(Header, @props)
    header = TestUtils.renderIntoDocument(HeaderElement)
    headerNode = React.findDOMNode(header)

    message = TestUtils.findRenderedDOMComponentWithClass(header, 'ic-notification')
    ok message, 'found the flash messge'
    React.unmountComponentAtNode(headerNode.parentNode)
