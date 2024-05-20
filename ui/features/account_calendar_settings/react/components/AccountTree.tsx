/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import React, {useCallback, useRef, useState, useEffect} from 'react'

import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'

import doFetchApi from '@canvas/do-fetch-api-effect'
import {useScope as useI18nScope} from '@canvas/i18n'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'

import {addAccountsToTree} from '../utils'
import {AccountCalendarItemToggleGroup} from './AccountCalendarItemToggleGroup'
import type {
  Account,
  Collection,
  AccountData,
  VisibilityChange,
  SubscriptionChange,
  ExpandedAccounts,
  FetchAccountDataResponse,
} from '../types'

const I18n = useI18nScope('account_calendar_settings_account_tree')

type ComponentProps = {
  readonly originAccountId: number
  readonly visibilityChanges: VisibilityChange[]
  readonly subscriptionChanges: SubscriptionChange[]
  readonly expandedAccounts: ExpandedAccounts
  readonly onAccountToggled: (id: number, visible: boolean) => void
  readonly onAccountSubscriptionToggled: (id: number, autoSubscription: boolean) => void
  readonly onAccountExpandedToggled: (id: number, expanded: boolean) => void
}

export const AccountTree = ({
  originAccountId,
  visibilityChanges,
  subscriptionChanges,
  expandedAccounts,
  onAccountToggled,
  onAccountSubscriptionToggled,
  onAccountExpandedToggled,
}: ComponentProps) => {
  const [collections, setCollections] = useState<Collection>({})
  // ref because we need this to be updated syncronously so we can be sure
  // we're not fetching the same account multiple times
  const loadingCollectionIds = useRef<number[]>([])
  const [loadingCollectionIdState, setLoadingCollectionIdState] = useState<number[]>([]) // but also need in state for re-render

  const receivedAccountData = useCallback((accounts: AccountData[]) => {
    setCollections((prevCollections: Collection) => {
      const newColls = addAccountsToTree(accounts, prevCollections)
      return newColls
    })
  }, [])

  const fetchInFlight = useCallback((id: number) => loadingCollectionIds.current.includes(id), [])

  const fetchAccountData = useCallback(
    (accountId: number, nextLink?: string, accumulatedResults: AccountData[] = []) => {
      loadingCollectionIds.current = [...loadingCollectionIds.current, accountId]
      setLoadingCollectionIdState(loadingCollectionIds.current)
      doFetchApi({
        path: nextLink || `/api/v1/accounts/${accountId}/account_calendars`,
        params: {
          ...(nextLink == null && {per_page: 100}),
        },
      })
        .then((response: FetchAccountDataResponse) => {
          const {json, link} = response
          const accountData = accumulatedResults.concat(json || [])
          if (link?.next) {
            fetchAccountData(accountId, link.next.url, accountData)
          } else {
            receivedAccountData(accountData)
            loadingCollectionIds.current = loadingCollectionIds.current.filter(
              id => id !== accountId
            )
            setLoadingCollectionIdState(loadingCollectionIds.current)
          }
        })
        .catch(showFlashError(I18n.t("Couldn't load account calendar settings")))
    },
    [receivedAccountData]
  )

  useEffect(() => {
    for (const id of expandedAccounts) {
      fetchAccountData(id)
    }
    // this should onlyrun on first render
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const handleToggle = useCallback(
    (account: Account, expanded: boolean) => {
      if (
        expanded &&
        !fetchInFlight(account.id) &&
        // because children include the account itself + sub accounts
        collections[account.id].sub_account_count >= collections[account.id].children.length &&
        account.id !== originAccountId
      ) {
        fetchAccountData(account.id)
      }
      onAccountExpandedToggled(account.id, expanded)
    },
    [collections, fetchAccountData, fetchInFlight, onAccountExpandedToggled, originAccountId]
  )

  if (!collections[originAccountId]) {
    return (
      <Flex as="div" alignItems="center" justifyItems="center" padding="x-large">
        <Spinner renderTitle={I18n.t('Loading accounts')} />
      </Flex>
    )
  }

  return (
    <View as="div" padding="small">
      <div id="account-tree" data-testid="account-tree">
        <AccountCalendarItemToggleGroup
          parentId={null}
          accountGroup={[originAccountId]}
          expandedAccounts={expandedAccounts}
          collections={collections}
          loadingCollectionIds={loadingCollectionIdState}
          handleToggle={handleToggle}
          visibilityChanges={visibilityChanges}
          subscriptionChanges={subscriptionChanges}
          onAccountToggled={onAccountToggled}
          onAccountSubscriptionToggled={onAccountSubscriptionToggled}
        />
      </div>
    </View>
  )
}
