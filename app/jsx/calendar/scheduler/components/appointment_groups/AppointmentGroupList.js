/*
 * Copyright (C) 2016 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import React from 'react'
import PropTypes from 'prop-types'
import classnames from 'classnames'
import I18n from 'i18n!appointment_groups'
import natcompare from 'compiled/util/natcompare'
import Grid, { GridRow, GridCol } from '@instructure/ui-core/lib/components/Grid'
import Text from '@instructure/ui-core/lib/components/Text'
import Pill from '@instructure/ui-core/lib/components/Pill'
import IconCalendarAddLine from 'instructure-icons/lib/Line/IconCalendarAddLine'
import IconCalendarReservedLine from 'instructure-icons/lib/Line/IconCalendarReservedLine'
import $ from 'jquery'
import 'jquery.instructure_date_and_time'

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
      <Pill
        variant="success"
        text={I18n.t('Reserved')} /> :
      <Pill
        text={I18n.t('Available')} />

    return (
      <div key={appointment.id} className={rowClasses}>
        <Grid
          hAlign="start"
          vAlign="middle"
        >
          <GridRow>
            <GridCol
              width="auto">
              <span className={iconClasses}>
                {
                  (isReserved) ? <IconCalendarReservedLine /> : <IconCalendarAddLine />
                }
              </span>
            </GridCol>
            <GridCol
              colSpacing="small"
              width={4}>
              <span className="AppointmentGroupList__Appointment-timeLabel">
                <Text>
                  {timeLabel}
                </Text>
              </span>
            </GridCol>
            <GridCol
              width="auto">
              <span className={badgeClasses}>
                {statusText}
              </span>
            </GridCol>
            <GridCol
              colSpacing="small">
              <span className="AppointmentGroupList__Appointment-label">
                <Text>
                  {participantList}
                </Text>
              </span>
            </GridCol>
          </GridRow>
        </Grid>
      </div>
    )
  }

export default class AppointmentGroupList extends React.Component {
    static propTypes = {
      appointmentGroup: PropTypes.object,
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
