import $ from 'jquery'
import React from 'react'
import ReactDOM from 'react-dom'
import CSAlerts from 'jsx/cs_alerts/CSAlerts'
import axios from 'axios'

const $el = document.getElementById('cs-alerts-container')
let alerts = []

axios.get("/cs_alerts/teacher_alerts").then((response) => {
  $(".dot-overlay").addClass("hidden");

  alerts = response.data
  ReactDOM.render(
    <CSAlerts
      alerts={alerts}
    />,
    $el
  )
})
