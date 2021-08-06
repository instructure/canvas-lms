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
import {IconUserLine} from '@instructure/ui-icons'
import {Avatar} from '@instructure/ui-avatar'
import {Text} from '@instructure/ui-text'

import LoadingWrapper from './LoadingWrapper'
import LoadingSkeleton from './LoadingSkeleton'
import useFetchApi from '@canvas/use-fetch-api-hook'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {parseObservedUsers} from './utils'
import CanvasAsyncSelect from '@canvas/instui-bindings/react/AsyncSelect'

const SAVED_USER_KEY = 'k5_observed_user_id'

const ObserverOptions = ({currentUser, currentUserRoles, handleChangeObservedUser}) => {
  const [loading, setLoading] = useState(true)
  const [observedUsers, setObservedUsers] = useState([])
  const [selectSearchValue, setSelectSearchValue] = useState('')
  const [selectedUser, setSelectedUser] = useState(null)

  const isOnlyObserver = currentUserRoles.every(r => r === 'user' || r === 'observer')

  useFetchApi({
    path: '/api/v1/users/self/enrollments',
    params: {
      type: ['ObserverEnrollment'],
      include: ['avatar_url', 'observed_users'],
      per_page: 100
    },
    loading: setLoading,
    success: useCallback(
      enrollments => {
        setObservedUsers(parseObservedUsers(enrollments, isOnlyObserver, currentUser))
      },
      [currentUser, isOnlyObserver]
    ),
    error: useCallback(err => showFlashError(I18n.t('Unable to get observed students'))(err), []),
    fetchNumPages: 10
  })

  const handleUserSelected = useCallback(
    id => {
      const user = observedUsers.find(u => u.id === id)
      setSelectSearchValue(user.name)
      setSelectedUser(user)
      handleChangeObservedUser(user.id)
      window.sessionStorage.setItem(SAVED_USER_KEY, user.id)
    },
    [handleChangeObservedUser, observedUsers]
  )

  useEffect(() => {
    if (observedUsers?.length > 0) {
      const storedObservedUserId = window.sessionStorage.getItem(SAVED_USER_KEY)
      const validUser = !!observedUsers.find(u => u.id === storedObservedUserId)
      handleUserSelected(validUser ? storedObservedUserId : observedUsers[0].id)
    }
  }, [observedUsers, handleUserSelected])

  const loadingSkeleton = props => (
    <div {...props}>
      <LoadingSkeleton
        height="2.25em"
        width="22em"
        margin="medium 0 0 0"
        screenReaderLabel={I18n.t('Loading observed students')}
      />
    </div>
  )

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

  return (
    <LoadingWrapper
      id="observer-options"
      isLoading={loading}
      renderCustomSkeleton={loadingSkeleton}
      skeletonsNum={currentUserRoles.includes('observer') ? 1 : 0}
    >
      {observedUsers?.length > 1 && (
        <View as="div" margin="medium 0 0 0" maxWidth="22em">
          <CanvasAsyncSelect
            inputValue={selectSearchValue}
            renderLabel={
              <ScreenReaderContent>{I18n.t('Select a student to view')}</ScreenReaderContent>
            }
            noOptionsLabel={I18n.t('No Results')}
            onInputChange={e => setSelectSearchValue(e.target.value)}
            onOptionSelected={(_e, id) => handleUserSelected(id)}
            renderBeforeInput={selectAvatar}
          >
            {observedUsers
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
              ))}
          </CanvasAsyncSelect>
        </View>
      )}
      {observedUsers?.length === 1 && isOnlyObserver && (
        <View as="div" margin="medium 0 0 0">
          <AccessibleContent
            alt={I18n.t('You are observing %{observedUser}', {observedUser: observedUsers[0].name})}
          >
            <Text as="div">
              {selectAvatar} {observedUsers[0].name}
            </Text>
          </AccessibleContent>
        </View>
      )}
    </LoadingWrapper>
  )
}

ObserverOptions.propTypes = {
  currentUser: PropTypes.shape({
    id: PropTypes.string,
    display_name: PropTypes.string,
    avatar_image_url: PropTypes.string
  }).isRequired,
  currentUserRoles: PropTypes.arrayOf(PropTypes.string).isRequired,
  handleChangeObservedUser: PropTypes.func.isRequired
}

export default ObserverOptions
