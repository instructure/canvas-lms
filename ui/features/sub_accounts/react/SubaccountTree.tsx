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

import doFetchApi from '@canvas/do-fetch-api-effect'
import {Alert} from '@instructure/ui-alerts'
import React, {useEffect, useRef, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Spinner} from '@instructure/ui-spinner'
import SubaccountItem from './SubaccountItem'
import {AccountWithCounts} from './types'
import {Flex} from '@instructure/ui-flex'
import SubaccountNameForm from './SubaccountNameForm'
import {calculateIndent, resetQuery, useFocusContext} from './util'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {QueryFunctionContext, useInfiniteQuery} from '@tanstack/react-query'
import {queryClient} from '@canvas/query'
import DeleteSubaccountModal from './DeleteSubaccountModal'

const I18n = createI18nScope('sub_accounts')

interface Props {
  parentAccount?: AccountWithCounts
  handleParent?: (decreaseCount: boolean) => void
  rootAccount: AccountWithCounts
  depth: number
  parentExpanded?: boolean
}

export default function SubaccountTree(props: Props) {
  const subCount = useRef(props.rootAccount.sub_account_count)
  const {setFocusId, focusRef, overMax} = useFocusContext()
  const [showForm, setShowForm] = useState(false)
  const [isExpanded, setIsExpanded] = useState(!overMax && subCount.current > 0 && props.depth < 3)
  const [displayConfirmation, setDisplayConfirmation] = useState(false)

  const fetchSubAccounts = async (
    context: QueryFunctionContext,
  ): Promise<{json: AccountWithCounts[]; nextPage: string | null}> => {
    const params = {
      per_page: '100',
      page: context.pageParam || '1',
      include: ['course_count', 'sub_account_count'],
    }
    const {json, link} = await doFetchApi({
      path: `/api/v1/accounts/${props.rootAccount.id}/sub_accounts`,
      method: 'GET',
      params,
    })
    const nextPage = link?.next ? link.next.page : null
    return {json: json as AccountWithCounts[], nextPage}
  }

  const {
    data,
    isFetching,
    isLoading,
    isSuccess,
    hasNextPage,
    isFetchingNextPage,
    fetchNextPage,
    error,
  } = useInfiniteQuery({
    queryKey: ['subAccountList', props.rootAccount.id],
    queryFn: context => fetchSubAccounts(context),
    getNextPageParam: lastPage => lastPage.nextPage,
    enabled: isExpanded && subCount.current > 0,
  })

  // set focus ref after completing re-fetch
  useEffect(() => {
    if (isSuccess && focusRef) {
      focusRef.focus()
    }
  }, [isSuccess, focusRef])

  // fetch more accounts if available
  useEffect(() => {
    if (!isFetching && hasNextPage) {
      fetchNextPage()
    }
  }, [isFetchingNextPage, isFetching, fetchNextPage, hasNextPage])

  // should only trigger when overMax is set at the start
  // otherwise, adding/deleting will effect expanded/collapsed state
  // of the tree
  useEffect(() => {
    setIsExpanded(!overMax && subCount.current > 0 && props.depth < 3)
  }, [overMax])

  const deleteAccount = async () => {
    await doFetchApi({
      path: `/accounts/${props.parentAccount?.id}/sub_accounts/${props.rootAccount.id}`,
      method: 'DELETE',
    })
    if (props.handleParent) {
      props.handleParent(true)
    }
  }

  const handleDelete = () => {
    if (subCount.current > 0) {
      showFlashAlert({
        message: I18n.t('You cannot delete accounts with active subaccounts'),
        type: 'warning',
      })
    } else if (props.rootAccount.course_count > 0) {
      showFlashAlert({
        message: I18n.t('You cannot delete accounts with active courses'),
        type: 'warning',
      })
    } else {
      setDisplayConfirmation(true)
    }
  }

  const renderRoot = (showRoot: boolean) => {
    const show = props.parentExpanded != null ? props.parentExpanded : true
    return (
      <SubaccountItem
        account={{...props.rootAccount, sub_account_count: subCount.current}}
        depth={props.depth}
        onExpand={() => setIsExpanded(true)}
        onCollapse={() => {
          setShowForm(false)
          setIsExpanded(false)
        }}
        onAdd={() => {
          setShowForm(true)
          setIsExpanded(true)
        }}
        onDelete={handleDelete}
        onEditSaved={() => {
          if (props.handleParent) {
            props.handleParent(false)
          } else {
            queryClient.invalidateQueries(['account', props.rootAccount.id])
          }
        }}
        isExpanded={isExpanded}
        canDelete={props.depth != 1}
        show={show && showRoot}
      />
    )
  }

  const renderChildren = (subaccounts: AccountWithCounts[], parentExpanded: boolean) => {
    const childTree = subaccounts.map((account: AccountWithCounts) => {
      return (
        <SubaccountTree
          key={`${account.id}_tree`}
          rootAccount={account}
          parentAccount={{...props.rootAccount, sub_account_count: subCount.current}}
          handleParent={(decreaseCount: boolean) => {
            if (decreaseCount) {
              subCount.current--
              setFocusId(props.rootAccount.id)
            }
            resetQuery(props.rootAccount.id)
          }}
          depth={props.depth + 1}
          parentExpanded={parentExpanded}
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

  const childIndent = calculateIndent(props.depth + 1)
  if (error) {
    return (
      <Flex>
        <Flex.Item width={`${childIndent}%`} />
        <Flex.Item align="center">
          <Alert variant="error">{I18n.t('Failed loading subaccounts')}</Alert>
        </Flex.Item>
      </Flex>
    )
  } else if (isLoading && !isFetching && !showForm) {
    return (
      <>
        {renderRoot(true)}
        {displayConfirmation ? renderDeleteConfirmation() : null}
      </>
    )
  } else {
    const subaccounts = data?.pages.flatMap(page => page.json) || []
    const showSpinner = isFetching && !isFetchingNextPage
    // we only want to do this if the query was made
    if (subCount.current !== subaccounts.length && !isFetching) {
      subCount.current = subaccounts.length
    }
    const parentExpanded =
      props.parentExpanded != null ? props.parentExpanded && isExpanded : isExpanded
    const spinnerSize = props.depth === 1 ? 'medium' : 'small'
    return (
      <>
        {showSpinner ? (
          <Flex>
            <Flex.Item width={`${childIndent}%`} />
            <Flex.Item>
              <Spinner size={spinnerSize} renderTitle={I18n.t('Loading subaccounts')} />
            </Flex.Item>
          </Flex>
        ) : null}
        {renderRoot(!showSpinner)}
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
        {parentExpanded && showForm ? (
          <SubaccountNameForm
            accountName={''}
            accountId={props.rootAccount.id}
            onSuccess={() => {
              subCount.current++
              setShowForm(false)
              resetQuery(props.rootAccount.id)
            }}
            onCancel={() => setShowForm(false)}
            depth={props.depth + 1}
          />
        ) : null}
      </>
    )
  }
}
