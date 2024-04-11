// @ts-nocheck
/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import moment from 'moment-timezone'
import {IconButton} from '@instructure/ui-buttons'
import {IconTrashLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Table} from '@instructure/ui-table'
import {useScope as useI18nScope} from '@canvas/i18n'
import {BlackoutDate} from '../types'
import {coursePaceDateFormatter} from '../api/backend_serializer'

const I18n = useI18nScope('course_paces_blackout_dates_table')

/* React Components */

interface PassedProps {
  readonly blackoutDates: BlackoutDate[]
  readonly deleteBlackoutDate: (blackoutDate: BlackoutDate) => any
  readonly displayType: 'admin' | 'course'
}

type ComponentProps = PassedProps

interface LocalState {}

export class BlackoutDatesTable extends React.Component<ComponentProps, LocalState> {
  private dateFormatter: any

  /* Lifecycle */

  constructor(props: ComponentProps) {
    super(props)
    this.state = {}
    this.dateFormatter = coursePaceDateFormatter()
  }

  /* Helpers */

  sortBlackoutDates = (dates: BlackoutDate[]): BlackoutDate[] => {
    return dates.sort((a, b) => {
      const aStart = moment(a.start_date)
      const bStart = moment(b.start_date)
      const diff = aStart.diff(bStart, 'days')
      if (diff > 0) {
        return 1
      } else if (diff < 0) {
        return -1
      } else {
        return 0
      }
    })
  }

  sortedBlackoutDates = (): BlackoutDate[] => {
    if (this.props.displayType === 'course') {
      const adminDates = this.props.blackoutDates.filter(blackoutDate => blackoutDate.admin_level)
      const courseDates = this.props.blackoutDates.filter(blackoutDate => !blackoutDate.admin_level)
      return this.sortBlackoutDates(adminDates).concat(this.sortBlackoutDates(courseDates))
    } else {
      return this.sortBlackoutDates(this.props.blackoutDates)
    }
  }

  /* Renderers */

  renderRows = () => {
    const dates = this.sortedBlackoutDates()
    if (dates.length === 0) {
      return (
        <Table.Row key="blackout-date-empty">
          <Table.Cell colSpan={4} textAlign="center">
            {I18n.t('No blackout dates')}
          </Table.Cell>
        </Table.Row>
      )
    }
    return dates.map(bd => (
      <Table.Row key={`blackout-date-${bd.id || bd.temp_id}`}>
        <Table.Cell>
          <div style={{overflowWrap: 'break-word'}}>{bd.event_title}</div>
        </Table.Cell>
        <Table.Cell>{this.dateFormatter(bd.start_date.toDate())}</Table.Cell>
        <Table.Cell>{this.dateFormatter(bd.end_date.toDate())}</Table.Cell>
        <Table.Cell textAlign="end">{this.renderTrash(bd)}</Table.Cell>
      </Table.Row>
    ))
  }

  renderTrash = (blackoutDate: BlackoutDate) => {
    if (this.props.displayType === 'course' && blackoutDate.admin_level) {
      return null
    } else {
      return (
        <IconButton
          onClick={() => this.props.deleteBlackoutDate(blackoutDate)}
          screenReaderLabel={`Delete blackout date ${blackoutDate.event_title}`}
        >
          <IconTrashLine />
        </IconButton>
      )
    }
  }

  render() {
    return (
      <Table caption="Blackout Dates" layout="fixed" data-testid="blackout_dates_table">
        <Table.Head>
          <Table.Row>
            <Table.ColHeader id="blackout-dates-title">{I18n.t('Event Title')}</Table.ColHeader>
            <Table.ColHeader id="blackout-dates-start-date">{I18n.t('Start Date')}</Table.ColHeader>
            <Table.ColHeader id="blackout-dates-end-date">{I18n.t('End Date')}</Table.ColHeader>

            <Table.ColHeader id="blackout-dates-actions" width="4rem">
              <ScreenReaderContent>{I18n.t('Actions')}</ScreenReaderContent>
            </Table.ColHeader>
          </Table.Row>
        </Table.Head>
        <Table.Body>{this.renderRows()}</Table.Body>
      </Table>
    )
  }
}

export default BlackoutDatesTable
