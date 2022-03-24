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
import {Popover} from '@instructure/ui-popover'
import {View} from '@instructure/ui-view'
import {TextInput} from '@instructure/ui-text-input'
import {TruncateText} from '@instructure/ui-truncate-text'
import {Spinner} from '@instructure/ui-spinner'
import {Heading} from '@instructure/ui-heading'
import {
  IconArrowOpenStartLine,
  IconArrowOpenEndLine,
  IconAddressBookLine
} from '@instructure/ui-icons'
import {
  ScreenReaderContent,
  AccessibleContent,
  PresentationContent
} from '@instructure/ui-a11y-content'
import {IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Tag} from '@instructure/ui-tag'
import {nanoid} from 'nanoid'
import {AddressBookItem} from './AddressBookItem'
import {useScope as useI18nScope} from '@canvas/i18n'
import React, {useEffect, useMemo, useState, useRef, useCallback} from 'react'

const I18n = useI18nScope('conversations_2')

const MOUSE_FOCUS_TYPE = 'mouse'
const KEYBOARD_FOCUS_TYPE = 'keyboard'
export const COURSE_TYPE = 'course'
export const SUBMENU_TYPE = 'subMenu'
export const BACK_BUTTON_TYPE = 'backButton'
export const HEADER_TEXT_TYPE = 'headerText'

