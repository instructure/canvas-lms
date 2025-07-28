/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {forwardRef, useCallback, useImperativeHandle, useMemo, useRef, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import useContentShareUserSearchApi from '@canvas/direct-sharing/react/effects/useContentShareUserSearchApi'
import useDebouncedSearchTerm from '@canvas/search-item-selector/react/hooks/useDebouncedSearchTerm'
import CanvasAsyncSelect, {
  type CanvasAsyncSelectProps,
} from '@canvas/instui-bindings/react/AsyncSelect'

const MINIMUM_SEARCH_LENGTH = 3

const isSearchableTerm = (term: string) => term.length >= MINIMUM_SEARCH_LENGTH

export type BasicUser = {
  id: string
  name: string
  short_name: string
  sortable_name: string
  avatar_url?: string
  email?: string
  created_at: string
}

type ContentShareUserSearchSelectorProps = {
  courseId: string
  onUserSelected: (user?: BasicUser) => void
  selectedUsers: BasicUser[]
} & Omit<CanvasAsyncSelectProps, 'renderLabel' | 'inputRef' | 'messages' | 'isRequired'>

export type ContentShareUserSearchSelectorRef = {
  validate: () => boolean
}

const I18n = createI18nScope('files_v2')

const ContentShareUserSearchSelector = forwardRef<
  ContentShareUserSearchSelectorRef,
  ContentShareUserSearchSelectorProps
>(({courseId, onUserSelected, selectedUsers, ...restOfSelectProps}, ref) => {
  const inputRef = useRef<HTMLInputElement | null>(null)
  const [error, setError] = useState(null)
  const [searchedUsers, setSearchedUsers] = useState<BasicUser[] | null>(null)
  const [inputValue, setInputValue] = useState('')
  const [isLoading, setIsLoading] = useState(false)

  useImperativeHandle(ref, () => ({
    validate: () => {
      let valid = true
      if (selectedUsers.length === 0) {
        valid = false
        setError(I18n.t('At least one person should be selected'))
      }
      if (!valid) {
        inputRef.current?.focus()
      }
      return valid
    },
  }))

  const {searchTerm, setSearchTerm, searchTermIsPending} = useDebouncedSearchTerm('', {
    isSearchableTerm,
  })

  const userSearchParams = useMemo(() => {
    const params: {search_term?: string} = {}
    if (searchTerm.length >= MINIMUM_SEARCH_LENGTH) params.search_term = searchTerm
    return params
  }, [searchTerm])

  const setFetchError = useCallback(() => setError(I18n.t('Error retrieving users')), [])

  useContentShareUserSearchApi({
    courseId,
    success: setSearchedUsers,
    error: setFetchError,
    loading: setIsLoading,
    params: userSearchParams,
  })

  const handleUserSelected = useCallback(
    (_ev: React.MouseEvent<HTMLButtonElement>, id: string) => {
      if (searchedUsers === null) return
      const user = searchedUsers.find(u => u.id === id)
      onUserSelected(user)
      setInputValue('')
      setError(null)
    },
    [onUserSelected, searchedUsers],
  )

  const handleInputChanged = useCallback(
    (ev: React.ChangeEvent<HTMLInputElement>) => {
      setInputValue(ev.target.value)
      setSearchTerm(ev.target.value)
      setError(null)
    },
    [setSearchTerm],
  )

  const noOptionsLabel = useMemo(
    () =>
      isSearchableTerm(inputValue)
        ? I18n.t('No Results')
        : I18n.t('Enter at least %{count} characters', {count: MINIMUM_SEARCH_LENGTH}),
    [inputValue],
  )

  const selectProps = useMemo(
    () => ({
      inputValue,
      inputRef: (inputElement: HTMLInputElement | null) => {
        inputRef.current = inputElement
        // Removes the canvas default styles for invalid inputs
        inputElement?.removeAttribute('required')
      },
      isLoading: isLoading || searchTermIsPending,
      renderLabel: I18n.t('Select at least one person'),
      assistiveText: I18n.t('Enter at least %{count} characters', {count: MINIMUM_SEARCH_LENGTH}),
      placeholder: I18n.t('Begin typing to search'),
      noOptionsLabel,
      isRequired: true,
      messages: error ? [{text: error, type: 'newError'}] : [],
      onInputChange: handleInputChanged,
      onOptionSelected: handleUserSelected,
    }),
    [
      error,
      handleInputChanged,
      handleUserSelected,
      inputValue,
      isLoading,
      noOptionsLabel,
      searchTermIsPending,
    ],
  )

  const userOptions = useMemo(() => {
    if (searchedUsers === null || !isSearchableTerm(inputValue)) return []
    const selectedUsersIds = selectedUsers.map((user: BasicUser) => user.id)
    return searchedUsers
      .filter(user => !selectedUsersIds.includes(user.id))
      .map(user => (
        <CanvasAsyncSelect.Option key={user.id} id={user.id} value={user.id}>
          {user.name}
        </CanvasAsyncSelect.Option>
      ))
  }, [inputValue, searchedUsers, selectedUsers])

  return (
    <CanvasAsyncSelect {...restOfSelectProps} {...selectProps}>
      {userOptions}
    </CanvasAsyncSelect>
  )
})

export default ContentShareUserSearchSelector
