/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import React, {Component} from 'react'
import moment from 'moment-timezone'
import classnames from 'classnames'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {string} from 'prop-types'
import {sizeShape} from '../plannerPropTypes'
// @ts-expect-error TS2305 (typescriptify)
import {getShortDate} from '../../utilities/dateUtils'
import buildStyle from './style'
import {useScope as createI18nScope} from '@canvas/i18n'
import GroupedDates from './GroupedDates'

const I18n = createI18nScope('planner')

export default class EmptyDays extends Component {
  // @ts-expect-error TS7006 (typescriptify)
  constructor(props) {
    super(props)
    // @ts-expect-error TS2339 (typescriptify)
    this.style = buildStyle()
  }

  static propTypes = {
    day: string.isRequired,
    endday: string.isRequired,
    timeZone: string.isRequired,
    responsiveSize: sizeShape,
  }

  static defualtProps = {
    responsiveSize: 'large',
  }

  // @ts-expect-error TS7006 (typescriptify)
  renderDate = (start, end) => {
    const dateString = I18n.t('%{startDate} to %{endDate}', {
      startDate: getShortDate(start),
      endDate: getShortDate(end),
    })
    return (
      <Text as="div" lineHeight="condensed">
        {dateString}
      </Text>
    )
  }

  render = () => {
    // @ts-expect-error TS2339 (typescriptify)
    const now = moment.tz(this.props.timeZone)
    // @ts-expect-error TS2339 (typescriptify)
    const start = moment.tz(this.props.day, this.props.timeZone).startOf('day')
    // @ts-expect-error TS2339 (typescriptify)
    const end = moment.tz(this.props.endday, this.props.timeZone).endOf('day')
    const includesToday =
      (now.isSame(start, 'day') || now.isAfter(start, 'day')) &&
      (now.isSame(end, 'day') || now.isBefore(end, 'day'))
    const clazz = classnames(
      // @ts-expect-error TS2339 (typescriptify)
      this.style.classNames.root,
      // @ts-expect-error TS2339 (typescriptify)
      this.style.classNames[this.props.responsiveSize],
      'planner-empty-days',
      {'planner-today': includesToday},
    )

    return (
      <>
        {/* @ts-expect-error TS2339 (typescriptify) */}
        <style>{this.style.css}</style>
        <div className={clazz}>
          <Heading border="bottom">{this.renderDate(start, end)}</Heading>
          {/* @ts-expect-error TS2339 (typescriptify) */}
          <div className={this.style.classNames.nothingPlannedContent}>
            <GroupedDates role="img" aria-hidden="true" />
            {/* @ts-expect-error TS2339 (typescriptify) */}
            <div className={this.style.classNames.nothingPlannedContainer}>
              {/* @ts-expect-error TS2339 (typescriptify) */}
              <div className={this.style.classNames.nothingPlanned}>
                <Text size="large">{I18n.t('Nothing Planned Yet')}</Text>
              </div>
            </div>
          </div>
        </div>
      </>
    )
  }
}
