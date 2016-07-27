require [
  'react'
  'jsx/grading/tabContainer'
], (React, TabContainer) ->
  TabContainerFactory = React.createFactory TabContainer
  mgpEnabled = ENV.MULTIPLE_GRADING_PERIODS
  React.render(
    TabContainerFactory(multipleGradingPeriodsEnabled: mgpEnabled),
    document.getElementById("react_grading_tabs")
  )
