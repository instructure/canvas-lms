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

import classNames from 'classnames'
import PropTypes from 'prop-types'
import React, {useLayoutEffect, useRef} from 'react'
import theme from '@instructure/canvas-theme'

export function Highlight({...props}) {
  const highlightRef = useRef()

  useLayoutEffect(() => {
    if (props.isHighlighted && highlightRef.current) {
      setTimeout(() => {
        highlightRef.current?.scrollIntoView({behavior: 'smooth', block: 'center'})
        highlightRef.current?.querySelector('button').focus({preventScroll: true})
      }, 0)
    }
  }, [props.isHighlighted, highlightRef])

  return (
    <div
      style={{
        borderRadius: theme.variables.borders.radiusLarge,
      }}
      className={classNames({'highlight-fadeout': props.isHighlighted})}
      data-testid={props.isHighlighted ? 'isHighlighted' : 'notHighlighted'}
      ref={highlightRef}
    >
      {props.children}
    </div>
  )
}

Highlight.propTypes = {
  /**
   * Boolean to define if the Highlight is highlighted.
   */
  isHighlighted: PropTypes.bool,
  children: PropTypes.node,
}

Highlight.defaultProps = {
  isHighlighted: false,
}

export default Highlight
