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

import doFetchApi, {FetchApiError} from '@canvas/do-fetch-api-effect'
import {Alert} from '@instructure/ui-alerts'
import React, {useCallback, useContext, useEffect, useMemo, useRef, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Spinner} from '@instructure/ui-spinner'
import SubaccountItem from './SubaccountItem'
import type {AccountWithCounts, SubaccountQueryKey} from './types'
import {Flex} from '@instructure/ui-flex'
import SubaccountNameForm from './SubaccountNameForm'
import {
  calculateIndent,
  getSubAccounts,
  FetchSubAccountsResponse,
  generateQueryKey,
  SubaccountContext,
} from './util'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {queryClient} from '@canvas/query'
import DeleteSubaccountModal from './DeleteSubaccountModal'
import {InfiniteData, useInfiniteQuery} from '@tanstack/react-query'

const I18n = createI18nScope('sub_accounts')

// if any account has over 100 subaccounts
// we will not auto expand themselves or their children
// this also applies to top-level accounts
const THRESHOLD_FOR_AUTO_EXPAND = 100
const RATE_LIMIT_REFETCH_INTERVAL = 20_000 // 20 seconds
type ModifyType = 'delete' | 'edit' | 'add'

interface Props {
  parentAccount?: AccountWithCounts
  handleParent?: (account: AccountWithCounts, modifyType: ModifyType) => void
  rootAccount: AccountWithCounts
  depth: number
  parentExpanded?: boolean
  defaultExpanded: boolean
  isFocus?: boolean
}

