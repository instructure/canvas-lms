define([
  'react',
  'classnames',
  'i18n!appointment_groups',
  'jsx/shared/FriendlyDatetime',
  'compiled/util/natcompare',
  'instructure-icons/react/Line/IconCalendarAddLine',
  'instructure-icons/react/Line/IconCalendarReservedLine',
  'jquery',
  'jquery.instructure_date_and_time'
], (React, classnames, I18n, FriendlyDatetime, natcompare, { default: IconCalendarAddLine }, { default: IconCalendarReservedLine }, $) => {
  const renderAppointment = (appointment, participantList = '') => {
    const timeLabel = I18n.t('%{start_date}, %{start_time} to %{end_time}', {
      start_date: $.dateString(appointment.start_at),
      start_time: $.timeString(appointment.start_at),
      end_time: $.timeString(appointment.end_at)
    })

    const isReserved = appointment.child_events && appointment.child_events.length > 0;

    const badgeClasses = classnames({
      AppointmentGroupList__Badge: true,
      'AppointmentGroupList__Badge--reserved': isReserved,
      'AppointmentGroupList__Badge--unreserved': !isReserved
    })

    const rowClasses = classnames({
      AppointmentGroupList__Appointment: true,
      'AppointmentGroupList__Appointment--reserved': isReserved,
      'AppointmentGroupList__Appointment--unreserved': !isReserved
    });

    const iconClasses = classnames({
      AppointmentGroupList__Icon: true,
      'AppointmentGroupList__Icon--reserved': isReserved,
      'AppointmentGroupList__Icon--unreserved': !isReserved
    })

    const statusText = (isReserved) ?
                       I18n.t('Reserved') :
                       I18n.t('Available')

    return (
      <div key={appointment.id} className={rowClasses}>
        <div>
          <span className={iconClasses}>
            {
              (isReserved) ? <IconCalendarReservedLine /> : <IconCalendarAddLine />
            }
          </span>
          <span className="pad-box-micro AppointmentGroupList__Appointment-timeLabel">{timeLabel}</span>
          <span className={badgeClasses}>{statusText}</span>
          <span className="pad-box-micro AppointmentGroupList__Appointment-label">{participantList}</span>
        </div>
      </div>
    )
  }

  return class AppointmentGroupList extends React.Component {
    static propTypes = {
      appointmentGroup: React.PropTypes.object,
    }

    renderAppointmentList () {
      const { appointmentGroup } = this.props
      return (appointmentGroup.appointments || []).map((appointment) => {
        let participantList = null

        if (!appointment.reserved) {
          if (appointment.child_events.length) {
            const names = appointment.child_events.map(event =>
              (event.user ? event.user.sortable_name : event.group.name)
            )
            const sorted = names.sort((a, b) => natcompare.strings(a, b))
            const maxParticipants = appointmentGroup.participants_per_appointment

            // if there's no limit or we are below the limit, show Available
            if (!maxParticipants || maxParticipants > appointment.child_events_count) {
              sorted.push(I18n.t('Available'))
            }

            participantList = sorted.join('; ')
          }
        }

        return renderAppointment(appointment, participantList)
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
