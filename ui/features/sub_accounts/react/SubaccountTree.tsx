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

const I18n = createI18nScope('sub_accounts')

interface Props {
  parentAccount?: AccountWithCounts
  handleParent?: (decreaseCount: boolean) => void
  rootAccount: AccountWithCounts
  indent: number
  isTopAccount: boolean
  parentExpanded?: boolean
}

export default function SubaccountTree(props: Props) {
  const subCount = useRef(props.rootAccount.sub_account_count)
  const {setFocusId, focusRef, overMax} = useFocusContext()
  const [showForm, setShowForm] = useState(false)
  const [isExpanded, setIsExpanded] = useState(!overMax && subCount.current > 0)
  const [hasFetched, setHasFetched] = useState(subCount.current < 1)

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
    setHasFetched(true)
    return {json: json as AccountWithCounts[], nextPage}
  }

  const {data, isFetching, isSuccess, hasNextPage, isFetchingNextPage, fetchNextPage, error} =
    useInfiniteQuery({
      queryKey: ['subAccountList', props.rootAccount.id],
      queryFn: context => fetchSubAccounts(context),
      getNextPageParam: lastPage => lastPage.nextPage,
      enabled: isExpanded && !hasFetched,
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
    setIsExpanded(!overMax && subCount.current > 0)
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

  const handleDelete = async (subaccounts: AccountWithCounts[]) => {
    const deleteMsg = I18n.t("Confirm deleting '%{name}'?", {name: props.rootAccount.name})
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
    } else if (window.confirm(deleteMsg)) {
      await deleteAccount()
    }
  }

  const renderRoot = (subaccounts: AccountWithCounts[]) => {
    const show = props.parentExpanded != null ? props.parentExpanded : true
    return (
      <SubaccountItem
        account={{...props.rootAccount, sub_account_count: subCount.current}}
        indent={props.indent}
        onExpand={() => setIsExpanded(true)}
        onCollapse={() => {
          setShowForm(false)
          setIsExpanded(false)
        }}
        onAdd={() => {
          setShowForm(true)
          setIsExpanded(true)
        }}
        onDelete={() => handleDelete(subaccounts)}
        onEditSaved={() => {
          if (props.handleParent) {
            props.handleParent(false)
          } else {
            queryClient.invalidateQueries(['account', props.rootAccount.id])
          }
        }}
        isExpanded={isExpanded}
        canDelete={!props.isTopAccount}
        show={show}
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
            setHasFetched(false)
            resetQuery(props.rootAccount.id)
          }}
          indent={props.indent + 1}
          isTopAccount={false}
          parentExpanded={parentExpanded}
        />
      )
    })
    return childTree
  }

  const childIndent = calculateIndent(props.indent + 1)
  if (error) {
    return (
      <Flex>
        <Flex.Item width={`${childIndent}%`} />
        <Flex.Item align="center">
          <Alert variant="error">{I18n.t('Failed loading subaccounts')}</Alert>
        </Flex.Item>
      </Flex>
    )
  } else if ((isFetching && !isFetchingNextPage) || (data == null && !hasFetched && isExpanded)) {
    return (
      <Flex>
        <Flex.Item width={`${childIndent}%`} />
        <Flex.Item>
          <Spinner renderTitle={I18n.t('Loading subaccounts')} />
        </Flex.Item>
      </Flex>
    )
  } else {
    const subaccounts = data?.pages.flatMap(page => page.json) || []
    // we only want to do this if the query was made
    if (hasFetched && subCount.current !== subaccounts.length && !isFetchingNextPage) {
      subCount.current = subaccounts.length
    }
    const parentExpanded =
      props.parentExpanded != null ? props.parentExpanded && isExpanded : isExpanded
    return (
      <>
        {renderRoot(subaccounts)}
        {renderChildren(subaccounts, parentExpanded)}
        {isFetchingNextPage ? (
          <Flex>
            <Flex.Item width={`${childIndent}%`} />
            <Flex.Item>
              <Spinner renderTitle={I18n.t('Loading subaccounts')} />
            </Flex.Item>
          </Flex>
        ) : null}
        {parentExpanded && showForm ? (
          <SubaccountNameForm
            accountName={''}
            accountId={props.rootAccount.id}
            onSuccess={() => {
              subCount.current++
              setHasFetched(false)
              setShowForm(false)
              resetQuery(props.rootAccount.id)
            }}
            onCancel={() => setShowForm(false)}
            indent={props.indent + 1}
          />
        ) : null}
      </>
    )
  }
}
