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
import getCookie from 'get-cookie'

import {View} from '@instructure/ui-view'
import {ScreenReaderContent, AccessibleContent} from '@instructure/ui-a11y-content'
import {IconUserLine} from '@instructure/ui-icons'
import {Avatar} from '@instructure/ui-avatar'
import {Text} from '@instructure/ui-text'

import {parseObserverList} from './utils'
import CanvasAsyncSelect from '@canvas/instui-bindings/react/AsyncSelect'

export const SELECTED_OBSERVED_USER_COOKIE = 'k5_observed_user_id'

const ObserverOptions = ({observerList, currentUser, handleChangeObservedUser, margin}) => {
  const [observedUsers] = useState(() => parseObserverList(observerList))
  const [selectSearchValue, setSelectSearchValue] = useState('')
  const [selectedUser, setSelectedUser] = useState(null)

  const handleUserSelected = useCallback(
    id => {
      const user = observedUsers.find(u => u.id === id)
      setSelectSearchValue(user.name)
      setSelectedUser(user)
      handleChangeObservedUser(user.id)
      document.cookie = `${SELECTED_OBSERVED_USER_COOKIE}=${user.id};path=/`
    },
    [handleChangeObservedUser, observedUsers]
  )

  useEffect(() => {
    if (observedUsers.length > 0) {
      const storedObservedUserId = getCookie(SELECTED_OBSERVED_USER_COOKIE)
      const validUser = !!observedUsers.find(u => u.id === storedObservedUserId)
      handleUserSelected(validUser ? storedObservedUserId : observedUsers[0].id)
    }
  }, [observedUsers, handleUserSelected])

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

  if (observedUsers.length > 1) {
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
          onOptionSelected={(_e, id) => handleUserSelected(id)}
          renderBeforeInput={selectAvatar}
          shouldNotWrap
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

export const ObserverListShape = PropTypes.arrayOf(
  PropTypes.shape({
    id: PropTypes.string.isRequired,
    name: PropTypes.string.isRequired,
    avatar_url: PropTypes.string
  })
)

export const shouldShowObserverOptions = (observerList, currentUser) =>
  observerList.length > 1 || (observerList.length === 1 && observerList[0].id !== currentUser.id)

ObserverOptions.propTypes = {
  observerList: ObserverListShape.isRequired,
  currentUser: PropTypes.shape({
    id: PropTypes.string,
    display_name: PropTypes.string,
    avatar_image_url: PropTypes.string
  }).isRequired,
  handleChangeObservedUser: PropTypes.func.isRequired,
  margin: PropTypes.string
}

export default ObserverOptions
