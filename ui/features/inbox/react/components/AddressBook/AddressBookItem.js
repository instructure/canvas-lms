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
import React, {useEffect, useMemo, useRef} from 'react'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {TruncateText} from '@instructure/ui-truncate-text'
import {Text} from '@instructure/ui-text'

export const AddressBookItem = ({
  children,
  id,
  iconBefore,
  iconAfter,
  isKeyboardFocus,
  isSelected,
  hasPopup,
  onSelect,
  onHover,
  menuRef,
}) => {
  const itemRef = useRef()

  // Scroll individual item into view when its selected or navigated towards
  useEffect(() => {
    if (isSelected && itemRef.current && menuRef && isKeyboardFocus) {
      const menuItemOffsetTop = itemRef.current?.offsetTop
      const menuHeight = menuRef.current?.clientHeight
      const itemHeight = itemRef.current?.clientHeight
      menuRef.current.scrollTop = menuItemOffsetTop - (menuHeight - itemHeight) / 2
    }
  }, [isKeyboardFocus, isSelected, menuRef])

  return useMemo(
    () => (
      <View
        as="div"
        background={isSelected ? 'brand' : null}
        padding="xx-small"
        onMouseEnter={() => {
          onHover(true)
        }}
        onMouseLeave={() => {
          onHover(false)
        }}
        onMouseDown={() => {
          onSelect()
        }}
        elementRef={el => {
          itemRef.current = el
        }}
        data-testid="address-book-item"
      >
        <li
          role="menuitem"
          id={id}
          style={{listStyle: 'none'}}
          aria-haspopup={hasPopup}
          data-selected={isSelected}
        >
          <Flex as="div" width="100%" margin="xxx-small none xxx-small xxx-small">
            {iconBefore && (
              <Flex.Item align="start" margin="0 small 0 0">
                {iconBefore}
              </Flex.Item>
            )}
            <Flex.Item align="center" shouldGrow={true} shouldShrink={true}>
              <TruncateText>
                <Text color={isSelected ? 'primary-inverse' : null}>{children}</Text>
              </TruncateText>
            </Flex.Item>
            {iconAfter && (
              <Flex.Item align="center" margin="0 0 0 small">
                {iconAfter}
              </Flex.Item>
            )}
          </Flex>
        </li>
      </View>
    ),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [children, hasPopup, iconAfter, iconBefore, id, isSelected]
  )
}

AddressBookItem.propTypes = {
  /**
   * Child text to be displayed in MenuItem
   */
  children: PropTypes.node,
  /**
   * String used for ID required for a11y
   */
  id: PropTypes.string.isRequired,
  /**
   * Node to be the icon rendered before the item
   */
  iconBefore: PropTypes.node,
  /**
   * Node to be the icon rendered after the item
   */
  iconAfter: PropTypes.node,
  /**
   * Bool to describe if item is selected
   */
  isSelected: PropTypes.bool,
  /**
   * Bool for popup a11y aria markup
   */
  hasPopup: PropTypes.bool,
  /**
   * Function to be returned on click
   */
  onSelect: PropTypes.func,
  /**
   * Function to execute on item hover
   */
  onHover: PropTypes.func,
  /**
   * Menu Ref is needed to scroll menu correctly
   */
  menuRef: PropTypes.object,
  /**
   * Boolean to determine if keyboard or mouse navigation is occuring
   */
  isKeyboardFocus: PropTypes.bool,
}

export default AddressBookItem
