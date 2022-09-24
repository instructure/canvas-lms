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

export const ConferenceAddressBook = ({
  menuItemList,
  onChange,
  selectedIds,
  isEditing,
  savedAttendees,
}) => {
  const [isOpen, setIsOpen] = useState(false)
  const [highlightMenuItem, setHighlightMenuItem] = useState(null)
  const [inputValue, setInputValue] = useState('')
  const [selectedMenuItems, setSelectedMenuItems] = useState([])
  const [announcement, setAnnouncement] = useState('')

  // Initial setup of selectd Ids
  useEffect(() => {
    const initialSelectedMenuItems = menuItemList.filter(u => selectedIds?.includes(u.id))
    if (initialSelectedMenuItems !== selectedMenuItems) {
      setSelectedMenuItems(initialSelectedMenuItems)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedIds, menuItemList])

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
      const menuItem = menuItemList.find(u => u.id === id)
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

  const removeSelectedItem = menuItem => {
    if (isEditing) {
      if (savedAttendees?.includes(menuItem.id))
        // terminate if menu item has been saved
        return
    }
    const newSelectedMenuItems = selectedMenuItems
    const removalIndex = newSelectedMenuItems.indexOf(menuItem)
    if (removalIndex > -1) {
      newSelectedMenuItems.splice(removalIndex, 1)
    }
    setSelectedMenuItems([...newSelectedMenuItems])
    onChange([...newSelectedMenuItems])
  }

  const addSelectedItem = (event, {id}) => {
    const menuItem = menuItemList.find(u => u.id === id)

    // Exit if selected menu item is already selected
    if (selectedMenuItems.includes(menuItem)) {
      setIsOpen(false)
      setInputValue('')
      return
    }

    const newSelectedItems = selectedMenuItems
    newSelectedItems.push(menuItem)
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
        data-testId="address-input"
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
        {filteredMenuItems?.map(u => {
          return (
            <Select.Option id={u.id} key={u.id} isHighlighted={u.id === highlightMenuItem?.id}>
              {u.displayName}
            </Select.Option>
          )
        })}
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
  selectedIds: PropTypes.arrayOf(PropTypes.string),
  savedAttendees: PropTypes.arrayOf(PropTypes.string),
  onChange: PropTypes.func,
  isEditing: PropTypes.bool,
}

ConferenceAddressBook.defaultProps = {
  onChange: () => {},
}
const ConferenceAddressBookTags = ({selectedMenuItems, onDismiss}) => {
  return selectedMenuItems.map((menuItem, index) => (
    <Tag
      data-testId="address-tag"
      dismissable={true}
      key={menuItem.id}
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
