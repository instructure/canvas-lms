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
import type {AccountWithCounts} from './types'
import {Flex} from '@instructure/ui-flex'
import SubaccountNameForm from './SubaccountNameForm'
import {calculateIndent, fetchSubAccounts, useFocusContext} from './util'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {queryClient, useAllPages} from '@canvas/query'
import DeleteSubaccountModal from './DeleteSubaccountModal'

const I18n = createI18nScope('sub_accounts')

// if any account has over 100 subaccounts
// we will not auto expand themselves or their children
// this also applies to top-level accounts
const THRESHOLD_FOR_AUTO_EXPAND = 100

interface Props {
  parentAccount?: AccountWithCounts
  handleParent?: (account: AccountWithCounts, decreaseCount: boolean) => void
  rootAccount: AccountWithCounts
  depth: number
  parentExpanded?: boolean
}

export default function SubaccountTree(props: Props) {
  const subCount = useRef(props.rootAccount.sub_account_count || 0)
  const [subaccounts, setSubaccounts] = useState([] as AccountWithCounts[])
  const {focusId} = useFocusContext()
  const [showForm, setShowForm] = useState(false)
  const [isExpanded, setIsExpanded] = useState(false)
  const [displayConfirmation, setDisplayConfirmation] = useState(false)

  const {data, isFetching, isLoading, hasNextPage, isFetchingNextPage, error} = useAllPages({
    queryKey: ['subAccountList', props.rootAccount.id],
    queryFn: context => fetchSubAccounts(context),
    getNextPageParam: lastPage => lastPage.nextPage,
    enabled: isExpanded && subCount.current > 0,
  })

  useEffect(() => {
    if (!isFetching && data != null) {
      const subaccounts =
        data.pages.reduce((acc, page) => {
          return acc.concat(page.json)
        }, [] as AccountWithCounts[]) || []
      setSubaccounts(subaccounts)
    }
  }, [data, isFetching])

  useEffect(() => {
    setIsExpanded(
      subCount.current < THRESHOLD_FOR_AUTO_EXPAND && subCount.current > 0 && props.depth < 3,
    )
  }, [props.depth])

  const deleteAccount = async () => {
    await doFetchApi({
      path: `/accounts/${props.parentAccount?.id}/sub_accounts/${props.rootAccount.id}`,
      method: 'DELETE',
    })
    if (props.handleParent) {
      props.handleParent(props.rootAccount, true)
    }
  }

  const handleDelete = () => {
    if (subCount.current > 0) {
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
  }

  const updateList = (json: AccountWithCounts, isDeleted: boolean) => {
    const account = subaccounts.find(account => account.id === json.id)
    // updating
    if (account) {
      if (isDeleted) {
        // deleted
        subCount.current--
        setSubaccounts(subaccounts.filter(account => account.id !== json.id))
        focusId.current = props.rootAccount.id
      } else {
        // updated
        setSubaccounts(
          subaccounts.map(account => {
            if (account.id !== json.id) {
              return account
            } else {
              return json as AccountWithCounts
            }
          }),
        )
        focusId.current = json.id
      }
    } else {
      // adding
      subCount.current++
      setSubaccounts([...subaccounts, json as AccountWithCounts])
      focusId.current = json.id
    }
  }

  const renderRoot = (showRoot: boolean) => {
    const show = props.parentExpanded != null ? props.parentExpanded : true
    return (
      <SubaccountItem
        account={{...props.rootAccount, sub_account_count: subCount.current}}
        depth={props.depth}
        onExpand={() => {
          setIsExpanded(true)
          focusId.current = ''
        }}
        onCollapse={() => {
          setShowForm(false)
          setIsExpanded(false)
          focusId.current = ''
        }}
        onAdd={() => {
          setShowForm(true)
          setIsExpanded(true)
          focusId.current = ''
        }}
        onDelete={handleDelete}
        onEditSaved={(json: AccountWithCounts) => {
          if (props.handleParent) {
            props.handleParent(json, false)
          } else {
            // root node should just be re-fetched
            queryClient.invalidateQueries(['account', props.rootAccount.id])
          }
        }}
        isExpanded={isExpanded}
        canDelete={props.depth != 1}
        show={show && showRoot}
        isFocus={focusId.current === props.rootAccount.id}
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
          handleParent={(account: AccountWithCounts, isDeleted: boolean) => {
            updateList(account, isDeleted)
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
    const showSpinner = isFetching && !isFetchingNextPage
    // we only want to do this if the query was made
    const updateCount = subCount.current !== subaccounts.length && !isFetching && !hasNextPage
    if (updateCount) {
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
            onSuccess={(json: AccountWithCounts) => {
              setShowForm(false)
              updateList(json, false)
            }}
            onCancel={() => setShowForm(false)}
            depth={props.depth + 1}
          />
        ) : null}
      </>
    )
  }
}
