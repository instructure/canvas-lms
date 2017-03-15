require [
  'react'
  'react-dom'
  'jsx/calendar/scheduler/components/appointment_groups/EditPage'
], (React, ReactDOM, EditPage) ->

  ReactDOM.render(
    React.createElement(EditPage, {appointment_group_id: ENV.APPOINTMENT_GROUP_ID && ENV.APPOINTMENT_GROUP_ID.toString() }),
    document.getElementById('content')
  )
