define [
  'react'
  'underscore'
  'jsx/dashboard_card/DashboardCardBox'
  'jsx/dashboard_card/CourseActivitySummaryStore'
], (React, _, DashboardCardBox, CourseActivitySummaryStore) ->

  TestUtils = React.addons.TestUtils

  module 'DashboardCardBox',
    setup: ->
      @stub(CourseActivitySummaryStore, 'getStateForCourse', -> {})
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
        React.unmountComponentAtNode(@component.getDOMNode().parentNode)

  test 'should render div.card per provided courseCard', ->
    @component = TestUtils.renderIntoDocument(DashboardCardBox({
      courseCards: @courseCards
    }))
    $html = $(@component.getDOMNode())
    ok $html.attr('class').match(/Box/)
    equal $html.children('div.card').length, @courseCards.length
