/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import React, {useState, useMemo, useEffect} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import {Alert} from '@instructure/ui-alerts'
import {Select} from '@instructure/ui-select'
import {Tag} from '@instructure/ui-tag'

const I18n = createI18nScope('video_conference')

// @ts-expect-error TS7031 (typescriptify)
export const ConferenceAddressBook = ({menuItemList, onChange, selectedItems, isEditing}) => {
  const [isOpen, setIsOpen] = useState(false)
  const [highlightMenuItem, setHighlightMenuItem] = useState(null)
  const [inputValue, setInputValue] = useState('')
  const [selectedMenuItems, setSelectedMenuItems] = useState([])
  const [announcement, setAnnouncement] = useState('')
  const [savedAttendees, setSavedAttendees] = useState([])

  // @ts-expect-error TS2339 (typescriptify)
  const groupUserMap = ENV?.group_user_ids_map || {}
  // @ts-expect-error TS2339 (typescriptify)
  const sectionUserMap = ENV?.section_user_ids_map || {}

  // Create an array that contains the shared elements between 2 arrays
  // @ts-expect-error TS7006 (typescriptify)
  const intersection = (array1, array2) => {
    let tempSwitchVariable
    if (array2.length > array1.length) {
      tempSwitchVariable = array2
      array2 = array1
      array1 = tempSwitchVariable
    }
    // @ts-expect-error TS7006 (typescriptify)
    return array1.filter(e => {
      return array2.indexOf(e) > -1
    })
  }
  // Runs once on startup to set up initially selected items
  useEffect(() => {
    // @ts-expect-error TS7006 (typescriptify)
    const selectedUserIDs = selectedItems?.map(u => u.id)
    // @ts-expect-error TS7006 (typescriptify)
    const selectedUserAssetCode = selectedItems?.map(u => u.assetCode)
    // This should only get set once. Represents users who are already a part of the conference

    // @ts-expect-error TS2551,TS7006 (typescriptify)
    const sectionIDs = ENV.sections?.map(u => u.id) || []
    // @ts-expect-error TS2339,TS7006 (typescriptify)
    const groupIDs = ENV.groups?.map(u => u.id) || []

    // @ts-expect-error TS7034 (typescriptify)
    let selectedSections = []
    // @ts-expect-error TS7034 (typescriptify)
    let selectedGroups = []

    // Any section or group that has all of its students selected will be auto selected
    // Empty groups or sections will be set to selected automatically
    // @ts-expect-error TS7006 (typescriptify)
    sectionIDs?.forEach(id => {
      const sectionUsers = sectionUserMap[id]
      const intersectionArray = intersection(sectionUsers, selectedUserIDs)
      if (intersectionArray.length === sectionUsers.length) {
        selectedSections.push(id)
      }
    })

    // @ts-expect-error TS7006 (typescriptify)
    groupIDs?.forEach(id => {
      const groupUsers = groupUserMap[id]
      const intersectionArray = intersection(groupUsers, selectedUserIDs)
      // guarding against empty arrays, these lead to pre-selecting groups
      // that have no members
      if (intersectionArray.length > 0 && intersectionArray.length === groupUsers.length) {
        selectedGroups.push(id)
      }
    })

    // @ts-expect-error TS7005 (typescriptify)
    selectedGroups = selectedGroups?.map(u => `group-${u}`)
    // @ts-expect-error TS7005 (typescriptify)
    selectedSections = selectedSections?.map(u => `section-${u}`)
    // @ts-expect-error TS7006 (typescriptify)
    const initialSelectedMenuItems = menuItemList.filter(u =>
      selectedGroups.concat(selectedSections, selectedUserAssetCode)?.includes(u.assetCode),
    )
    // @ts-expect-error TS7006 (typescriptify)
    setSavedAttendees(initialSelectedMenuItems.map(u => u.assetCode))
    setSelectedMenuItems([...selectedMenuItems.concat(initialSelectedMenuItems)])
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const handleBlur = () => {
    setHighlightMenuItem(null)
  }

  // @ts-expect-error TS7006 (typescriptify)
  const handleInputChange = e => {
    if (!isOpen) {
      setIsOpen(true)
    }
    setInputValue(e.target.value)
  }

  // @ts-expect-error TS7006,TS7031 (typescriptify)
  const handleHighlight = (e, {id}) => {
    if (id) {
      // @ts-expect-error TS7006 (typescriptify)
      const menuItem = menuItemList.find(u => u.assetCode === id)
      setHighlightMenuItem(menuItem)
      setAnnouncement(menuItem.displayName)
    }
  }

  const filteredMenuItems = useMemo(() => {
    const filteredMenuItemList = menuItemList
      // @ts-expect-error TS7006 (typescriptify)
      .filter(u => u.displayName.toLowerCase().includes(inputValue.toLowerCase()))
      // @ts-expect-error TS2345,TS7006 (typescriptify)
      .filter(u => !selectedMenuItems.includes(u))

    // @ts-expect-error TS7006 (typescriptify)
    const getOptionsChangedMessage = newMenuItems => {
      let message =
        newMenuItems.length !== menuItemList.length
          ? `${newMenuItems.length} options available.` // options changed, announce new total
          : null // options haven't changed, don't announce
      if (message && newMenuItems.length > 0) {
        // options still available
        if (highlightMenuItem !== newMenuItems[0]) {
          // highlighted option hasn't been announced
          // @ts-expect-error TS2339 (typescriptify)
          message = `${highlightMenuItem?.displayName}. ${message}`
        }
      }
      return message
    }

    if (inputValue.length) {
      const newAnnouncement = getOptionsChangedMessage(filteredMenuItemList)
      // @ts-expect-error TS2345 (typescriptify)
      setAnnouncement(newAnnouncement)
    }

    return filteredMenuItemList
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [inputValue, menuItemList, selectedMenuItems.length])

  const mapOfFilteredMenuItems = useMemo(() => {
    // @ts-expect-error TS7034 (typescriptify)
    const sectionArray = []
    // @ts-expect-error TS7034 (typescriptify)
    const groupArray = []
    // @ts-expect-error TS7034 (typescriptify)
    const userArray = []

    // @ts-expect-error TS7006 (typescriptify)
    filteredMenuItems.forEach(menuItem => {
      if (menuItem.type === 'section') {
        sectionArray.push(menuItem)
      } else if (menuItem.type === 'group') {
        groupArray.push(menuItem)
      } else {
        userArray.push(menuItem)
      }
    })

    return new Map([
      // @ts-expect-error TS7005 (typescriptify)
      ['sections', sectionArray],
      // @ts-expect-error TS7005 (typescriptify)
      ['groups', groupArray],
      // @ts-expect-error TS7005 (typescriptify)
      ['users', userArray],
    ])
  }, [filteredMenuItems])

  // @ts-expect-error TS7006 (typescriptify)
  const removeSelectedItem = menuItem => {
    if (isEditing) {
      // Change this to work with asset codes
      // @ts-expect-error TS2345 (typescriptify)
      if (savedAttendees?.includes(menuItem.assetCode)) {
        // terminate if menu item has been saved
        return
      }
    }

    // Get users from group or section to Remove
    let additionalUsersToRemove = []
    if (menuItem.type === 'group') {
      // @ts-expect-error TS7006 (typescriptify)
      additionalUsersToRemove = groupUserMap[menuItem.id]?.map(u => `user-${u}`)
    } else if (menuItem.type === 'section') {
      // @ts-expect-error TS7006 (typescriptify)
      additionalUsersToRemove = sectionUserMap[menuItem.id]?.map(u => `user-${u}`)
    }

    // @ts-expect-error TS2345,TS7006 (typescriptify)
    const unsavedUsersToRemove = additionalUsersToRemove.filter(x => !savedAttendees?.includes(x))

    // @ts-expect-error TS7006 (typescriptify)
    const menuItemsToRemove = menuItemList.filter(u => unsavedUsersToRemove?.includes(u.assetCode))
    menuItemsToRemove.push(menuItem)
    const newSelectedMenuItems = selectedMenuItems
    // @ts-expect-error TS7006 (typescriptify)
    menuItemsToRemove.forEach(currentMenuItem => {
      // @ts-expect-error TS2345 (typescriptify)
      const removalIndex = newSelectedMenuItems.indexOf(currentMenuItem)
      if (removalIndex > -1) {
        newSelectedMenuItems.splice(removalIndex, 1)
      }
    })
    setSelectedMenuItems([...newSelectedMenuItems])
    onChange([...newSelectedMenuItems])
  }

  // @ts-expect-error TS7006,TS7031 (typescriptify)
  const addSelectedItem = (event, {id}) => {
    // @ts-expect-error TS7006 (typescriptify)
    const menuItem = menuItemList.find(u => u.assetCode === id)
    // Exit if selected menu item is already selected
    // @ts-expect-error TS2345 (typescriptify)
    if (selectedMenuItems.includes(menuItem)) {
      setIsOpen(false)
      setInputValue('')
      return
    }

    // Get users from group or section to add
    let additionalUsersToAdd = []
    if (menuItem.type === 'group') {
      additionalUsersToAdd = groupUserMap[menuItem.id] || []
    } else if (menuItem.type === 'section') {
      additionalUsersToAdd = sectionUserMap[menuItem.id] || []
    }
    // @ts-expect-error TS7006 (typescriptify)
    additionalUsersToAdd = additionalUsersToAdd?.map(u => `user-${u}`)
    // Remove users that have already been selected so duplicates do not occur
    // @ts-expect-error TS2339 (typescriptify)
    const selectedMenuItemsAssetCode = selectedMenuItems?.map(u => u.assetCode)
    const unselectedUsers = additionalUsersToAdd.filter(
      // @ts-expect-error TS7006 (typescriptify)
      x => !selectedMenuItemsAssetCode.includes(x),
    )
    // @ts-expect-error TS7006 (typescriptify)
    const additionalUsersToAddMenuItem = menuItemList.filter(u =>
      unselectedUsers?.includes(u.assetCode),
    )
    additionalUsersToAddMenuItem.push(menuItem)

    const newSelectedItems = selectedMenuItems.concat(additionalUsersToAddMenuItem)
    setAnnouncement(`${menuItem.displayName} selected. List collapsed.`)
    setSelectedMenuItems([...newSelectedItems])
    onChange([...newSelectedItems])
    setInputValue('')
    setIsOpen(false)
  }

  // @ts-expect-error TS7006 (typescriptify)
  const handleKeyDown = e => {
    // Delete last tag when input is empty
    if (e.keyCode === 8) {
      if (inputValue === '' && selectedMenuItems?.length > 0) {
        removeSelectedItem(selectedMenuItems[selectedMenuItems?.length - 1])
      }
    }
  }

  return (
    <div>
      {/* @ts-expect-error TS2769 (typescriptify) */}
      <Select
        data-testid="address-input"
        renderLabel={I18n.t('Course Members')}
        assistiveText={I18n.t(
          'Type or use arrow keys to navigate options. Multiple selections allowed.',
        )}
        inputValue={inputValue}
        isShowingOptions={isOpen}
        onBlur={handleBlur}
        onInputChange={handleInputChange}
        onRequestShowOptions={() => setIsOpen(true)}
        onRequestHideOptions={() => setIsOpen(false)}
        onRequestHighlightOption={handleHighlight}
        onRequestSelectOption={addSelectedItem}
        onKeyDown={handleKeyDown}
        renderBeforeInput={
          selectedMenuItems.length > 0 ? (
            <ConferenceAddressBookTags
              selectedMenuItems={selectedMenuItems}
              onDismiss={removeSelectedItem}
            />
          ) : null
        }
      >
        {!!mapOfFilteredMenuItems.get('sections')?.length && (
          <Select.Group
            key="sections"
            renderLabel="Sections"
            data-testid="section-conference-header"
          >
            {mapOfFilteredMenuItems.get('sections')?.map(u => {
              return (
                <Select.Option
                  id={u.assetCode}
                  key={u.assetCode}
                  // @ts-expect-error TS2339 (typescriptify)
                  isHighlighted={u.assetCode === highlightMenuItem?.assetCode}
                  data-testid={u.assetCode}
                >
                  {u.displayName}
                </Select.Option>
              )
            })}
          </Select.Group>
        )}

        {!!mapOfFilteredMenuItems.get('groups')?.length && (
          <Select.Group key="groups" renderLabel="Groups" data-testid="group-conference-header">
            {mapOfFilteredMenuItems.get('groups')?.map(u => {
              return (
                <Select.Option
                  id={u.assetCode}
                  key={u.assetCode}
                  // @ts-expect-error TS2339 (typescriptify)
                  isHighlighted={u.assetCode === highlightMenuItem?.assetCode}
                  data-testid={u.assetCode}
                >
                  {u.displayName}
                </Select.Option>
              )
            })}
          </Select.Group>
        )}
        <Select.Group key="users" renderLabel="Users" data-testid="user-conference-header">
          {mapOfFilteredMenuItems.get('users')?.map(u => {
            return (
              <Select.Option
                id={u.assetCode}
                key={u.assetCode}
                // @ts-expect-error TS2339 (typescriptify)
                isHighlighted={u.assetCode === highlightMenuItem?.assetCode}
                data-testid={u.assetCode}
              >
                {u.displayName}
              </Select.Option>
            )
          })}
        </Select.Group>
      </Select>
      <Alert
        liveRegion={() => document.getElementById('flash-messages')}
        liveRegionPoliteness="assertive"
        screenReaderOnly={true}
      >
        {announcement}
      </Alert>
    </div>
  )
}

ConferenceAddressBook.propTypes = {
  menuItemList: PropTypes.array,
  onChange: PropTypes.func,
  isEditing: PropTypes.bool,
  selectedItems: PropTypes.arrayOf(PropTypes.object),
}

ConferenceAddressBook.defaultProps = {
  onChange: () => {},
}
// @ts-expect-error TS7031 (typescriptify)
const ConferenceAddressBookTags = ({selectedMenuItems, onDismiss}) => {
  // @ts-expect-error TS7006 (typescriptify)
  return selectedMenuItems.map((menuItem, index) => (
    <Tag
      data-testid="address-tag"
      // @ts-expect-error TS2769 (typescriptify)
      dismissable={true}
      key={menuItem.assetCode}
      title={`Remove ${menuItem.displayName}`}
      text={menuItem.displayName}
      margin={index > 0 ? 'xxx-small 0 xxx-small xx-small' : 'xxx-small 0'}
      onClick={() => {
        onDismiss(menuItem)
      }}
    />
  ))
}

ConferenceAddressBookTags.propTypes = {
  selectedMenuItems: PropTypes.arrayOf(PropTypes.object),
  onDismiss: PropTypes.func,
}

export default ConferenceAddressBook
