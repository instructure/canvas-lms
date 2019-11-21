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
import I18n from 'i18n!react_collaborations'

class Spinner extends React.Component {
  render() {
    return (
      <div className="LoadingSpinner LoadingSpinner-medium LoadingSpinner-lightBg">
        <svg className="circle" role="img" aria-labelledby="LoadingSpinner">
          <title id="LoadingSpinner">{I18n.t('Loading collaborations')}</title>
          <g role="presentation">
            <circle className="circleShadow" cx="50%" cy="50%" r="1.75em" />
            <circle className="circleTrack" cx="50%" cy="50%" r="1.75em" />
            <circle className="circleSpin" cx="50%" cy="50%" r="1.75em" />
          </g>
        </svg>
      </div>
    )
  }
}

export default Spinner
