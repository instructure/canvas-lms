import React from 'react'
import ReactDOM from 'react-dom'
import EditPage from 'jsx/calendar/scheduler/components/appointment_groups/EditPage'

ReactDOM.render(
  <EditPage appointment_group_id={ENV.APPOINTMENT_GROUP_ID && ENV.APPOINTMENT_GROUP_ID.toString()} />,
  document.getElementById('content')
)
