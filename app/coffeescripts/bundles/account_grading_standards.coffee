require [
  'react'
  'react-dom'
  'jsx/grading/AccountTabContainer'
], (React, ReactDOM, AccountTabContainer) ->
  TabContainerFactory = React.createFactory AccountTabContainer

  ReactDOM.render(
    TabContainerFactory(
      multipleGradingPeriodsEnabled: ENV.MULTIPLE_GRADING_PERIODS
      readOnly: ENV.GRADING_PERIODS_READ_ONLY
      urls:
        enrollmentTermsURL:      ENV.ENROLLMENT_TERMS_URL
        gradingPeriodsUpdateURL: ENV.GRADING_PERIODS_UPDATE_URL
        gradingPeriodSetsURL:    ENV.GRADING_PERIOD_SETS_URL
        deleteGradingPeriodURL:  ENV.DELETE_GRADING_PERIOD_URL
    ),
    document.getElementById("react_grading_tabs")
  )
