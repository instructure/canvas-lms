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
    @component = TestUtils.renderIntoDocument(OutcomeAlignmentDeleteLink({
      has_rubric_association: true
    }))
    $html = $(@component.getDOMNode())
    ok $html.prop('tagName') == 'SPAN'

  test 'should render a link if !hasRubricAssociation', ->
    @component = TestUtils.renderIntoDocument(OutcomeAlignmentDeleteLink({
      has_rubric_association: false
    }))
    $html = $(@component.getDOMNode())
    ok $html.prop('tagName') == 'A'

