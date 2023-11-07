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
import {useScope as useI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import {Alert} from '@instructure/ui-alerts'
import {Select} from '@instructure/ui-select'
import {Tag} from '@instructure/ui-tag'

const I18n = useI18nScope('video_conference')

export const ConferenceAddressBook = ({menuItemList, onChange, selectedItems, isEditing}) => {
  const [isOpen, setIsOpen] = useState(false)
  const [highlightMenuItem, setHighlightMenuItem] = useState(null)
  const [inputValue, setInputValue] = useState('')
  const [selectedMenuItems, setSelectedMenuItems] = useState([])
  const [announcement, setAnnouncement] = useState('')
  const [savedAttendees, setSavedAttendees] = useState([])

  const groupUserMap = ENV?.group_user_ids_map || {}
  const sectionUserMap = ENV?.section_user_ids_map || {}

  // Create an array that contains the shared elements between 2 arrays
  const intersection = (array1, array2) => {
    let tempSwitchVariable
    if (array2.length > array1.length) {
      tempSwitchVariable = array2
      array2 = array1
      array1 = tempSwitchVariable
    }
    return array1.filter(e => {
      return array2.indexOf(e) > -1
    })
  }
  // Runs once on startup to set up initially selected items
  useEffect(() => {
    const selectedUserIDs = selectedItems?.map(u => u.id)
    const selectedUserAssetCode = selectedItems?.map(u => u.assetCode)
    // This should only get set once. Represents users who are already a part of the conference

    const sectionIDs = ENV.sections?.map(u => u.id) || []
    const groupIDs = ENV.groups?.map(u => u.id) || []

    let selectedSections = []
    let selectedGroups = []

    // Any section or group that has all of its students selected will be auto selected
    // Empty groups or sections will be set to selected automatically
    sectionIDs?.forEach(id => {
      const sectionUsers = sectionUserMap[id]
      const intersectionArray = intersection(sectionUsers, selectedUserIDs)
      if (intersectionArray.length === sectionUsers.length) {
        selectedSections.push(id)
      }
    })

    groupIDs?.forEach(id => {
      const groupUsers = groupUserMap[id]
      const intersectionArray = intersection(groupUsers, selectedUserIDs)
      // guarding against empty arrays, these lead to pre-selecting groups
      // that have no members
      if (intersectionArray.length > 0 && intersectionArray.length === groupUsers.length) {
        selectedGroups.push(id)
      }
    })

    selectedGroups = selectedGroups?.map(u => `group-${u}`)
    selectedSections = selectedSections?.map(u => `section-${u}`)
    const initialSelectedMenuItems = menuItemList.filter(u =>
      selectedGroups.concat(selectedSections, selectedUserAssetCode)?.includes(u.assetCode)
    )
    setSavedAttendees(initialSelectedMenuItems.map(u => u.assetCode))
    setSelectedMenuItems([...selectedMenuItems.concat(initialSelectedMenuItems)])
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const handleBlur = () => {
    setHighlightMenuItem(null)
  }

  const handleInputChange = e => {
    if (!isOpen) {
      setIsOpen(true)
    }
    setInputValue(e.target.value)
  }

  const handleHighlight = (e, {id}) => {
    if (id) {
      const menuItem = menuItemList.find(u => u.assetCode === id)
      setHighlightMenuItem(menuItem)
      setAnnouncement(menuItem.displayName)
    }
  }

  const filteredMenuItems = useMemo(() => {
    let newMenuItemList = menuItemList.filter(u => u.displayName.includes(inputValue))
    newMenuItemList = newMenuItemList.filter(u => !selectedMenuItems.includes(u))

    const getOptionsChangedMessage = newMenuItems => {
      let message =
        newMenuItems.length !== menuItemList.length
          ? `${newMenuItems.length} options available.` // options changed, announce new total
          : null // options haven't changed, don't announce
      if (message && newMenuItems.length > 0) {
        // options still available
        if (highlightMenuItem !== newMenuItems[0]) {
          // highlighted option hasn't been announced
          message = `${highlightMenuItem?.displayName}. ${message}`
        }
      }
      return message
    }

    if (inputValue.length) {
      const newAnnouncement = getOptionsChangedMessage(newMenuItemList)
      setAnnouncement(newAnnouncement)
    }

    return newMenuItemList
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [inputValue, menuItemList, selectedMenuItems.length])

  const mapOfFilteredMenuItems = useMemo(() => {
    const sectionArray = []
    const groupArray = []
    const userArray = []

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
      ['sections', sectionArray],
      ['groups', groupArray],
      ['users', userArray],
    ])
  }, [filteredMenuItems])

  const removeSelectedItem = menuItem => {
    if (isEditing) {
      // Change this to work with asset codes
      if (savedAttendees?.includes(menuItem.assetCode)) {
        // terminate if menu item has been saved
        return
      }
    }

    // Get users from group or section to Remove
    let additionalUsersToRemove = []
    if (menuItem.type === 'group') {
      additionalUsersToRemove = groupUserMap[menuItem.id]?.map(u => `user-${u}`)
    } else if (menuItem.type === 'section') {
      additionalUsersToRemove = sectionUserMap[menuItem.id]?.map(u => `user-${u}`)
    }

    const unsavedUsersToRemove = additionalUsersToRemove.filter(x => !savedAttendees?.includes(x))

    const menuItemsToRemove = menuItemList.filter(u => unsavedUsersToRemove?.includes(u.assetCode))
    menuItemsToRemove.push(menuItem)
    const newSelectedMenuItems = selectedMenuItems
    menuItemsToRemove.forEach(currentMenuItem => {
      const removalIndex = newSelectedMenuItems.indexOf(currentMenuItem)
      if (removalIndex > -1) {
        newSelectedMenuItems.splice(removalIndex, 1)
      }
    })
    setSelectedMenuItems([...newSelectedMenuItems])
    onChange([...newSelectedMenuItems])
  }

  const addSelectedItem = (event, {id}) => {
    const menuItem = menuItemList.find(u => u.assetCode === id)
    // Exit if selected menu item is already selected
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
    additionalUsersToAdd = additionalUsersToAdd?.map(u => `user-${u}`)
    // Remove users that have already been selected so duplicates do not occur
    const selectedMenuItemsAssetCode = selectedMenuItems?.map(u => u.assetCode)
    const unselectedUsers = additionalUsersToAdd.filter(
      x => !selectedMenuItemsAssetCode.includes(x)
    )
    const additionalUsersToAddMenuItem = menuItemList.filter(u =>
      unselectedUsers?.includes(u.assetCode)
    )
    additionalUsersToAddMenuItem.push(menuItem)

    const newSelectedItems = selectedMenuItems.concat(additionalUsersToAddMenuItem)
    setAnnouncement(`${menuItem.displayName} selected. List collapsed.`)
    setSelectedMenuItems([...newSelectedItems])
    onChange([...newSelectedItems])
    setInputValue('')
    setIsOpen(false)
  }

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
      <Select
        data-testid="address-input"
        renderLabel={I18n.t('Course Members')}
        assistiveText={I18n.t(
          'Type or use arrow keys to navigate options. Multiple selections allowed.'
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
const ConferenceAddressBookTags = ({selectedMenuItems, onDismiss}) => {
  return selectedMenuItems.map((menuItem, index) => (
    <Tag
      data-testid="address-tag"
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
