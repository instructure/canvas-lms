require [
  'react'
  'jsx/grading/AccountTabContainer'
], (React, AccountTabContainer) ->
  TabContainerFactory = React.createFactory AccountTabContainer
  mgpEnabled = ENV.MULTIPLE_GRADING_PERIODS
  urls =
    gradingPeriodSetsURL: ENV.GRADING_PERIOD_SETS_URL

  React.render(
    TabContainerFactory(multipleGradingPeriodsEnabled: mgpEnabled, URLs: urls),
    document.getElementById("react_grading_tabs")
  )
