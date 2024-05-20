/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {Avatar} from '@instructure/ui-avatar'
import {debounce} from '@instructure/debounce'
import {Flex} from '@instructure/ui-flex'
import {IconButton} from '@instructure/ui-buttons'
import {IconProgressLine, IconSearchLine, IconTrashLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Select} from '@instructure/ui-select'
import {Spinner} from '@instructure/ui-spinner'
import {Table} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import useFetchApi from '@canvas/use-fetch-api-hook'
import type {CanvasUserSearchResultType, PathwayUserShareType} from '../../../../types'

const MIN_SEARCH_TERM_LENGTH = 2
const SEARCH_DEBOUNCE_MS = 750

type CanvasUserFinderProps = {
  selectedUsers: PathwayUserShareType[]
  onChange: (newSelectedUsers: PathwayUserShareType[]) => void
}

const CanvasUserFinder = ({selectedUsers, onChange}: CanvasUserFinderProps) => {
  const [searchTerm, setSearchTerm] = useState<string>('')
  const [debouncedSearchterm, setDebouncedSearchTerm] = useState<string>('_') // will cause a 400 on the first fetch
  const [searchResults, setSearchResults] = useState<PathwayUserShareType[] | null>(null)
  const [currSelectedUsers, setCurrSelectedUsers] = useState<PathwayUserShareType[]>(selectedUsers)

  const [inFlight, setInFlight] = useState<boolean>(false)
  const [showSearchResults, setShowSearchResults] = useState<boolean>(false)
  const [highlightedOptionId, setHighlightedOptionId] = useState<string | null>(null)

  const isLoading = useCallback((loading: boolean) => {
    setInFlight(loading)
  }, [])

  // this will fetch when the component is first mounted, but
  // the controller will return immediately a 400 since debouncedSearchterm is empty
  useFetchApi(
    {
      path: `/users/${ENV.current_user.id}/passport/data/pathways/share_users`, // `/api/v1/accounts/${ENV.ACCOUNT_ID}/users`,
      params: {
        search_term: debouncedSearchterm,
      },
      success: useCallback((results: CanvasUserSearchResultType[]) => {
        if (results === undefined) {
          setSearchResults(null)
        } else {
          const shares: PathwayUserShareType[] = results.map(r => {
            return {
              id: r.id,
              name: r.name,
              role: 'viewer',
              sortable_name: r.sortable_name,
              avatar_url: r.avatar_url,
            }
          })
          // strip unwanted fields
          setSearchResults(shares || [])
          setShowSearchResults(true)
        }
      }, []),
      error: useCallback(() => {
        // this will happen on the first fetch, since debouncedSearchterm < 2 chars long
        setSearchResults(null)
      }, []),
      loading: isLoading,
      meta: undefined,
      convert: undefined,
      forceResult: undefined,
    },
    [debouncedSearchterm]
  )

  useEffect(() => {
    setDebouncedSearchTerm('_')
    setSearchTerm('')
    setSearchResults(null)
  }, [])

  const deferSetDebouncedSearchTerm = useCallback(
    debounce(
      (value: string) => {
        if (value.length < MIN_SEARCH_TERM_LENGTH) return
        setDebouncedSearchTerm(value)
      },
      SEARCH_DEBOUNCE_MS,
      {leading: false, trailing: true}
    ),
    []
  )

  const handleChangeSearchValue = useCallback(
    (_event, value) => {
      setSearchTerm(value)
      deferSetDebouncedSearchTerm(value)
      if (value.trim().length < MIN_SEARCH_TERM_LENGTH) {
        setSearchResults(null)
      }
    },
    [deferSetDebouncedSearchTerm]
  )

  const handleShowOptions = useCallback(() => {
    setShowSearchResults(true)
  }, [])

  const handleHideOptions = useCallback(() => {
    setShowSearchResults(false)
    setHighlightedOptionId(null)
  }, [])

  const handleHighlightOption = useCallback((_event, {id}) => {
    setHighlightedOptionId(id)
  }, [])

  const handleSelectOption = useCallback(
    (_event, {id}) => {
      const newSelection = searchResults?.find(r => r.id === id)
      const currSelectionIndex = currSelectedUsers.findIndex(u => u.id === id)
      const newSelectedUsers = [...currSelectedUsers]
      if (currSelectionIndex >= 0) {
        newSelectedUsers.splice(currSelectionIndex, 1)
      } else if (newSelection) {
        newSelectedUsers.push(newSelection)
      }
      setCurrSelectedUsers(newSelectedUsers)
      onChange(newSelectedUsers)
      setShowSearchResults(false)
    },
    [currSelectedUsers, onChange, searchResults]
  )

  const handleChangeUserRole = useCallback(
    (userId: string, role) => {
      const newSelectedUsers = [...currSelectedUsers]
      const userIndex = newSelectedUsers.findIndex(u => u.id === userId)
      if (userIndex >= 0) {
        newSelectedUsers[userIndex].role = role
        setCurrSelectedUsers(newSelectedUsers)
        onChange(newSelectedUsers)
      }
    },
    [currSelectedUsers, onChange]
  )

  const renderSelection = () => {
    return (
      <Table caption="Selected Users">
        <Table.Head>
          <Table.Row>
            <Table.ColHeader id="name">User</Table.ColHeader>
            <Table.ColHeader id="role">Role</Table.ColHeader>
            <Table.ColHeader id="action" width="40px">
              <ScreenReaderContent>Action</ScreenReaderContent>
            </Table.ColHeader>
          </Table.Row>
        </Table.Head>
        <Table.Body>
          {currSelectedUsers
            .sort((a, b) => a.sortable_name.localeCompare(b.sortable_name))
            .map(user => {
              return (
                <Table.Row key={user.id}>
                  <Table.Cell>
                    <Flex gap="x-small">
                      <Flex.Item shouldGrow={false} shouldShrink={false}>
                        <Avatar name={user.name} src={user.avatar_url} size="xx-small" />
                      </Flex.Item>
                      <Flex.Item shouldGrow={true} shouldShrink={true} wrap="wrap">
                        {user.name}
                      </Flex.Item>
                    </Flex>
                  </Table.Cell>
                  <Table.Cell>
                    <SimpleSelect
                      renderLabel={<ScreenReaderContent>select a role</ScreenReaderContent>}
                      value={user.role}
                      width="9rem"
                      onChange={(_event, {value}) => handleChangeUserRole(user.id, value)}
                    >
                      <SimpleSelect.Option id="role-collaborator" value="collaborator">
                        Collaborator
                      </SimpleSelect.Option>
                      <SimpleSelect.Option id="role-reviewer" value="reviewer">
                        Reviewer
                      </SimpleSelect.Option>
                      <SimpleSelect.Option id="role-viewer" value="viewer">
                        Viewer
                      </SimpleSelect.Option>
                    </SimpleSelect>
                  </Table.Cell>
                  <Table.Cell>
                    <IconButton
                      screenReaderLabel={`Remove ${user.name}`}
                      withBackground={false}
                      withBorder={false}
                      onClick={() => {
                        const newSelectedUsers = currSelectedUsers.filter(u => u.id !== user.id)
                        setCurrSelectedUsers(newSelectedUsers)
                        onChange(newSelectedUsers)
                      }}
                      size="small"
                    >
                      <IconTrashLine size="x-small" />
                    </IconButton>
                  </Table.Cell>
                </Table.Row>
              )
            })}
        </Table.Body>
      </Table>
    )
  }

  const renderOptions = () => {
    if (inFlight) {
      return (
        <Select.Option id="empty-option" key="empty-option">
          <Spinner renderTitle="Loading" size="x-small" />
        </Select.Option>
      )
    }
    if (searchResults) {
      if (searchResults.length > 0) {
        return searchResults.map(result => {
          return (
            <Select.Option
              key={result.id}
              id={result.id}
              isHighlighted={highlightedOptionId === result.id}
              isSelected={!!currSelectedUsers.find(u => u.id === result.id)}
            >
              {result.name}
            </Select.Option>
          )
        })
      } else {
        return (
          <Select.Option id="empty-option" key="empty-option">
            No matches found
          </Select.Option>
        )
      }
    } else {
      return (
        <Select.Option id="empty-option" key="empty-option">
          ---
        </Select.Option>
      )
    }
  }

  return (
    <View as="div">
      <Select
        renderLabel={
          <>
            <Text as="div" weight="bold">
              Share
            </Text>
            <Text as="div" weight="normal" lineHeight="double" size="small">
              Add users to collaborate on, review, or view the pathway.
            </Text>
          </>
        }
        placeholder="Search for users"
        renderBeforeInput={inFlight ? <IconProgressLine /> : <IconSearchLine />}
        isShowingOptions={showSearchResults}
        inputValue={searchTerm}
        onInputChange={handleChangeSearchValue}
        onRequestShowOptions={handleShowOptions}
        onRequestHideOptions={handleHideOptions}
        onRequestHighlightOption={handleHighlightOption}
        onRequestSelectOption={handleSelectOption}
      >
        {renderOptions()}
      </Select>
      <View as="div" margin="medium 0 0 0">
        {renderSelection()}
      </View>
    </View>
  )
}

export default CanvasUserFinder
