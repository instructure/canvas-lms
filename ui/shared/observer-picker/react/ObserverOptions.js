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

import React, {useCallback, useEffect, useState} from 'react'
import PropTypes from 'prop-types'
import I18n from 'i18n!observer_options'

import {View} from '@instructure/ui-view'
import {ScreenReaderContent, AccessibleContent} from '@instructure/ui-a11y-content'
import {IconUserLine, IconAddLine} from '@instructure/ui-icons'
import {Avatar} from '@instructure/ui-avatar'
import {Text} from '@instructure/ui-text'

import CanvasAsyncSelect from '@canvas/instui-bindings/react/AsyncSelect'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import doFetchApi from '@canvas/do-fetch-api-effect'

import {savedObservedId, saveObservedId} from '../ObserverGetObservee'
import AddStudentModal from './AddStudentModal'
import {parseObservedUsersList, parseObservedUsersResponse} from './utils'

const ObserverOptions = ({
  observedUsersList,
  currentUser,
  handleChangeObservedUser,
  margin,
  canAddObservee,
  currentUserRoles
}) => {
  const [observedUsers, setObservedUsers] = useState(() =>
    parseObservedUsersList(observedUsersList)
  )
  const [selectSearchValue, setSelectSearchValue] = useState('')
  const [selectedUser, setSelectedUser] = useState(null)
  const [newStudentModalOpen, setNewStudentModalOpen] = useState(false)
  const isOnlyObserver = currentUserRoles?.every(r => r === 'user' || r === 'observer')

  const updateObservedUser = useCallback(
    user => {
      setSelectSearchValue(user.name)
      setSelectedUser(user)
      handleChangeObservedUser(user.id)
      saveObservedId(currentUser.id, user.id)
    },
    [currentUser.id, handleChangeObservedUser]
  )

  const handleUserSelected = useCallback(
    id => {
      const user = observedUsers.find(u => u.id === id)
      updateObservedUser(user)
    },
    [observedUsers, updateObservedUser]
  )

  useEffect(() => {
    if (observedUsers.length > 0) {
      const storedObservedUserId = savedObservedId(currentUser.id)
      const validUser = observedUsers.find(u => u.id === storedObservedUserId)
      updateObservedUser(validUser || observedUsers[0])
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const selectAvatar =
    /* don't show the default Canvas avatar */
    selectedUser?.avatarUrl && !selectedUser.avatarUrl.includes('avatar-50.png') ? (
      /* hack to shrink the avatar - should be able to use size="xx-small" on inst-ui 7.9.0 */
      <span style={{fontSize: '0.5rem', verticalAlign: 'middle'}}>
        <Avatar name={selectedUser.name} src={selectedUser.avatarUrl} size="auto" />
      </span>
    ) : (
      <IconUserLine />
    )
  const onNewStudentPaired = async () => {
    try {
      const {json} = await doFetchApi({
        path: '/api/v1/users/self/enrollments',
        params: {
          type: ['ObserverEnrollment'],
          include: ['avatar_url', 'observed_users'],
          per_page: 100
        }
      })
      const observees = parseObservedUsersResponse(json, isOnlyObserver, currentUser)
      const newObservee = observees.reduce((previous, current) => {
        if (observedUsers.findIndex(ou => ou.id === current.id) < 0) {
          return current
        } else {
          return previous
        }
      })
      setObservedUsers(observees)
      updateObservedUser(newObservee)
    } catch (ex) {
      showFlashAlert({
        message: I18n.t('Unable to get observed students'),
        err: ex,
        type: 'error'
      })
    }
  }

  const addStudentOption = (
    <CanvasAsyncSelect.Option
      key="new"
      id="new-student-option"
      value="new"
      renderBeforeLabel={props => <IconAddLine color={!props.isHighlighted ? 'brand' : null} />}
      // according to the documentation the next line should override the default color
      // on inst-ui 8.7.0, but it doesn't seem to work on inst-ui 7.9.0
      // themeOverride={{color: k5Theme.variables.colors.brand}}
    >
      {props => <Text color={!props.isHighlighted ? 'brand' : null}>{I18n.t('Add Student')}</Text>}
    </CanvasAsyncSelect.Option>
  )

  const handleClose = () => {
    setNewStudentModalOpen(false)
  }
  const handleOptionSelected = id => {
    if (id === 'new-student-option') {
      setNewStudentModalOpen(true)
    } else {
      handleUserSelected(id)
    }
  }

  if (observedUsers.length > 1 || canAddObservee) {
    const userPickerOptions = observedUsers
      .filter(
        u =>
          u.name.toLowerCase().includes(selectSearchValue.toLowerCase()) ||
          selectedUser.name.toLowerCase() === selectSearchValue.toLowerCase()
      )
      .map(u => (
        <CanvasAsyncSelect.Option
          key={u.id}
          id={u.id}
          value={u.id}
          renderBeforeLabel={<IconUserLine />}
        >
          {u.name}
        </CanvasAsyncSelect.Option>
      ))
    if (canAddObservee) {
      userPickerOptions.push(addStudentOption)
    }
    return (
      <View as="div" margin={margin}>
        <CanvasAsyncSelect
          data-testid="observed-student-dropdown"
          inputValue={selectSearchValue}
          renderLabel={
            <ScreenReaderContent>{I18n.t('Select a student to view')}</ScreenReaderContent>
          }
          noOptionsLabel={I18n.t('No Results')}
          onInputChange={e => setSelectSearchValue(e.target.value)}
          onOptionSelected={(_e, id) => {
            handleOptionSelected(id)
          }}
          renderBeforeInput={selectAvatar}
          shouldNotWrap
        >
          {userPickerOptions}
        </CanvasAsyncSelect>
        {canAddObservee && (
          <AddStudentModal
            open={newStudentModalOpen}
            handleClose={handleClose}
            currentUserId={currentUser.id}
            onStudentPaired={onNewStudentPaired}
          />
        )}
      </View>
    )
  } else if (observedUsers.length === 1 && observedUsers[0].id !== currentUser.id) {
    return (
      <View as="div" margin={margin}>
        <AccessibleContent
          alt={I18n.t('You are observing %{observedUser}', {observedUser: observedUsers[0].name})}
        >
          <Text as="div" data-testid="observed-student-label">
            {selectAvatar} {observedUsers[0].name}
          </Text>
        </AccessibleContent>
      </View>
    )
  } else {
    return null
  }
}

export const ObservedUsersListShape = PropTypes.arrayOf(
  PropTypes.shape({
    id: PropTypes.string.isRequired,
    name: PropTypes.string.isRequired,
    avatar_url: PropTypes.string
  })
)

export const shouldShowObserverOptions = (observedUsersList, currentUser) =>
  observedUsersList.length > 1 ||
  (observedUsersList.length === 1 && observedUsersList[0].id !== currentUser.id)

ObserverOptions.propTypes = {
  observedUsersList: ObservedUsersListShape.isRequired,
  currentUser: PropTypes.shape({
    id: PropTypes.string,
    display_name: PropTypes.string,
    avatar_image_url: PropTypes.string
  }).isRequired,
  handleChangeObservedUser: PropTypes.func.isRequired,
  margin: PropTypes.string,
  canAddObservee: PropTypes.bool.isRequired,
  currentUserRoles: PropTypes.arrayOf(PropTypes.string).isRequired
}

export default ObserverOptions
