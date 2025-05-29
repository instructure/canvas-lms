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

import React, {useCallback, useEffect, useRef, useState} from 'react'
import UserDateRangeSearch from '../UserDateRangeSearch'
import {TextInput} from '@instructure/ui-text-input'
import {Avatar} from '@instructure/ui-avatar'
import {Link, type LinkProps} from '@instructure/ui-link'
import {Alert} from '@instructure/ui-alerts'
import {Table} from '@instructure/ui-table'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import {IconSearchLine} from '@instructure/ui-icons'
import {useDebouncedCallback} from 'use-debounce'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {FormMessage, MessagesQueryParams, User} from './types'
import {useInfiniteQuery, type QueryFunctionContext, type InfiniteData} from '@tanstack/react-query'

const I18n = createI18nScope('comm_messages')

type FetchReturn = {
  users: User[]
  nextPage: string | null
}

type UserQueryKey = ['users', string, string]

type APIQueryParams = {
  page: string
  per_page: string
  search_term: string
  include: string[]
  sort: 'sortable_name'
}

type LinkClick = NonNullable<LinkProps['onClick']>

async function fetchUsers({
  queryKey,
  pageParam,
}: QueryFunctionContext<UserQueryKey, string>): Promise<FetchReturn> {
  const [_, accountId, searchTerm] = queryKey
  const params: APIQueryParams = {
    page: pageParam,
    per_page: '10',
    search_term: searchTerm,
    include: ['avatar_url'],
    sort: 'sortable_name',
  }
  const path = `/api/v1/accounts/${accountId}/users`
  const {json, link} = await doFetchApi<Array<User>>({path, params})
  if (typeof json === 'undefined') return {users: [], nextPage: null}
  const nextPage = link?.next ? link.next.page : null
  return {users: json, nextPage}
}

interface UsersTableDisplayProps {
  enclosingDiv: React.RefObject<HTMLDivElement>
  data: InfiniteData<FetchReturn>
  onUserSelect: (user: User) => void
  isTriggerRow: (row: number, lastRow: number) => boolean
  onFetchNextPage: () => void
}

function UsersTableDisplay(props: UsersTableDisplayProps): JSX.Element {
  const {data, onUserSelect, isTriggerRow, onFetchNextPage, enclosingDiv} = props
  const observerRef = useRef<IntersectionObserver | null>(null)
  const viewUsers: Record<string, User> = {}

  function bySortableName(a: string, b: string) {
    const userA = viewUsers[a]
    const userB = viewUsers[b]
    return userA.sortable_name.localeCompare(userB.sortable_name, ENV.LOCALES, {numeric: true})
  }

  function clearPageLoadTrigger() {
    if (observerRef.current === null) return
    observerRef.current.disconnect()
    observerRef.current = null
  }

  function setPageLoadTrigger(ref: Element | null) {
    if (ref === null) return
    clearPageLoadTrigger()
    observerRef.current = new IntersectionObserver(
      function (entries) {
        if (entries[0].isIntersecting) {
          onFetchNextPage()
          clearPageLoadTrigger()
        }
      },
      {
        root: enclosingDiv.current,
        rootMargin: '0px',
        threshold: 0,
      },
    )
    observerRef.current.observe(ref)
  }

  const handleClick: LinkClick = function ({target}) {
    if (target instanceof HTMLElement && target.dataset.userId)
      onUserSelect(viewUsers[target.dataset.userId])
  }

  // occasionally the API returns duplicate results across pages, so we need
  // coalesce those into one; this is the easiest way.
  data.pages.forEach(page => {
    page.users.forEach(user => {
      viewUsers[user.id] = user
    })
  })
  const keys = Object.keys(viewUsers).sort(bySortableName)
  const setTrigger = (row: number) =>
    isTriggerRow(row, keys.length - 1)
      ? (ref: Element | null) => setPageLoadTrigger(ref)
      : undefined

  if (keys.length === 0) return <></>

  return (
    <View margin="sectionElements none" as="div">
      <Table caption={I18n.t('Search results')}>
        <Table.Head>
          <Table.Row>
            <Table.ColHeader id="user-list-name">{I18n.t('Name')}</Table.ColHeader>
            <Table.ColHeader id="user-list-login-id">{I18n.t('Login / SIS ID')}</Table.ColHeader>
          </Table.Row>
        </Table.Head>
        <Table.Body>
          {keys.map((id, idx) => {
            const user = viewUsers[id]
            const userLink = (
              <Link onClick={handleClick} data-user-id={id} elementRef={setTrigger(idx)}>
                <Avatar
                  name={user.name}
                  src={user.avatar_url}
                  size="x-small"
                  margin="0 x-small xxx-small 0"
                  data-fs-exclude={true}
                />
                {user.name}
              </Link>
            )
            return (
              <Table.Row key={id}>
                <Table.RowHeader>{userLink}</Table.RowHeader>
                <Table.Cell>{user.login_id}</Table.Cell>
              </Table.Row>
            )
          })}
        </Table.Body>
      </Table>
    </View>
  )
}

