define [
  'underscore',
  'react',
  'jsx/epub_exports/CourseListItem'
], (_, React, CourseListItem, I18n) ->
  TestUtils = React.addons.TestUtils

  module 'CourseListItemSpec',
    setup: ->
      @props = {
        course: {
          name: 'Maths 101',
          id: 1
        }
      }

  test 'getDisplayState', ->
    component = TestUtils.renderIntoDocument(CourseListItem(@props))
    ok _.isNull(component.getDisplayState()),
      'display state should be null without epub_export'
    React.unmountComponentAtNode(component.getDOMNode().parentNode)

    @props.course = {
      epub_export: {
        permissions: {},
        workflow_state: 'generating'
      }
    }
    component = TestUtils.renderIntoDocument(CourseListItem(@props))
    ok !_.isNull(component.getDisplayState()),
      'display state should not be null with epub_export'
    ok component.getDisplayState().match('Generating'), 'should include workflow_state'
    React.unmountComponentAtNode(component.getDOMNode().parentNode)

  test 'render', ->
    component = TestUtils.renderIntoDocument(CourseListItem(@props))
    ok !_.isNull(component.getDOMNode()), 'should render with course'
    React.unmountComponentAtNode(component.getDOMNode().parentNode)
