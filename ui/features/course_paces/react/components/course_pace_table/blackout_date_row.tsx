/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {useScope as useI18nScope} from '@canvas/i18n'
import {pick} from 'lodash'

import {ApplyTheme} from '@instructure/ui-themeable'
import {Flex} from '@instructure/ui-flex'
import {Table} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

import {BlackoutDate} from '../../shared/types'
import {coursePaceDateFormatter} from '../../shared/api/backend_serializer'

// until the icon gets into INSTUI
// @ts-ignore
import blackoutDatesIcon from '../../utils/blackout-dates-lined.svg'

const I18n = useI18nScope('course_paces_blackout_date_row')

const {Cell, Row} = Table as any

interface PassedProps {
  readonly blackoutDate: BlackoutDate
  readonly isStacked?: boolean
}
interface LocalState {}

class BlackoutDateRow extends React.Component<PassedProps, LocalState> {
  static displayName = 'Row'

  private dateFormatter: any

  constructor(props: PassedProps) {
    super(props)
    this.dateFormatter = coursePaceDateFormatter()
  }

  renderIcon() {
    // width, height, and color copied from assignment_row.tsx
    return <img src={blackoutDatesIcon} width="20px" height="20px" color="#75808B" alt="" />
  }

  renderTitle() {
    return (
      <Flex alignItems="center">
        <View margin="0 x-small 0 0" aria-hidden="true">
          {this.renderIcon()}
        </View>
        <div>
          <Text weight="bold">
            <span style={{overflowWrap: 'anywhere'}}>{this.props.blackoutDate.event_title}</span>
          </Text>
          <div className="course-paces-assignment-row-points-possible">
            <Text size="x-small">{I18n.t('Blackout Date')}</Text>
          </div>
        </div>
      </Flex>
    )
  }

  renderDates() {
    const whiteSpace = this.props.isStacked ? 'normal' : 'nowrap'
    return (
      <>
        <span style={{whiteSpace}}>{this.dateFormatter(this.props.blackoutDate.start_date)}</span>
        {!this.props.blackoutDate.start_date.isSame(this.props.blackoutDate.end_date) && (
          <>
            {' - '}
            <span style={{whiteSpace: 'nowrap'}}>
              {this.dateFormatter(this.props.blackoutDate.end_date)}
            </span>
          </>
        )}
      </>
    )
  }

  duration() {
    return this.props.blackoutDate.end_date.diff(this.props.blackoutDate.start_date, 'days') + 1
  }

  render() {
    const labelMargin = this.props.isStacked ? '0 0 0 small' : undefined
    const themeOverrides = {background: '#F5F5F5'}
    return (
      <ApplyTheme theme={{[Cell.theme]: themeOverrides}}>
        <Row
          data-testid="pp-blackout-date-row"
          {...pick(this.props, ['hover', 'isStacked', 'headers'])}
        >
          <Cell>
            <View margin={labelMargin}>{this.renderTitle()}</View>
          </Cell>
          <Cell textAlign="center">{this.duration()}</Cell>
          <Cell colSpan={this.props.isStacked ? 2 : 1} textAlign="center">
            <View margin={labelMargin}>{this.renderDates()}</View>
          </Cell>
          {!this.props.isStacked && <Cell />}
        </Row>
      </ApplyTheme>
    )
  }
}
export default BlackoutDateRow
