require [
  'react-dom'
  'jsx/calendar/scheduler/components/appointment_groups/EditPage'
], (ReactDOM, EditPage) ->

  ReactDOM.render(
    React.createElement(EditPage, {appointment_group: ENV.APPOINTMENT_GROUP.appointment_group}),
    document.getElementById('content')
  )