export default function SubaccountTree(props: Props) {
  const defaultExpanded = useRef(false)
  const newSubaccount = useRef('')
  const observerRef = useRef<IntersectionObserver | null>(null)
  const [isEnabled, setIsEnabled] = useState(false)
  const [hasFocus, setHasFocus] = useState(props.isFocus || false)
  const [subCount, setSubCount] = useState(props.rootAccount.sub_account_count || 0)
  const [subaccounts, setSubaccounts] = useState([] as AccountWithCounts[])
  const [showForm, setShowForm] = useState(false)
  const [isExpanded, setIsExpanded] = useState(false)
  const [displayConfirmation, setDisplayConfirmation] = useState(false)

  const queue = useContext(SubaccountContext)

  const {
    data,
    isFetching,
    isLoading,
    fetchNextPage,
    isFetchingNextPage,
    hasNextPage,
    error,
    promise,
  } = useInfiniteQuery<
    FetchSubAccountsResponse,
    unknown,
    InfiniteData<FetchSubAccountsResponse>,
    SubaccountQueryKey
  >({
    queryKey: generateQueryKey(props.rootAccount.id, props.depth),
    queryFn: getSubAccounts,
    getNextPageParam: (lastPage: {nextPage: any}) => lastPage.nextPage,
    enabled: isExpanded && isEnabled,
    staleTime: 10 * 60 * 1000, // 10 minutes
    initialPageParam: '1',
    refetchInterval: query => {
      if (
        query.state.error &&
        query.state.error instanceof FetchApiError &&
        query.state.error.response.status === 403
      ) {
        // this is a rate limit error; let's wait and refetch in 20 seconds
        return RATE_LIMIT_REFETCH_INTERVAL
      } else {
        return false
      }
    },
  })

  useEffect(() => {
    if (isEnabled || !queue || subCount < 1 || !isExpanded) return
    queue?.addItem(async () => {
      if (!isEnabled) {
        setIsEnabled(true)
      }
      // 10 second timeout to prevent the queue from getting stuck
      // this query can still resolve, even after the timeout occurs
      const timeout = new Promise<void>((resolve, _reject) =>
        setTimeout(() => {
          resolve()
        }, 10_000),
      )
      await Promise.race([promise, timeout])
    })

    // only run this effect when we expand the tree
    // isExpand defaults to false until checked
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isExpanded])

  useEffect(() => {
    if (!isFetching && data != null) {
      const subaccounts =
        data.pages.reduce((acc: AccountWithCounts[], page: {json: AccountWithCounts[]}) => {
          return acc.concat(page.json)
        }, [] as AccountWithCounts[]) || []
      setSubaccounts(subaccounts || [])
      if (!hasNextPage) {
        setSubCount(subaccounts.length)
      }
    }
  }, [data, hasNextPage, isFetching])

  useEffect(() => {
    const count = subCount
    const expandByDefault =
      count < THRESHOLD_FOR_AUTO_EXPAND && count > 0 && props.depth < 3 && props.defaultExpanded
    if (expandByDefault) {
      setIsExpanded(true)
      defaultExpanded.current = true
    }
  }, [props.depth, props.defaultExpanded, subCount])

  const deleteAccount = async () => {
    await doFetchApi({
      path: `/accounts/${props.parentAccount?.id}/sub_accounts/${props.rootAccount.id}`,
      method: 'DELETE',
    })
    if (props.handleParent) {
      props.handleParent(props.rootAccount, 'delete')
    }
  }

  const handleCollapse = useCallback(() => {
    setShowForm(false)
    setIsExpanded(false)
    setHasFocus(false)
  }, [])

  const handleExpand = useCallback(() => {
    setIsExpanded(true)
    setHasFocus(false)
  }, [])

  const handleDelete = useCallback(() => {
    if (subCount > 0) {
      showFlashAlert({
        message: I18n.t('You cannot delete accounts with active subaccounts'),
        type: 'warning',
      })
    } else if (props.rootAccount.course_count || 0 > 0) {
      showFlashAlert({
        message: I18n.t('You cannot delete accounts with active courses'),
        type: 'warning',
      })
    } else {
      setDisplayConfirmation(true)
    }
  }, [props.rootAccount.course_count, subCount])

  const handleAdd = useCallback(() => {
    setShowForm(true)
    setIsExpanded(true)
    setHasFocus(false)
  }, [])

  const handleEdit = useCallback(
    (json: AccountWithCounts) => {
      if (props.handleParent) {
        props.handleParent(json, 'edit')
      } else {
        // root node should just be re-fetched
        queryClient.invalidateQueries({queryKey: ['account', props.rootAccount.id]})
      }
      setHasFocus(true)
    },
    // already exhaustive
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [props.handleParent, props.rootAccount],
  )

  const updateList = useCallback(
    (json: AccountWithCounts, modifyType: ModifyType) => {
      if (modifyType === 'delete') {
        // deleted
        setSubaccounts(subs => subs.filter(account => account.id !== json.id))
        setSubCount(count => count - 1)
        setHasFocus(true)
      } else if (modifyType === 'edit') {
        // updated
        setSubaccounts(subs =>
          subs.map(account => {
            if (account.id !== json.id) {
              return account
            } else {
              return json as AccountWithCounts
            }
          }),
        )
      } else {
        // adding
        setSubaccounts(subs => [...subs, json as AccountWithCounts])
        setSubCount(count => count + 1)
        newSubaccount.current = json.id
      }
      sessionStorage.removeItem(`subAccounts-${props.rootAccount.id}`)
    },
    [props.rootAccount.id],
  )

  const renderRoot = useMemo(() => {
    const show = props.parentExpanded != null ? props.parentExpanded : true
    return (
      <SubaccountItem
        account={{...props.rootAccount, sub_account_count: subCount}}
        depth={props.depth}
        onExpand={handleExpand}
        onCollapse={handleCollapse}
        onAdd={handleAdd}
        onDelete={handleDelete}
        onEditSaved={handleEdit}
        isExpanded={isExpanded}
        canDelete={props.depth != 1}
        show={show}
        isFocus={hasFocus}
      />
    )
  }, [
    props.rootAccount,
    props.parentExpanded,
    props.depth,
    subCount,
    handleExpand,
    handleCollapse,
    handleAdd,
    handleDelete,
    handleEdit,
    isExpanded,
    hasFocus,
  ])

  const renderChildren = (subaccounts: AccountWithCounts[], parentExpanded: boolean) => {
    const childTree = subaccounts.map((account: AccountWithCounts) => {
      let isFocus = false
      if (account.id === newSubaccount.current) {
        newSubaccount.current = ''
        isFocus = true
      }
      return (
        <SubaccountTree
          key={`${account.id}_tree`}
          rootAccount={account}
          parentAccount={{...props.rootAccount, sub_account_count: subCount}}
          handleParent={updateList}
          depth={props.depth + 1}
          parentExpanded={parentExpanded}
          defaultExpanded={defaultExpanded.current}
          isFocus={isFocus}
        />
      )
    })
    return childTree
  }

  const renderDeleteConfirmation = () => {
    return (
      <DeleteSubaccountModal
        account={props.rootAccount}
        onClose={() => setDisplayConfirmation(false)}
        onConfirm={async () => {
          await deleteAccount()
          setDisplayConfirmation(false)
        }}
      />
    )
  }

  function clearPageLoadTrigger() {
    if (observerRef.current === null) return
    observerRef.current.disconnect()
    observerRef.current = null
  }

  function setPageLoadTrigger(ref: Element | null) {
    if (ref === null) return
    clearPageLoadTrigger()
    observerRef.current = new IntersectionObserver(function (entries) {
      if (entries[0].isIntersecting) {
        fetchNextPage()
        clearPageLoadTrigger()
      }
    })
    observerRef.current.observe(ref)
  }

  const childIndent = calculateIndent(props.depth + 1)
  if (error) {
    return (
      <>
        {renderRoot}
        <Flex>
          <Flex.Item width={`${childIndent}%`} />
          <Flex.Item align="center">
            <Alert variant="error">{I18n.t('Failed loading subaccounts')}</Alert>
          </Flex.Item>
        </Flex>
      </>
    )
  } else if (isLoading && !isFetching && !showForm) {
    return (
      <>
        {renderRoot}
        {displayConfirmation ? renderDeleteConfirmation() : null}
      </>
    )
  } else {
    const showSpinner = isFetching && !isFetchingNextPage
    const parentExpanded =
      props.parentExpanded != null ? props.parentExpanded && isExpanded : isExpanded
    return (
      <>
        {renderRoot}
        {showSpinner ? (
          <Flex>
            <Flex.Item width={`${childIndent}%`} />
            <Flex.Item>
              <Spinner size="small" renderTitle={I18n.t('Loading subaccounts')} />
            </Flex.Item>
          </Flex>
        ) : null}
        {displayConfirmation ? renderDeleteConfirmation() : null}
        {renderChildren(subaccounts, parentExpanded)}
        {isFetchingNextPage ? (
          <Flex>
            <Flex.Item width={`${childIndent}%`} />
            <Flex.Item>
              <Spinner size="small" renderTitle={I18n.t('Loading subaccounts')} />
            </Flex.Item>
          </Flex>
        ) : null}
        {hasNextPage && !isFetchingNextPage ? <div ref={el => setPageLoadTrigger(el)}></div> : null}
        {parentExpanded && showForm ? (
          <SubaccountNameForm
            accountName={''}
            accountId={props.rootAccount.id}
            onSuccess={(json: AccountWithCounts) => {
              setShowForm(false)
              updateList(json, 'add')
            }}
            onCancel={() => setShowForm(false)}
            depth={props.depth + 1}
          />
        ) : null}
      </>
    )
  }
}
