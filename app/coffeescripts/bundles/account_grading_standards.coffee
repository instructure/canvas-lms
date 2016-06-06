require [
  'react'
  'jsx/grading/AccountTabContainer'
], (React, AccountTabContainer) ->
  TabContainerFactory = React.createFactory AccountTabContainer
  mgpEnabled = ENV.MULTIPLE_GRADING_PERIODS
  readOnly =   ENV.GRADING_PERIODS_READ_ONLY
  urls =
    gradingPeriodSetsURL:    ENV.GRADING_PERIOD_SETS_URL
    gradingPeriodsUpdateURL: ENV.GRADING_PERIODS_UPDATE_URL
    deleteGradingPeriodURL:  ENV.DELETE_GRADING_PERIOD_URL
    enrollmentTermsURL:      ENV.ENROLLMENT_TERMS_URL

  React.render(
    TabContainerFactory(
      multipleGradingPeriodsEnabled: mgpEnabled
      readOnly: readOnly
      urls: urls
    ),
    document.getElementById("react_grading_tabs")
  )
