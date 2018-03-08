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

import React from 'react'
import I18n from 'i18n!react_files'
import classnames from 'classnames'

var ProgressBar = React.createClass({
  render() {
    var barClasses = classnames({
      'progress-bar__bar': true,
      'almost-done': this.props.progress === 100
    })

    var containerClasses = classnames({
      'progress-bar__bar-container': true,
      'almost-done': this.props.progress === 100
    })

    return (
      <div ref="container" className={containerClasses}>
        <div
          ref="bar"
          className={barClasses}
          role="progressbar"
          aria-valuenow={this.props.progress}
          aria-valuemin="0"
          aria-valuemax="100"
          aria-label={this.props['aria-label'] || ''}
          style={{
            width: Math.min(this.props.progress, 100) + '%'
          }}
        />
      </div>
    )
  }
})

export default ProgressBar
