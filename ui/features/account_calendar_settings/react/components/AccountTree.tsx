// @ts-nocheck
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

import React, {useState, useEffect} from 'react'

import {ApplyTheme} from '@instructure/ui-themeable'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'

import doFetchApi from '@canvas/do-fetch-api-effect'
import {useScope as useI18nScope} from '@canvas/i18n'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'

import {addAccountsToTree} from '../utils'
import {AccountCalendarItemToggleGroup} from './AccountCalendarItemToggleGroup'
import {Account, Collection, AccountData, VisibilityChange, SubscriptionChange} from '../types'

const I18n = useI18nScope('account_calendar_settings_account_tree')

type ComponentProps = {
  readonly originAccountId: number
  readonly visibilityChanges: VisibilityChange[]
  readonly subscriptionChanges: SubscriptionChange[]
  readonly onAccountToggled: (id: number, visible: boolean) => void
  readonly onAccountSubscriptionToggled: (id: number, autoSubscription: boolean) => void
  readonly autoSubscriptionEnabled: boolean
}

export const AccountTree = ({
  originAccountId,
  visibilityChanges,
  subscriptionChanges,
  onAccountToggled,
  onAccountSubscriptionToggled,
  autoSubscriptionEnabled,
}: ComponentProps) => {
  const [collections, setCollections] = useState<Collection>({})
  const [loadingCollectionIds, setLoadingCollectionIds] = useState<number[]>([originAccountId])

  const receivedAccountData = accounts => {
    setCollections(addAccountsToTree(accounts, collections))
  }

  const fetchAccountData = (
    accountId,
    nextLink?: string,
    accumulatedResults: AccountData[] = []
  ) => {
    setLoadingCollectionIds([...loadingCollectionIds, accountId])
    doFetchApi({
      path: nextLink || `/api/v1/accounts/${accountId}/account_calendars`,
      params: {
        ...(nextLink == null && {per_page: 100}),
      },
    })
      .then(({json, link}) => {
        const accountData = accumulatedResults.concat(json || [])
        if (link?.next) {
          fetchAccountData(accountId, link.next.url, accountData)
        } else {
          receivedAccountData(accountData)
          setLoadingCollectionIds(loadingCollectionIds.filter(id => id !== accountId))
        }
      })
      .catch(showFlashError(I18n.t("Couldn't load account calendar settings")))
  }

  useEffect(() => {
    fetchAccountData(originAccountId)
    // this should run on first render
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const handleToggle = (account: Account, expanded) => {
    if (
      expanded &&
      collections[account.id].sub_account_count > 0 &&
      account.id !== originAccountId
    ) {
      fetchAccountData(account.id)
    }
  }

  if (!collections[originAccountId]) {
    return (
      <Flex as="div" alignItems="center" justifyItems="center" padding="x-large">
        <Spinner renderTitle={I18n.t('Loading accounts')} />
      </Flex>
    )
  }

  return (
    <View as="div" padding="small">
      <ApplyTheme>
        <div id="account-tree" data-testid="account-tree">
          <AccountCalendarItemToggleGroup
            parentId={null}
            accountGroup={[originAccountId]}
            defaultExpanded={true}
            collections={collections}
            handleToggle={handleToggle}
            visibilityChanges={visibilityChanges}
            subscriptionChanges={subscriptionChanges}
            onAccountToggled={onAccountToggled}
            onAccountSubscriptionToggled={onAccountSubscriptionToggled}
            autoSubscriptionEnabled={autoSubscriptionEnabled}
          />
        </div>
      </ApplyTheme>
    </View>
  )
}
