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

import React, { Component } from 'react'
import PropTypes from 'prop-types'
import tz from 'timezone'
import _ from 'underscore'
import $ from 'jquery'
import 'jquery.instructure_date_and_time'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'

class FriendlyDatetime extends Component {
  static propTypes = {
    dateTime: PropTypes.oneOfType([
      PropTypes.string,
      PropTypes.instanceOf(Date)
    ]).isRequired,
    format: PropTypes.string,
    prefix: PropTypes.string,
    showTime: PropTypes.bool
  }

  static defaultProps = {
    format: null,
    prefix: "",
    showTime: false
  }

  // The original render function is really slow because of all
  // tz.parse, $.fudge, $.datetimeString, etc.
  // As long as @props.datetime stays same, we don't have to recompute our output.
  // memoizing like this beat React.addons.PureRenderMixin 3x
  render = _.memoize(() => {
    // Separate props not used by the `time` element
    const {showTime, ...timeElementProps} = this.props

    let datetime = this.props.dateTime
    if (!datetime) {
      return (<time />)
    }
    if (!_.isDate(datetime)) {
      datetime = tz.parse(datetime)
    }
    const fudged = $.fudgeDateForProfileTimezone(datetime)
    let friendly
    if (this.props.format) {
      friendly = tz.format(datetime, this.props.format)
    } else if (showTime) {
      friendly = $.datetimeString(datetime)
    } else {
      friendly = $.friendlyDatetime(fudged)
    }

    const timeProps = Object.assign({}, timeElementProps, {
      title: $.datetimeString(datetime),
      dateTime: datetime.toISOString(),
    })

    let fixedPrefix = this.props.prefix
    if (fixedPrefix && !fixedPrefix.endsWith(' ')) {
      fixedPrefix += ' '
    }

    return (
      <span>
        <ScreenReaderContent>
          {fixedPrefix + friendly}
        </ScreenReaderContent>

        <time {...timeProps} ref={(c) => { this.time = c }} aria-hidden="true">
          <span className="visible-desktop">
            {/* something like: Mar 6, 2014 */}
            {fixedPrefix + friendly}
          </span>
          <span className="hidden-desktop">
            {/* something like: 3/3/2014 */}
            {fudged.toLocaleDateString()}
          </span>
        </time>
      </span>
    )
  }, () => this.props.dateTime)
}

export default FriendlyDatetime
