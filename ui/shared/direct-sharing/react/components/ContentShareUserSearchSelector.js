/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import I18n from 'i18n!user_search_selector'
import React, {useState} from 'react'
import {arrayOf, func, string} from 'prop-types'

import CanvasAsyncSelect from '@canvas/instui-bindings/react/AsyncSelect'
import useDebouncedSearchTerm from '../hooks/useDebouncedSearchTerm'
import useContentShareUserSearchApi from '../effects/useContentShareUserSearchApi'
import UserSearchSelectorItem from './UserSearchSelectorItem'
import {basicUser} from '@canvas/users/react/proptypes/user'

ContentShareUserSearchSelector.propTypes = {
  courseId: string.isRequired,
  onUserSelected: func.isRequired, // (basicUser) => {} (see proptypes/user.js)
  selectedUsers: arrayOf(basicUser),
  ...(() => {
    const {renderLabel, ...restOfSelectPropTypes} = CanvasAsyncSelect.propTypes
    return restOfSelectPropTypes
  })()
}

ContentShareUserSearchSelector.defaultProps = {
  selectedUsers: []
}

const MINIMUM_SEARCH_LENGTH = 3

const isSearchableTerm = term => term.length >= MINIMUM_SEARCH_LENGTH

export default function ContentShareUserSearchSelector({
  courseId,
  onUserSelected,
  selectedUsers,
  ...restOfSelectProps
}) {
  const [searchedUsers, setSearchedUsers] = useState(null)
  const [error, setError] = useState(null)
  const [inputValue, setInputValue] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const {searchTerm, setSearchTerm, searchTermIsPending} = useDebouncedSearchTerm('', {
    isSearchableTerm
  })

  const userSearchParams = {}
  if (searchTerm.length >= 3) userSearchParams.search_term = searchTerm
  useContentShareUserSearchApi({
    courseId,
    success: setSearchedUsers,
    error: setError,
    loading: setIsLoading,
    params: userSearchParams
  })

  function handleUserSelected(_ev, id) {
    if (searchedUsers === null) return
    const user = searchedUsers.find(u => u.id === id)
    onUserSelected(user)
    setInputValue('')
  }

  function handleInputChanged(ev) {
    setInputValue(ev.target.value)
    setSearchTerm(ev.target.value)
  }

  if (error !== null) throw error

  const noOptionsLabel = isSearchableTerm(inputValue)
    ? I18n.t('No Results')
    : I18n.t('Enter at least %{count} characters', {count: MINIMUM_SEARCH_LENGTH})

  const selectProps = {
    inputValue,
    isLoading: isLoading || searchTermIsPending,
    renderLabel: I18n.t('Send to:'),
    assistiveText: I18n.t('Enter at least %{count} characters', {count: MINIMUM_SEARCH_LENGTH}),
    placeholder: I18n.t('Begin typing to search'),
    noOptionsLabel,
    onInputChange: handleInputChanged,
    onOptionSelected: handleUserSelected
  }

  let userOptions = []
  if (searchedUsers !== null && isSearchableTerm(inputValue)) {
    const selectedUsersIds = selectedUsers.map(user => user.id)
    userOptions = searchedUsers
      .filter(user => !selectedUsersIds.includes(user.id))
      .map(user => (
        <CanvasAsyncSelect.Option key={user.id} id={user.id} value={user.id}>
          <UserSearchSelectorItem user={user} />
        </CanvasAsyncSelect.Option>
      ))
  }

  return (
    <CanvasAsyncSelect {...restOfSelectProps} {...selectProps}>
      {userOptions}
    </CanvasAsyncSelect>
  )
}
