require [
  'react'
  'react-dom'
  'jsx/grading/CourseTabContainer'
], (React, ReactDOM, CourseTabContainer) ->
  CourseTabContainerFactory = React.createFactory CourseTabContainer
  ReactDOM.render(
    CourseTabContainerFactory(hasGradingPeriods: ENV.HAS_GRADING_PERIODS),
    document.getElementById("react_grading_tabs")
  )
