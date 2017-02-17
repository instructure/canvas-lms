define [
  'react'
  'react-dom'
  'react-addons-test-utils'
  'underscore'
  'jsx/dashboard_card/DashboardCardBox'
  'jsx/dashboard_card/CourseActivitySummaryStore'
], (React, ReactDOM, TestUtils, _, DashboardCardBox, CourseActivitySummaryStore) ->

  QUnit.module 'DashboardCardBox',
    setup: ->
      @stub(CourseActivitySummaryStore, 'getStateForCourse').returns({})
      @courseCards = [{
        id: 1,
        shortName: 'Bio 101'
      }, {
        id: 2,
        shortName: 'Philosophy 201'
      }]

    teardown: ->
      localStorage.clear()
      if @component
        ReactDOM.unmountComponentAtNode(@component.getDOMNode().parentNode)

  test 'should render div.ic-DashboardCard per provided courseCard', ->
    CardBox = React.createElement(DashboardCardBox, {
      courseCards: @courseCards
    })
    @component = TestUtils.renderIntoDocument(CardBox)
    $html = $(@component.getDOMNode())
    equal $html.children('div.ic-DashboardCard').length, @courseCards.length