export interface CommMessageUserListProps {
  accountId: string
  onUserAndDateSelected: (selection: MessagesQueryParams | null) => void
}

export default function CommMessageUserList({
  accountId,
  onUserAndDateSelected,
}: CommMessageUserListProps): JSX.Element {
  const [searchTerm, setSearchTerm] = useState<string>('')
  const [selectedUser, setSelectedUser] = useState<User | null>(null)
  const [firstUse, setFirstUse] = useState<boolean>(true)
  const [messages, setMessages] = useState<FormMessage[]>([])
  const userListDivRef = useRef<HTMLDivElement | null>(null)
  const [debouncedSetSearchTerm] = useDebouncedCallback((s: string) => {
    setSearchTerm(s)
    onUserAndDateSelected(null)
    if (firstUse) setFirstUse(false)
  }, 500)

  const {
    data,
    fetchNextPage,
    isPending,
    isFetching,
    isFetchingNextPage,
    hasNextPage,
    isSuccess,
    error,
  } = useInfiniteQuery<FetchReturn, Error, InfiniteData<FetchReturn>, UserQueryKey, string>({
    queryKey: ['users', accountId, searchTerm],
    queryFn: fetchUsers,
    staleTime: 1000 * 60 * 10, // 10 minutes should be safe, user lists are not updated much
    getNextPageParam: lastPage => lastPage.nextPage,
    initialPageParam: '1',
    enabled: searchTerm.length >= 3,
  })

  // Make sure the messages under the search input are kept up to date
  useEffect(() => {
    const messages: FormMessage[] = []
    const l = searchTerm.length
    if (l < 3)
      messages.push({
        type: firstUse || l > 0 ? 'hint' : 'newError',
        text: I18n.t('Enter at least 3 characters to search'),
      })
    const noResults: boolean = !data?.pages.some(page => page.users.length > 0)
    if (noResults && l >= 3 && !isFetching)
      messages.push(
        {
          type: 'newError',
          text: I18n.t('No people found'),
        },
        {
          type: 'hint',
          text: I18n.t('You can search by Name or Login / SIS ID'),
        },
      )
    setMessages(messages)
  }, [searchTerm, data, firstUse, isFetching])

  function handleSearchChange(_e: any, v: string) {
    debouncedSetSearchTerm(v)
  }

  const isTriggerRow = (row: number, lastRow: number) =>
    row === lastRow && hasNextPage && !isFetching

  const handleUserSelected = useCallback(
    function (user: User) {
      onUserAndDateSelected(null)
      setSelectedUser(user)
    },
    [onUserAndDateSelected],
  )

  function handleRangeSelected(data: {from?: string; to?: string}) {
    onUserAndDateSelected({
      userId: selectedUser!.id,
      userName: selectedUser!.name,
      startTime: data.from,
      endTime: data.to,
    })
    handleModalClose()
  }

  function handleModalClose() {
    setSelectedUser(null)
  }

  function setListRef(elt: Element | null) {
    userListDivRef.current = elt as HTMLDivElement
  }

  function renderList() {
    if (isPending && !isFetching) return <></>
    if (isFetching && !isFetchingNextPage) return <Spinner renderTitle={I18n.t('Loading')} />
    if (!isSuccess) {
      // if we have an error, then the query failed, display an alert
      if (error)
        return (
          <Alert variant="error" margin="small">
            <strong>{I18n.t('Error loading users')}</strong>
          </Alert>
        )
      // otherwise the query is still loading / retrying / something else
      else return <Spinner renderTitle={I18n.t('Loading')} />
    }
    return (
      <>
        <UsersTableDisplay
          data={data}
          onUserSelect={handleUserSelected}
          onFetchNextPage={fetchNextPage}
          isTriggerRow={isTriggerRow}
          enclosingDiv={userListDivRef}
        />
        {isFetchingNextPage && <Spinner size="small" renderTitle={I18n.t('Loading more...')} />}
      </>
    )
  }

  return (
    <>
      <TextInput
        isRequired
        renderBeforeInput={<IconSearchLine />}
        margin="moduleElements none"
        renderLabel={I18n.t('Search for people by ID or name')}
        messages={messages}
        width="16rem"
        onChange={handleSearchChange}
        onBlur={() => setFirstUse(false)}
        data-testid="notifications-search-box"
      />
      <View
        as="div"
        margin="moduleElements none"
        maxHeight="400px"
        overflowY="auto"
        elementRef={setListRef}
      >
        {renderList()}
      </View>
      <UserDateRangeSearch
        isOpen={selectedUser !== null}
        userName={selectedUser?.name || ''}
        onSubmit={handleRangeSelected}
        onClose={handleModalClose}
      />
    </>
  )
}
