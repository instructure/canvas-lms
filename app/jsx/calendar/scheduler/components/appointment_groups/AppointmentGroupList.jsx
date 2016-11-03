define([
  'react',
  'i18n!appointment_groups',
  'jsx/shared/FriendlyDatetime',
  'jquery',
  'jquery.instructure_date_and_time'
], (React, I18n, FriendlyDatetime, $) => {

  class AppointmentGroupList extends React.Component {

    static propTypes = {
      appointmentGroup: React.PropTypes.object,
    }

    renderEvent () {
      if (this.props.appointmentGroup.appointments_count) {
        return this.props.appointmentGroup.appointments.map((c, index) => {
          if (!c.reserved) {
            if (c.child_events.length) {
              const names = this.props.appointmentGroup.appointments[0].child_events.map((child_event) => child_event.user.sortable_name)
              const sorted = names.sort((a, b) => natcompare.strings(a, b))
              sorted.push(I18n.t('Available'))
              return (
                <div key={c.id} className='AppointmentGroupList__Appointment'>
                  <div className='AppointmentGroupList__unreserved'>
                    <i className="icon-calendar-month"></i>
                    {I18n.t('%{start_time} to %{end_time}', {start_time: $.timeString(c.start_at), end_time: $.timeString(c.end_at)})} - {sorted.join('; ')}
                  </div>
                </div>
              )
            } else {
              return (
                <div key={c.id} className='AppointmentGroupList__Appointment'>
                  <div className='AppointmentGroupList__unreserved'>
                    <i className="icon-calendar-month"></i>
                    {I18n.t('%{start_time} to %{end_time}', {start_time: $.timeString(c.start_at), end_time: $.timeString(c.end_at)})} - {I18n.t('Available')}
                  </div>
                </div>
              )
            }
          } else {
            return (
              <div key={c.id} className='AppointmentGroupList__Appointment'>
                <div className='AppointmentGroupList__reserved'>
                  <i className="icon-calendar-month"></i>
                  {I18n.t('%{start_time} to %{end_time}', {start_time: $.timeString(c.start_at), end_time: $.timeString(c.end_at)})}
                </div>
              </div>
            )
          }
        })
      }
    }

    render () {
      return (
        <div className='AppointmentGroupList__List'>
          {this.renderEvent()}
        </div>
      )
    }
  }

  return AppointmentGroupList
})
