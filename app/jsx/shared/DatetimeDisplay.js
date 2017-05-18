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
import tz from 'timezone'
  class DatetimeDisplay extends React.Component {
    render () {
      let datetime = this.props.datetime instanceof Date ? this.props.datetime.toString() : this.props.datetime
      return (
        <span className='DatetimeDisplay'>
          {tz.format(datetime, this.props.format)}
        </span>
      );
    }
  };

  DatetimeDisplay.propTypes = {
    datetime: PropTypes.oneOfType([
      PropTypes.string,
      PropTypes.instanceOf(Date)
    ]),
    format: PropTypes.string
  };

  DatetimeDisplay.defaultProps = {
    format: '%c'
  };

export default DatetimeDisplay
