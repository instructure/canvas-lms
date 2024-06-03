/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import {parse, format as format_} from '@instructure/moment-utils'
import {isDate, memoize} from 'lodash'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {
  fudgeDateForProfileTimezone,
  friendlyDatetime,
  datetimeString,
} from '@canvas/datetime/date-functions'

type Props = {
  dateTime: string | Date | null
  format?: string
  prefix?: string
  prefixMobile?: string
  showTime?: boolean
}

class FriendlyDatetime extends Component<Props> {
  time: HTMLTimeElement | null = null

  static defaultProps = {
    format: null,
    prefix: '',
    prefixMobile: null,
    showTime: false,
  }

  // The original render function is really slow because of all
  // tz.parse, $.fudge, datetimeString, etc.
  // As long as @props.datetime stays same, we don't have to recompute our output.
  // memoizing like this beat React.addons.PureRenderMixin 3x
  render = memoize(
    () => {
      // Separate props not used by the `time` element
      const {prefixMobile, showTime, ...timeElementProps} = this.props

      let datetime = this.props.dateTime
      if (!datetime) {
        return null
      }
      if (!isDate(datetime)) {
        datetime = parse(datetime)
      }
      const fudged = fudgeDateForProfileTimezone(datetime)
      let friendly
      if (this.props.format) {
        friendly = format_(datetime, this.props.format)
      } else if (showTime) {
        friendly = datetimeString(datetime)
      } else {
        friendly = friendlyDatetime(fudged)
      }

      if (!datetime || !friendly || !fudged) {
        return null
      }

      const timeProps = {
        ...timeElementProps,
        title: datetimeString(datetime),
        dateTime: datetime.toISOString(),
      }

      let fixedPrefix = this.props.prefix
      if (fixedPrefix && !fixedPrefix.endsWith(' ')) {
        fixedPrefix += ' '
      }
      let fixedPrefixMobile = prefixMobile
      if (fixedPrefixMobile && !fixedPrefixMobile.endsWith(' ')) {
        fixedPrefixMobile += ' '
      }

      return (
        <span data-testid="friendly-date-time">
          <ScreenReaderContent>{fixedPrefix + friendly}</ScreenReaderContent>

          <time
            {...timeProps}
            ref={c => {
              this.time = c
            }}
            aria-hidden="true"
          >
            <span className="visible-desktop">
              {/* something like: Mar 6, 2014 */}
              {fixedPrefix + friendly}
            </span>
            <span className="hidden-desktop">
              {/* something like: 3/3/2014 */}
              {(fixedPrefixMobile || '') + fudged.toLocaleDateString()}
            </span>
          </time>
        </span>
      )
    },
    () => this.props.dateTime
  )
}

export default FriendlyDatetime
