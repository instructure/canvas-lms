require [
  'react'
  'react-dom'
  'jsx/grading/tabContainer'
], (React, ReactDOM, TabContainer) ->
  TabContainerFactory = React.createFactory TabContainer
  mgpEnabled = ENV.MULTIPLE_GRADING_PERIODS
  ReactDOM.render(
    TabContainerFactory(multipleGradingPeriodsEnabled: mgpEnabled),
    document.getElementById("react_grading_tabs")
  )
