define [
  'underscore'
  'react'
  'react-dom'
  'jsx/epub_exports/CourseListItem'
], (_, React, ReactDOM, CourseListItem, I18n) ->
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
    CourseListItemElement = React.createElement(CourseListItem, @props)
    component = TestUtils.renderIntoDocument(CourseListItemElement)
    ok _.isNull(component.getDisplayState()),
      'display state should be null without epub_export'
    ReactDOM.unmountComponentAtNode(component.getDOMNode().parentNode)

    @props.course = {
      epub_export: {
        permissions: {},
        workflow_state: 'generating'
      }
    }
    CourseListItemElement = React.createElement(CourseListItem, @props)
    component = TestUtils.renderIntoDocument(CourseListItemElement)
    ok !_.isNull(component.getDisplayState()),
      'display state should not be null with epub_export'
    ok component.getDisplayState().match('Generating'), 'should include workflow_state'
    ReactDOM.unmountComponentAtNode(component.getDOMNode().parentNode)

  test 'render', ->
    CourseListItemElement = React.createElement(CourseListItem, @props)
    component = TestUtils.renderIntoDocument(CourseListItemElement)
    ok !_.isNull(component.getDOMNode()), 'should render with course'
    ReactDOM.unmountComponentAtNode(component.getDOMNode().parentNode)
