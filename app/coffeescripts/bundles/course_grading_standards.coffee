require [
  'react'
  'react-dom'
  'jsx/grading/CourseTabContainer'
], (React, ReactDOM, CourseTabContainer) ->
  CourseTabContainerFactory = React.createFactory CourseTabContainer
  mgpEnabled = ENV.MULTIPLE_GRADING_PERIODS
  ReactDOM.render(
    CourseTabContainerFactory(multipleGradingPeriodsEnabled: mgpEnabled),
    document.getElementById("react_grading_tabs")
  )
