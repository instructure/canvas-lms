require [
  'react-dom'
  'jsx/calendar/scheduler/components/appointment_groups/EditPage'
], (ReactDOM, EditPage) ->

  ReactDOM.render(
    React.createElement(EditPage, {appointment_group_id: ENV.APPOINTMENT_GROUP_ID}),
    document.getElementById('content')
  )
