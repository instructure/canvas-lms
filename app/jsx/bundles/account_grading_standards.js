import React from 'react'
import ReactDOM from 'react-dom'
import AccountTabContainer from 'jsx/grading/AccountTabContainer'

ReactDOM.render(
  <AccountTabContainer
    {...{
      readOnly: ENV.GRADING_PERIODS_READ_ONLY,
      urls: {
        enrollmentTermsURL: ENV.ENROLLMENT_TERMS_URL,
        gradingPeriodsUpdateURL: ENV.GRADING_PERIODS_UPDATE_URL,
        gradingPeriodSetsURL: ENV.GRADING_PERIOD_SETS_URL,
        deleteGradingPeriodURL: ENV.DELETE_GRADING_PERIOD_URL
      }
    }}
  />,
  document.getElementById('react_grading_tabs')
)