export const AddressBook = ({
  menuData,
  onSelect,
  onTextChange,
  onSelectedIdsChange,
  isSubMenu,
  isLoading,
  limitTagCount,
  headerText,
  width,
  open,
  onUserFilterSelect,
  fetchMoreMenuData,
  hasMoreMenuData,
  isLoadingMoreMenuData,
  inputValue
}) => {
  const textInputRef = useRef(null)
  const componentViewRef = useRef(null)
  const popoverInstanceId = useRef(`address-book-menu-${nanoid()}`)
  const [isMenuOpen, setIsMenuOpen] = useState(open)
  const [selectedItem, setSelectedItem] = useState(null)
  const [selectedMenuItems, setSelectedMenuItems] = useState([])
  const [isLimitReached, setLimitReached] = useState(false)
  const [popoverWidth, setPopoverWidth] = useState('200px')
  const menuRef = useRef(null)
  const [focusType, setFocusType] = useState(KEYBOARD_FOCUS_TYPE) // Options are 'keyboard' and 'mouse'
  const backButtonArray = isSubMenu ? [{id: 'backButton', name: I18n.t('Back')}] : []
  const headerArray = headerText ? [{id: 'headerText', name: headerText, focusSkip: true}] : []
  const homeMenu = [
    {id: 'subMenuCourse', name: I18n.t('Courses')},
    {id: 'subMenuStudents', name: I18n.t('Students')}
  ]
  const [data, setData] = useState([
    ...backButtonArray,
    ...headerArray,
    ...menuData.contextData,
    ...menuData.userData
  ])
  const ariaAddressBookLabel = I18n.t('Address Book')
  const [menuItemCurrent, setMenuItemCurrent] = useState(null)
  const [isSubMenuSelection, setIsSubMenuSelection] = useState(true)

  const onItemRefSet = useCallback(refCurrent => {
    setMenuItemCurrent(refCurrent)
  }, [])

  // Update width to match componetViewRef width
  useEffect(() => {
    setPopoverWidth(componentViewRef?.current?.offsetWidth + 'px')
  }, [componentViewRef])

  // Keep Menu Data Up to Date when props change
  useEffect(() => {
    if (!isSubMenu) {
      setData([...homeMenu])
    } else {
      setData([...backButtonArray, ...headerArray, ...menuData.contextData, ...menuData.userData])
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [menuData, isSubMenu])

  // Reset selected item when data changes
  useEffect(() => {
    if (isSubMenuSelection) setSelectedItem(data[0])
  }, [data, isSubMenuSelection])

  // Limit amount of selected tags and close menu when limit reached
  useEffect(() => {
    if (!limitTagCount || selectedMenuItems.length < limitTagCount) {
      setLimitReached(false)
      textInputRef?.current?.removeAttribute('disabled', '')
    } else if (selectedMenuItems.length >= limitTagCount) {
      setLimitReached(true)
      textInputRef?.current?.setAttribute('disabled', true)
      setIsMenuOpen(false)
    }
  }, [selectedMenuItems, limitTagCount, textInputRef])

  // Provide selected IDs via callabck
  useEffect(() => {
    onSelectedIdsChange(selectedMenuItems)
  }, [onSelectedIdsChange, selectedMenuItems])

  // Creates an oberserver on the last scroll item to fetch more data when it becomes visible
  useEffect(() => {
    if (menuItemCurrent && hasMoreMenuData) {
      const observer = new IntersectionObserver(
        ([menuItem]) => {
          if (menuItem.isIntersecting) {
            observer.unobserve(menuItemCurrent)
            setIsSubMenuSelection(false)
            setMenuItemCurrent(null)
            fetchMoreMenuData()
          }
        },
        {
          root: null,
          rootMargin: '0px',
          threshold: 0.4
        }
      )

      if (menuItemCurrent) {
        observer.observe(menuItemCurrent)
      }

      return () => {}
    }
  }, [fetchMoreMenuData, hasMoreMenuData, menuItemCurrent])

  // Render individual menu items
  const renderMenuItem = (menuItem, isCourse, isBackButton, isHeader, isLast, isSubmenu) => {
    if (isHeader) {
      return renderHeaderItem(menuItem.name)
    }

    return (
      <View
        key={`address-book-item-${menuItem.id}`}
        elementRef={el => {
          if (isLast) {
            onItemRefSet(el)
          }
        }}
      >
        <AddressBookItem
          iconAfter={isCourse || isSubmenu ? <IconArrowOpenEndLine /> : null}
          iconBefore={isBackButton ? <IconArrowOpenStartLine /> : null}
          as="div"
          isSelected={selectedItem?.id === menuItem.id}
          hasPopup={!!(isCourse || isSubmenu)}
          id={`address-book-menu-item-${menuItem.id}`}
          onSelect={() => {
            selectHandler(menuItem, isCourse, isBackButton, isSubmenu)
          }}
          onHover={() => {
            if (focusType !== MOUSE_FOCUS_TYPE) {
              setFocusType(MOUSE_FOCUS_TYPE)
            }
            setSelectedItem(menuItem)
          }}
          menuRef={menuRef}
          isKeyboardFocus={focusType === KEYBOARD_FOCUS_TYPE}
        >
          {menuItem.name}
        </AddressBookItem>
      </View>
    )
  }

  // Render no results found item
  const renderNoResultsFound = () => {
    return (
      <View as="div" padding="xx-small">
        <Flex width="100%" margin="xxx-small none xxx-small xxx-small">
          <Flex.Item align="center" shouldGrow shouldShrink>
            <View>
              <Text>{I18n.t('No Results Found')}</Text>
            </View>
          </Flex.Item>
        </Flex>
      </View>
    )
  }

  // Render header menu item
  const renderHeaderItem = text => {
    return (
      <View as="div" padding="xx-small">
        <Flex
          width="100%"
          margin="xxx-small none xxx-small xxx-small"
          key="address-book-header"
          data-testid="address-book-header"
        >
          <Flex.Item align="center" shouldGrow shouldShrink>
            <View>
              <PresentationContent>
                <TruncateText>
                  <Heading level="h4" as="span">
                    {text}
                  </Heading>
                </TruncateText>
              </PresentationContent>
            </View>
          </Flex.Item>
        </Flex>
      </View>
    )
  }

  // Memo which determines appropriate render methods to call
  const renderedItems = useMemo(() => {
    if (data.length === 0 && !isLoading) {
      return renderNoResultsFound()
    }

    return data.map(menuItem => {
      return renderMenuItem(
        menuItem,
        menuItem.id.includes(COURSE_TYPE),
        menuItem.id.includes(BACK_BUTTON_TYPE),
        menuItem.id.includes(HEADER_TEXT_TYPE),
        menuItem?.isLast,
        menuItem.id.includes(SUBMENU_TYPE)
      )
    })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [data, selectedItem, selectedMenuItems, focusType])

  // Loading renderer
  const renderLoading = () => {
    return (
      <View as="div" padding="xx-small" data-testid="menu-loading-spinner">
        <Flex width="100%" margin="xxx-small none xxx-small xxx-small">
          <Flex.Item align="start" margin="0 small 0 0">
            <Spinner renderTitle={I18n.t('Loading')} size="x-small" />
          </Flex.Item>
          <Flex.Item align="center" shouldGrow shouldShrink>
            <View>
              <Text>{I18n.t('Loading')}</Text>
            </View>
          </Flex.Item>
        </Flex>
      </View>
    )
  }

  const renderedSelectedTags = useMemo(() => {
    return selectedMenuItems.map(menuItem => {
      return (
        <span data-testid="address-book-tag" key={`address-book-tag-${menuItem.id}`}>
          <Tag
            text={
              <AccessibleContent alt={`${I18n.t('Remove')} ${menuItem.name}`}>
                {menuItem.name}
              </AccessibleContent>
            }
            dismissible
            margin="0 xx-small 0 0"
            onClick={() => {
              removeTag(menuItem)
            }}
            key={`address-book-tag-${menuItem.id}`}
          />
        </span>
      )
    })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedMenuItems])

  // Key handler for input
  const inputKeyHandler = e => {
    setFocusType(KEYBOARD_FOCUS_TYPE)

    // Reremove unfocusable items
    const focusableData = data.filter(item => !item.focusSkip)

    const currentPosition = focusableData.findIndex(item => {
      return item.id === selectedItem?.id
    })

    if (!currentPosition) {
      setSelectedItem(focusableData[0])
    }

    let position = 0
    switch (e.keyCode) {
      case 38: // up
        if (!isLimitReached && currentPosition === 0) {
          position = focusableData.length - 1
          setSelectedItem(focusableData[position])
        } else if (!isLimitReached) {
          position = currentPosition - 1
          setSelectedItem(focusableData[position])
        }
        break
      case 40: // down
        if (!isMenuOpen && !isLimitReached) {
          setIsMenuOpen(true)
        }

        if (currentPosition >= focusableData.length - 1 && !isLimitReached) {
          position = 0
          setSelectedItem(focusableData[position])
        } else if (!isLimitReached) {
          position = currentPosition + 1
          setSelectedItem(focusableData[position])
        }
        break
      case 8: // Backspace
        if (inputValue === '') {
          removeTag(selectedMenuItems[selectedMenuItems.length - 1])
        }
        break
      case 27: // Escape
        isMenuOpen && setIsMenuOpen(false)
        break
      case 13: // Enter
        selectHandler(selectedItem, undefined, undefined)
        break
      default:
        break
    }
  }

  // Handler for selecting an item
  // Controls callback + tag addition
  const selectHandler = (menuItem, isCourse, isBackButton, isSubmenu) => {
    // If information is not available, quickly find it from data state
    if (isCourse === undefined && isBackButton === undefined && isSubmenu === undefined) {
      const selectedMenuItem = data.find(u => u.id === selectedItem?.id)
      isCourse = selectedMenuItem.id.includes(COURSE_TYPE)
      isSubmenu = selectedMenuItem.id.includes(SUBMENU_TYPE)
      isBackButton = selectedMenuItem.id.includes(BACK_BUTTON_TYPE)
    }

    // Only add tags for users
    if (!isBackButton && !isCourse && !isSubmenu) {
      addTag(menuItem)
      onSelect(menuItem.id)
      if (onUserFilterSelect) {
        onUserFilterSelect(menuItem?._id ? `user_${menuItem?._id}` : undefined)
      }
    } else {
      setIsSubMenuSelection(true)
      onSelect(menuItem.id, isCourse, isBackButton, isSubmenu)
    }
  }

  const addTag = menuItem => {
    const newSelectedMenuItems = selectedMenuItems
    const matchedMenuItems = newSelectedMenuItems.filter(u => {
      return u.id === menuItem.id
    })

    // Prevent duplicate IDs from being added
    if (matchedMenuItems.length === 0) {
      newSelectedMenuItems.push(menuItem)
      onTextChange('')
    }

    setSelectedMenuItems([...newSelectedMenuItems])
  }

  const removeTag = removeMenuItem => {
    let newSelectedMenuItems = selectedMenuItems
    if (onUserFilterSelect) {
      onUserFilterSelect(undefined)
    }
    newSelectedMenuItems = newSelectedMenuItems.filter(
      menuItem => menuItem.id !== removeMenuItem.id
    )
    setSelectedMenuItems([...newSelectedMenuItems])
  }

  return (
    <View as="div" width={width}>
      <div ref={componentViewRef}>
        <Flex>
          <Flex.Item padding="none xxx-small none none" shouldGrow shouldShrink>
            <Popover
              on="click"
              offsetY={4}
              placement="bottom start"
              isShowingContent={isMenuOpen}
              onShowContent={() => {
                setIsMenuOpen(true)
              }}
              onHideContent={(e, {documentClick}) => {
                if (
                  documentClick &&
                  e?.target?.getAttribute('aria-label') !== ariaAddressBookLabel
                ) {
                  setIsMenuOpen(false)
                }
              }}
              renderTrigger={
                <TextInput
                  renderLabel={
                    <ScreenReaderContent>{I18n.t('Address Book Input')}</ScreenReaderContent>
                  }
                  renderBeforeInput={selectedMenuItems.length === 0 ? null : renderedSelectedTags}
                  onFocus={() => {
                    if (!isLimitReached) {
                      setIsMenuOpen(true)
                    }
                  }}
                  onBlur={() => {
                    if (focusType === KEYBOARD_FOCUS_TYPE) {
                      setIsMenuOpen(false)
                    }
                  }}
                  onKeyDown={inputKeyHandler}
                  aria-expanded={isMenuOpen}
                  aria-activedescendant={`address-book-menu-item-${selectedItem?.id}`}
                  type="search"
                  aria-owns={popoverInstanceId.current}
                  aria-label={ariaAddressBookLabel}
                  aria-autocomplete="list"
                  inputRef={ref => {
                    textInputRef.current = ref
                  }}
                  value={inputValue}
                  onChange={e => {
                    onTextChange(e.target.value)
                    setIsMenuOpen(true)
                  }}
                  data-testid="address-book-input"
                />
              }
            >
              {isLoading && !isLoadingMoreMenuData && renderLoading()}
              {(!isLoading || isLoadingMoreMenuData) && (
                <View
                  elementRef={el => {
                    menuRef.current = el
                  }}
                  as="div"
                  width={popoverWidth}
                  maxHeight="45vh"
                  overflowY="auto"
                >
                  <ul
                    role="menu"
                    aria-label={I18n.t('Address Book Menu')}
                    id={popoverInstanceId.current}
                    style={{
                      paddingInlineStart: '0px',
                      marginBlockStart: '0px',
                      marginBlockEnd: '0px',
                      margin: '0'
                    }}
                    data-testid="address-book-popover"
                  >
                    {renderedItems}
                    {isLoadingMoreMenuData && renderLoading()}
                  </ul>
                </View>
              )}
            </Popover>
          </Flex.Item>
          <Flex.Item>
            <IconButton
              data-testid="address-button"
              screenReaderLabel={I18n.t('Open Address Book')}
              onClick={() => {
                if (isMenuOpen) {
                  setIsMenuOpen(false)
                } else {
                  textInputRef.current.focus()
                }
              }}
              disabled={isLimitReached}
            >
              <IconAddressBookLine />
            </IconButton>
          </Flex.Item>
        </Flex>
      </div>
    </View>
  )
}

AddressBook.defaultProps = {
  width: '340px',
  menuData: {},
  onTextChange: () => {},
  onSelect: () => {},
  onSelectedIdsChange: () => {}
}

AddressBook.propTypes = {
  /**
   * Array of Menu Data to be displayed
   */
  menuData: PropTypes.object,
  /**
   * Callback for an item being selected
   */
  onSelect: PropTypes.func,
  /**
   * Callback which provides text changes
   */
  onTextChange: PropTypes.func,
  /**
   * Callback which provides an array of selected items
   */
  onSelectedIdsChange: PropTypes.func,
  /**
   * Boolean for if subMenu back button should render
   */
  isSubMenu: PropTypes.bool,
  /**
   * Boolean to control if menu is loading
   */
  isLoading: PropTypes.bool,
  /**
   * Number that limits selected item count
   */
  limitTagCount: PropTypes.number,
  /**
   * Header text displayed inside Menu
   */
  headerText: PropTypes.string,
  /**
   * Width of AddressBook component
   */
  width: PropTypes.string,
  /**
   * Bool which determines if addressbook is intialed open
   */
  open: PropTypes.bool,
  /**
   * use State function to set user filter for conversations
   */
  onUserFilterSelect: PropTypes.func,
  /**
   * Bool which determines if Menu can load more data
   */
  hasMoreMenuData: PropTypes.bool,
  /**
   * Function to call next page
   */
  fetchMoreMenuData: PropTypes.func,
  /**
   * Bool which determines if menu is fetching more data
   */
  isLoadingMoreMenuData: PropTypes.bool,
  inputValue: PropTypes.string
}

export default AddressBook
