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
import React, {useMemo, useRef, useState} from 'react'
import MentionDropdownOption from './MentionDropdownOption'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {usePopper} from 'react-popper'
import {ARIA_ID_TEMPLATES} from '../../constants'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('mentions')

const MentionDropdownMenu = ({
  onSelect,
  onMouseEnter,
  mentionOptions,
  coordiantes,
  selectedUser,
  instanceId,
  highlightMouse,
  onOptionMouseEnter,
  isInteractive,
  isLoading,
  hasNextPage,
  onLoadMore,
}) => {
  // Hooks & Variables
  const directionality = tinyMCE?.activeEditor?.getParam('directionality')
  const menuRef = useRef(null)

  // Setup Popper
  const virtualReference = useMemo(() => {
    return {
      getBoundingClientRect: () => {
        return coordiantes
      },
    }
  }, [coordiantes])
  const [popperElement, setPopperElement] = useState(null)
  const {styles, attributes} = usePopper(virtualReference, popperElement, {
    placement: directionality === 'rtl' ? 'bottom-end' : 'bottom-start',
    modifiers: [
      {
        name: 'flip',
        options: {
          flipVariations: false,
          fallbackPlacements: ['bottom', 'bottom-end', 'bottom-start'],
        },
      },
    ],
  })

  // Memoize map of Mention Options (excluding Load More marker)
  const menuItems = useMemo(() => {
    return mentionOptions
      .filter(user => !user.isLoadMore)
      .map(user => {
        return (
          <MentionDropdownOption
            name={user.shortName || user.name}
            onSelect={() => {
              onSelect({
                ...user,
                elementId: ARIA_ID_TEMPLATES.activeDescendant(instanceId, user.id),
              })
            }}
            isSelected={selectedUser === user.id}
            key={user.id}
            id={ARIA_ID_TEMPLATES.activeDescendant(instanceId, user.id)}
            highlightMouse={highlightMouse}
            onOptionMouseEnter={() => {
              onOptionMouseEnter(user)
            }}
            menuRef={menuRef}
            isInteractive={isInteractive}
          />
        )
      })
  }, [
    mentionOptions,
    selectedUser,
    instanceId,
    highlightMouse,
    isInteractive,
    onSelect,
    onOptionMouseEnter,
  ])

  // Create screen reader announcement for result count
  const resultCountMessage = useMemo(() => {
    const count = mentionOptions.length
    if (count === 0 && !isLoading) return null
    if (isLoading && count === 0) return I18n.t('Loading mentionable users')
    if (hasNextPage) {
      // Note: The 'one' case is an edge case and unlikely to occur when hasNextPage is true,
      // but we handle it for consistency with proper pluralization
      return I18n.t(
        {
          one: 'Showing first 1 user. Press down arrow to load more.',
          other: 'Showing first %{count} users. Press down arrow to load more.',
        },
        {count},
      )
    }
    return I18n.t({one: '1 user available', other: '%{count} users available'}, {count})
  }, [mentionOptions.length, isLoading, hasNextPage])

  // Don't show if menu is empty and not loading
  if (mentionOptions?.length === 0 && !isLoading) {
    return null
  }

  return (
    <div
      className="mention-dropdown-menu"
      ref={isInteractive ? setPopperElement : null}
      style={isInteractive ? {...styles.popper, zIndex: 10000} : null}
      onMouseEnter={isInteractive ? onMouseEnter : null}
      {...attributes.popper}
    >
      <View
        as="div"
        background="primary"
        borderWidth="small"
        borderRadius="medium"
        maxHeight="200px"
        maxWidth="400px"
        minWidth="320px"
        overflowY="auto"
        padding="none"
        shadow="above"
        width="auto"
        elementRef={el => {
          menuRef.current = el
        }}
      >
        {resultCountMessage && <ScreenReaderContent>{resultCountMessage}</ScreenReaderContent>}
        <ul
          aria-label="Mentionable Users"
          id={ARIA_ID_TEMPLATES.ariaControlTemplate(instanceId)}
          role="listbox"
          style={{
            paddingInlineStart: '0px',
            marginBlockStart: '0px',
            marginBlockEnd: '0px',
            margin: '0',
          }}
        >
          {menuItems}
          {isLoading && (
            <li
              style={{
                padding: '8px',
                textAlign: 'center',
                listStyle: 'none',
              }}
              role="presentation"
            >
              <Spinner renderTitle={I18n.t('Loading mentionable users')} size="x-small" />
            </li>
          )}
          {!isLoading && hasNextPage && isInteractive && (
            <View
              as="div"
              background={selectedUser === '__LOAD_MORE__' ? 'brand' : 'primary'}
              padding="xx-small"
              onMouseEnter={() => {
                onOptionMouseEnter({id: '__LOAD_MORE__', isLoadMore: true})
              }}
            >
              <li
                aria-selected={selectedUser === '__LOAD_MORE__'}
                id={`${ARIA_ID_TEMPLATES.ariaControlTemplate(instanceId)}-load-more`}
                aria-label={I18n.t('Load more users')}
                role="option"
                tabIndex={-1}
                style={{
                  listStyle: 'none',
                  textAlign: 'center',
                  cursor: 'pointer',
                }}
                onClick={onLoadMore}
                onKeyDown={e => {
                  // This handler satisfies the linter but keyboard navigation is actually
                  // handled by the parent component via message passing
                  if (e.key === 'Enter' || e.key === ' ') {
                    e.preventDefault()
                    onLoadMore()
                  }
                }}
              >
                <Text color={selectedUser === '__LOAD_MORE__' ? 'primary-inverse' : 'brand'}>
                  {I18n.t('Load More Users...')}
                </Text>
              </li>
            </View>
          )}
        </ul>
      </View>
    </div>
  )
}

export default MentionDropdownMenu

MentionDropdownMenu.proptypes = {
  /**
   * Array of optons to be presented to user
   */
  mentionOptions: PropTypes.array,
  /**
   * Unique ID supplied for ARIA support
   */
  instanceId: PropTypes.string,
  /**
   * cordinates for menu on screen
   */
  coordiantes: PropTypes.object,
  /**
   * Callback for selecting an item
   */
  onSelect: PropTypes.func,
  /**
   * ID of selected user
   */
  selectedUser: PropTypes.string,
  /**
   * Event for triggering onMosueOver
   */
  onMouseEnter: PropTypes.func,
  /**
   * Bool to control mouse highlighting
   */
  highlightMouse: PropTypes.bool,
  /**
   * Callback to set user on hover
   */
  onOptionMouseEnter: PropTypes.func,
  /**
   * isInteractive determines if menu will recieve events
   * This is used for the hidden menu offscreen in the RCE
   */
  isInteractive: PropTypes.bool,
  /**
   * Loading state from GraphQL query
   */
  isLoading: PropTypes.bool,
  /**
   * Whether there are more pages to load
   */
  hasNextPage: PropTypes.bool,
  /**
   * Callback to load more users
   */
  onLoadMore: PropTypes.func,
}

MentionDropdownMenu.defaultProps = {
  isInteractive: true,
  onSelect: () => {},
  isLoading: false,
  hasNextPage: false,
  onLoadMore: () => {},
}
