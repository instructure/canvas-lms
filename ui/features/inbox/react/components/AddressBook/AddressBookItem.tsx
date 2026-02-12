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
import React, {useEffect, useMemo, useRef, useState} from 'react'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {TruncateText} from '@instructure/ui-truncate-text'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Tooltip} from '@instructure/ui-tooltip'

const I18n = createI18nScope('conversations_2')

export const AddressBookItem = ({
  // @ts-expect-error TS7031 (typescriptify)
  children,
  // @ts-expect-error TS7031 (typescriptify)
  id,
  // @ts-expect-error TS7031 (typescriptify)
  iconBefore,
  // @ts-expect-error TS7031 (typescriptify)
  iconAfter,
  // @ts-expect-error TS7031 (typescriptify)
  isKeyboardFocus,
  // @ts-expect-error TS7031 (typescriptify)
  isSelected,
  // @ts-expect-error TS7031 (typescriptify)
  hasPopup,
  // @ts-expect-error TS7031 (typescriptify)
  onSelect,
  // @ts-expect-error TS7031 (typescriptify)
  onHover,
  // @ts-expect-error TS7031 (typescriptify)
  menuRef,
  // @ts-expect-error TS7031 (typescriptify)
  observerEnrollments,
  // @ts-expect-error TS7031 (typescriptify)
  isOnObserverSubmenu,
  // @ts-expect-error TS7031 (typescriptify)
  pronouns,
}) => {
  const itemRef = useRef()
  const [observeesAreTruncated, setObserveesAreTruncated] = useState(false)

  // Scroll individual item into view when its selected or navigated towards
  useEffect(() => {
    if (isSelected && itemRef.current && menuRef && isKeyboardFocus) {
      // @ts-expect-error TS2339 (typescriptify)
      const menuItemOffsetTop = itemRef.current?.offsetTop
      const menuHeight = menuRef.current?.clientHeight
      // @ts-expect-error TS2339 (typescriptify)
      const itemHeight = itemRef.current?.clientHeight
      menuRef.current.scrollTop = menuItemOffsetTop - (menuHeight - itemHeight) / 2
    }
  }, [isKeyboardFocus, isSelected, menuRef])

  const getObservees = () => {
    return (
      observerEnrollments
        // @ts-expect-error TS7006 (typescriptify)
        .map(observerEnrollment => observerEnrollment.associatedUser.name)
        .join(', ')
    )
  }

  const getObserveesText = () => {
    return I18n.t('Observing: %{observees}', {
      observees: getObservees(),
    })
  }

  // @ts-expect-error TS7006 (typescriptify)
  const updateObserveesAreTruncated = isTruncated => {
    if (observeesAreTruncated !== isTruncated) {
      setObserveesAreTruncated(isTruncated)
    }
  }

  return useMemo(
    () => (
      <View
        as="div"
        // @ts-expect-error TS2322 (typescriptify)
        background={isSelected ? 'brand' : null}
        padding="xx-small"
        onMouseEnter={() => {
          onHover(true)
        }}
        onMouseLeave={() => {
          onHover(false)
        }}
        onMouseDown={e => {
          onSelect(e)
        }}
        elementRef={el => {
          // @ts-expect-error TS2322 (typescriptify)
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
                {/* @ts-expect-error TS2769 (typescriptify) */}
                <Text color={isSelected ? 'primary-inverse' : null}>{children}</Text>
              </TruncateText>
              {pronouns && (
                <Text weight="light" size="small">
                  {pronouns}
                </Text>
              )}
              {isOnObserverSubmenu && observerEnrollments && observerEnrollments.length > 0 && (
                <Text size="small" color={isSelected ? 'secondary-inverse' : 'secondary'}>
                  <TruncateText onUpdate={updateObserveesAreTruncated}>
                    {observeesAreTruncated ? (
                      <Tooltip
                        isShowingContent={isSelected}
                        renderTip={getObserveesText()}
                        placement="bottom"
                      >
                        {getObserveesText()}
                      </Tooltip>
                    ) : (
                      getObserveesText()
                    )}
                  </TruncateText>
                </Text>
              )}
              {isOnObserverSubmenu && observerEnrollments && observerEnrollments.length === 0 && (
                <Text size="small" color={isSelected ? 'secondary-inverse' : 'secondary'}>
                  {I18n.t('Observing: nobody')}
                </Text>
              )}
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
    [
      children,
      hasPopup,
      iconAfter,
      iconBefore,
      id,
      isSelected,
      observerEnrollments,
      isOnObserverSubmenu,
      observeesAreTruncated,
    ],
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
  /**
   * Array of observer enrollments
   */
  observerEnrollments: PropTypes.array,
  /**
   * Is the AddressBookContainer on an Observer submenu?
   */
  isOnObserverSubmenu: PropTypes.bool,
  /**
   * User pronouns to be displayed if 'Enable Personal Pronouns'
   * is enabled in Account Settings
   */
  pronouns: PropTypes.string,
}

AddressBookItem.defaultProps = {
  isOnObserverSubmenu: false,
}

export default AddressBookItem
