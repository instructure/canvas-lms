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

import PropTypes from 'prop-types'
import React from 'react'

export function Highlight({...props}) {
  const attrs = {}
  const highlightTestId = {}

  attrs.paddingBottom = '0.125rem'
  if (props.isHighlighted) {
    attrs.backgroundColor = 'rgba(0, 142, 226, 0.1)'
    highlightTestId['data-testid'] = 'isHighlighted'
  }

  return (
    <div style={{...attrs}} {...highlightTestId}>
      {props.children}
    </div>
  )
}

Highlight.propTypes = {
  /**
   * Boolean to define if the Highlight is highlighted.
   */
  isHighlighted: PropTypes.bool,
  children: PropTypes.node
}

Highlight.defaultProps = {
  isHighlighted: false
}

export default Highlight
