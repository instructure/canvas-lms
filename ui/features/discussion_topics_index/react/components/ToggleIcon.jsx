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

import PropTypes from 'prop-types'
import React from 'react'

export default function ToggleIcon({
  toggled,
  OnIcon,
  OffIcon,
  onToggleOn,
  onToggleOff,
  disabled,
  className,
}) {
  return (
    <span className={className}>
      <button
        type="button"
        className={disabled ? 'disabled-toggle-button' : 'toggle-button'}
        disabled={disabled}
        onClick={toggled ? onToggleOff : onToggleOn}
      >
        {toggled ? OnIcon : OffIcon}
      </button>
    </span>
  )
}

ToggleIcon.propTypes = {
  toggled: PropTypes.bool.isRequired,
  OnIcon: PropTypes.element.isRequired,
  OffIcon: PropTypes.element.isRequired,
  onToggleOn: PropTypes.func.isRequired,
  onToggleOff: PropTypes.func.isRequired,
  disabled: PropTypes.bool,
  className: PropTypes.string,
}

ToggleIcon.defaultProps = {
  disabled: false,
  className: '',
}
