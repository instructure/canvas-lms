define [
  'jquery',
  'jsx/outcomes/OutcomeAlignmentDeleteLink',
  'react'
  'react-dom'
  'react-addons-test-utils',
], ($, OutcomeAlignmentDeleteLink, React, ReactDOM, TestUtils) ->
  module 'OutcomeAlignmentDeleteLink',
    teardown: ->
      ReactDOM.unmountComponentAtNode(@component.getDOMNode().parentNode)

  test 'should render span if hasRubricAssociation', ->
    OutcomeAlignmentDeleteLinkElement = React.createElement(OutcomeAlignmentDeleteLink, {
      has_rubric_association: true
    })
    @component = TestUtils.renderIntoDocument(OutcomeAlignmentDeleteLinkElement)
    $html = $(@component.getDOMNode())
    ok $html.prop('tagName') == 'SPAN'

  test 'should render a link if !hasRubricAssociation', ->
    OutcomeAlignmentDeleteLinkElement = React.createElement(OutcomeAlignmentDeleteLink, {
      has_rubric_association: false
    })
    @component = TestUtils.renderIntoDocument(OutcomeAlignmentDeleteLinkElement)
    $html = $(@component.getDOMNode())
    ok $html.prop('tagName') == 'A'

