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

import React, {useState} from 'react'
import PropTypes from 'prop-types'

export default function VisualOnFocusMessage({message}) {
  const [focused, setFocused] = useState(false)

  return (
    <div className="accessibility_warning">
      <span
        className={focused ? '' : 'screenreader-only'}
        tabIndex="0" // eslint-disable-line jsx-a11y/no-noninteractive-tabindex
        onFocus={() => setFocused(true)}
        onBlur={() => setFocused(false)}
        data-testid="visual-onfocus-message"
      >
        {message}
      </span>
    </div>
  )
}

VisualOnFocusMessage.propTypes = {
  message: PropTypes.string,
}
