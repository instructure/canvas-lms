define [
  'underscore',
  'react',
  'react-dom',
  'react-addons-test-utils'
  'jsx/epub_exports/CourseList'
], (_, React, ReactDOM, TestUtils, CourseList, I18n) ->

  module 'CourseListSpec',
    setup: ->
      @props = {
        1: {
          name: 'Maths 101',
          id: 1
        },
        2: {
          name: 'Physics 101',
          id: 2
        }
      }

  test 'render', ->
    CourseListElement = React.createElement(CourseList, courses: {})
    component = TestUtils.renderIntoDocument(CourseListElement)
    node = component.getDOMNode()
    equal node.querySelectorAll('li').length, 0, 'should not render list items'
    ReactDOM.unmountComponentAtNode(node.parentNode)

    CourseListElement = React.createElement(CourseList, courses: @props)
    component = TestUtils.renderIntoDocument(CourseListElement)
    node = component.getDOMNode()
    equal node.querySelectorAll('li').length, Object.keys(@props).length,
      'should have an li element per course in @props'

    ReactDOM.unmountComponentAtNode(node.parentNode)
