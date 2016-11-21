define([
  'react',
  'classnames',
  'i18n!appointment_groups',
  'jsx/shared/FriendlyDatetime',
  'compiled/util/natcompare',
  'jquery',
  'jquery.instructure_date_and_time'
], (React, classnames, I18n, FriendlyDatetime, natcompare, $) => {
  return class AppointmentGroupList extends React.Component {
    static propTypes = {
      appointmentGroup: React.PropTypes.object,
    }

    renderAppointment (appointment, statusLabel) {
      const timeLabel = I18n.t('%{start_time} to %{end_time}', { start_time: $.timeString(appointment.start_at), end_time: $.timeString(appointment.end_at) })
      const label = statusLabel ? `${timeLabel} - ${statusLabel}` : timeLabel

      const reservedClass = classnames({
        AppointmentGroupList__unreserved: !appointment.reserved,
        AppointmentGroupList__reserved: appointment.reserved,
      })

      return (
        <div key={appointment.id} className="AppointmentGroupList__Appointment">
          <div className={reservedClass}>
            <i className="icon-calendar-month" />
            <span className="pad-box-micro AppointmentGroupList__Appointment-label">{label}</span>
          </div>
        </div>
      )
    }

    renderAppointmentList () {
      const { appointmentGroup } = this.props
      return (appointmentGroup.appointments || []).map((appointment) => {
        let statusLabel = null

        if (!appointment.reserved) {
          if (appointment.child_events.length) {
            const names = appointment.child_events.map(event => event.user.sortable_name)
            const sorted = names.sort((a, b) => natcompare.strings(a, b))
            const maxParticipants = appointmentGroup.participants_per_appointment

            // if there's no limit or we are below the limit, show Available
            if (!maxParticipants || maxParticipants > appointment.child_events_count) {
              sorted.push(I18n.t('Available'))
            }

            statusLabel = sorted.join('; ')
          } else {
            statusLabel = I18n.t('Available')
          }
        }

        return this.renderAppointment(appointment, statusLabel)
      })
    }

    render () {
      return (
        <div className="AppointmentGroupList__List">
          {this.renderAppointmentList()}
        </div>
      )
    }
  }
})
