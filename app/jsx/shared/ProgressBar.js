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
import classnames from 'classnames'

export default function ProgressBar(props) {
  const barClasses = classnames({
    'progress-bar__bar': true,
    'almost-done': props.progress === 100
  })

  const containerClasses = classnames({
    'progress-bar__bar-container': true,
    'almost-done': props.progress === 100
  })

  return (
    <div className={containerClasses}>
      <div
        className={barClasses}
        role="progressbar"
        aria-valuenow={props.progress}
        aria-valuemin="0"
        aria-valuemax="100"
        aria-label={props['aria-label'] || ''}
        style={{
          width: `${Math.min(props.progress, 100)}%`
        }}
      />
    </div>
  )
}
