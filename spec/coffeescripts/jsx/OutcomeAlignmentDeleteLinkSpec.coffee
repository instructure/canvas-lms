define [
  'jquery',
  'jsx/outcomes/OutcomeAlignmentDeleteLink',
  'react'
], ($, OutcomeAlignmentDeleteLink, React) ->
  module 'OutcomeAlignmentDeleteLink',
    TestUtils = React.addons.TestUtils
    teardown: ->
      React.unmountComponentAtNode(@component.getDOMNode().parentNode)

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

