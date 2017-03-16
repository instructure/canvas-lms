import React from 'react'
import ReactDOM from 'react-dom'
import CourseTabContainer from 'jsx/grading/CourseTabContainer'

ReactDOM.render(
  <CourseTabContainer hasGradingPeriods={ENV.HAS_GRADING_PERIODS} />,
  document.getElementById('react_grading_tabs')
)
