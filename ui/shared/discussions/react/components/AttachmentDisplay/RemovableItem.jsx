/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import React, {useState} from 'react'
import {Responsive} from '@instructure/ui-responsive'
import {IconXSolid} from '@instructure/ui-icons'
import {IconButton} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'

export const RemovableItem = ({
  onRemove,
  screenReaderLabel,
  childrenAriaLabel,
  children,
  responsiveQuerySizes,
}) => {
  const [showRemove, setShowRemove] = useState(false)
  let blurTimeout = null
  const handleInteraction = () => {
    clearTimeout(blurTimeout)
    setShowRemove(true)
  }
  const handleExit = () => {
    blurTimeout = setTimeout(() => setShowRemove(false), 100)
  }

  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({mobile: true, desktop: true, tablet: true})}
      render={(_responsiveProps, matches) => (
        <span className="discussions-attach-item">
          <View display="inline-block">
            <View
              display="inline-block"
              onMouseEnter={handleInteraction}
              onMouseLeave={handleExit}
              onFocus={handleInteraction}
              onBlur={handleExit}
              role="button"
              aria-label={childrenAriaLabel}
              data-testid="removable-item"
            >
              {children}
            </View>
            {(showRemove || ['mobile', 'tablet'].some(device => matches.includes(device))) && (
              <div style={{display: 'inline-block', margin: '0 0.5rem'}}>
                <IconButton
                  size="small"
                  shape="circle"
                  screenReaderLabel={screenReaderLabel}
                  onClick={onRemove}
                  onMouseEnter={handleInteraction}
                  onMouseLeave={handleExit}
                  onFocus={handleInteraction}
                  onBlur={handleExit}
                  data-testid="remove-button"
                >
                  <IconXSolid />
                </IconButton>
              </div>
            )}
          </View>
        </span>
      )}
    />
  )
}

RemovableItem.propTypes = {
  /**
   * Behavior for removing the item
   */
  onRemove: PropTypes.func.isRequired,
  /**
   * Screenreader label for the remove IconButton
   */
  screenReaderLabel: PropTypes.string.isRequired,
  /**
   * Aria label for the child View
   */
  childrenAriaLabel: PropTypes.string.isRequired,
  /**
   * The item that is able to be removed
   */
  children: PropTypes.node.isRequired,
  /**
   * Used to set the responsive state
   */
  responsiveQuerySizes: PropTypes.func.isRequired,
}

export default RemovableItem
