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

import {useScope as useI18nScope} from '@canvas/i18n'
import React, {useState} from 'react'
import CanvasAsyncSelect, {
  type CanvasAsyncSelectProps,
} from '@canvas/instui-bindings/react/AsyncSelect'
import useDebouncedSearchTerm from '@canvas/search-item-selector/react/hooks/useDebouncedSearchTerm'
import useContentShareUserSearchApi from '../effects/useContentShareUserSearchApi'
import UserSearchSelectorItem from './UserSearchSelectorItem'

const I18n = useI18nScope('user_search_selector')

ContentShareUserSearchSelector.defaultProps = {
  selectedUsers: [],
}

const MINIMUM_SEARCH_LENGTH = 3

const isSearchableTerm = (term: string) => term.length >= MINIMUM_SEARCH_LENGTH

type BasicUser = {
  id: string
  name: string
  avatar_url?: string
  email?: string
}

type Props = {
  courseId: string
  onUserSelected: (user: any) => void
  selectedUsers: BasicUser[]
} & Omit<CanvasAsyncSelectProps, 'renderLabel'>

export default function ContentShareUserSearchSelector({
  courseId,
  onUserSelected,
  selectedUsers,
  ...restOfSelectProps
}: Props) {
  const [searchedUsers, setSearchedUsers] = useState<BasicUser[] | null>(null)
  const [error, setError] = useState(null)
  const [inputValue, setInputValue] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const {searchTerm, setSearchTerm, searchTermIsPending} = useDebouncedSearchTerm('', {
    isSearchableTerm,
  })

  const userSearchParams: {
    search_term?: string
  } = {}
  if (searchTerm.length >= 3) userSearchParams.search_term = searchTerm
  useContentShareUserSearchApi({
    courseId,
    success: setSearchedUsers,
    error: setError,
    loading: setIsLoading,
    params: userSearchParams,
  })

  function handleUserSelected(_ev: React.MouseEvent<HTMLButtonElement>, id: string) {
    if (searchedUsers === null) return
    const user = searchedUsers.find(u => u.id === id)
    onUserSelected(user)
    setInputValue('')
  }

  function handleInputChanged(ev: React.ChangeEvent<HTMLInputElement>) {
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
    onOptionSelected: handleUserSelected,
  }

  let userOptions: any = []
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
