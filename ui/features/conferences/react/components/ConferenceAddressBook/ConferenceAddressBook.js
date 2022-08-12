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

export const ConferenceAddressBook = ({userList, onChange, selectedIds}) => {
  const [isOpen, setIsOpen] = useState(false)
  const [highlightUser, setHighlightUser] = useState(null)
  const [inputValue, setInputValue] = useState('')
  const [selectedUsers, setSelectedUsers] = useState([])
  const [announcement, setAnnouncement] = useState('')

  // Initial setup of selectd Ids
  useEffect(() => {
    const initialSelectedUsers = userList.filter(u => selectedIds?.includes(u.id))
    if (initialSelectedUsers !== selectedUsers) {
      setSelectedUsers(initialSelectedUsers)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedIds, userList])

  const handleBlur = () => {
    setHighlightUser(null)
  }

  const handleInputChange = e => {
    if (!isOpen) {
      setIsOpen(true)
    }
    setInputValue(e.target.value)
  }

  const handleHighlight = (e, {id}) => {
    if (id) {
      const user = userList.find(u => u.id === id)
      setHighlightUser(user)
      setAnnouncement(user.displayName)
    }
  }

  const filteredUsers = useMemo(() => {
    let newUserList = userList.filter(u => u.displayName.includes(inputValue))
    newUserList = newUserList.filter(u => !selectedUsers.includes(u))

    const getOptionsChangedMessage = newUsers => {
      let message =
        newUsers.length !== userList.length
          ? `${newUsers.length} options available.` // options changed, announce new total
          : null // options haven't changed, don't announce
      if (message && newUsers.length > 0) {
        // options still available
        if (highlightUser !== newUsers[0]) {
          // highlighted option hasn't been announced
          message = `${highlightUser?.displayName}. ${message}`
        }
      }
      return message
    }

    if (inputValue.length) {
      const newAnnouncement = getOptionsChangedMessage(newUserList)
      setAnnouncement(newAnnouncement)
    }

    return newUserList
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [inputValue, userList, selectedUsers.length])

  const removeSelectedUser = user => {
    const newSelectedUsers = selectedUsers
    const removalIndex = newSelectedUsers.indexOf(user)
    if (removalIndex > -1) {
      newSelectedUsers.splice(removalIndex, 1)
    }
    setSelectedUsers([...newSelectedUsers])
    onChange([...newSelectedUsers])
  }

  const addSelectedUser = (event, {id}) => {
    const user = userList.find(u => u.id === id)

    // Exit if selected user already selected
    if (selectedUsers.includes(user)) {
      setIsOpen(false)
      setInputValue('')
      return
    }

    const newSelectedUsers = selectedUsers
    newSelectedUsers.push(user)
    setAnnouncement(`${user.displayName} selected. List collapsed.`)
    setSelectedUsers([...newSelectedUsers])
    onChange([...newSelectedUsers])
    setInputValue('')
    setIsOpen(false)
  }

  const handleKeyDown = e => {
    // Delete last tag when input is empty
    if (e.keyCode === 8) {
      if (inputValue === '' && selectedUsers?.length > 0) {
        removeSelectedUser(selectedUsers[selectedUsers?.length - 1])
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
        onRequestSelectOption={addSelectedUser}
        onKeyDown={handleKeyDown}
        renderBeforeInput={
          selectedUsers.length > 0 ? (
            <ConferenceAddressBookTags
              selectedUsers={selectedUsers}
              onDismiss={removeSelectedUser}
            />
          ) : null
        }
      >
        {filteredUsers?.map(u => {
          return (
            <Select.Option id={u.id} key={u.id} isHighlighted={u.id === highlightUser?.id}>
              {u.displayName}
            </Select.Option>
          )
        })}
      </Select>
      <Alert
        liveRegion={() => document.getElementById('flash-messages')}
        liveRegionPoliteness="assertive"
        screenReaderOnly
      >
        {announcement}
      </Alert>
    </div>
  )
}

ConferenceAddressBook.propTypes = {
  userList: PropTypes.array,
  selectedIds: PropTypes.arrayOf(PropTypes.string),
  onChange: PropTypes.func
}

ConferenceAddressBook.defaultProps = {
  onChange: () => {}
}

const ConferenceAddressBookTags = ({selectedUsers, onDismiss}) => {
  return selectedUsers.map((user, index) => (
    <Tag
      data-testId="address-tag"
      dismissable
      key={user.id}
      title={`Remove ${user.displayName}`}
      text={user.displayName}
      margin={index > 0 ? 'xxx-small 0 xxx-small xx-small' : 'xxx-small 0'}
      onClick={() => {
        onDismiss(user)
      }}
    />
  ))
}

ConferenceAddressBookTags.propTypes = {
  selectedUsers: PropTypes.arrayOf(PropTypes.object),
  onDismiss: PropTypes.func
}

export default ConferenceAddressBook
