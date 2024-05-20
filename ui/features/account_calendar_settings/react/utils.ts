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

import {useScope as useI18nScope} from '@canvas/i18n'

import type {Collection, AccountData, Account} from './types'

const I18n = useI18nScope('account_calendar_settings_utils')

export const castIdsToInt = (accounts: AccountData[]): Account[] =>
  accounts.map(account => ({
    ...account,
    id: parseInt(account.id, 10),
    children: [],
    heading: '',
    parent_account_id:
      account.parent_account_id != null ? parseInt(account.parent_account_id, 10) : null,
  }))

export const addAccountsToTree = (
  accountData: AccountData[],
  collections: Collection
): Collection => {
  const accounts = castIdsToInt(accountData)
  const allAccounts = JSON.parse(JSON.stringify(collections))

  accounts.forEach(account => {
    if (allAccounts.hasOwnProperty(account.id)) {
      delete allAccounts[account.id]
    }

    allAccounts[account.id] = {
      ...account,
      ...{
        heading: I18n.t('%{accountName} (%{accountCount})', {
          accountName: account.name,
          accountCount: account.sub_account_count + 1, // to include parent account in the count
        }),
        label: I18n.t('%{accountName}, %{accountCount} accounts', {
          accountName: account.name,
          accountCount: account.sub_account_count + 1, // to include parent account in the count
        }),
      },
    }

    if (
      account.parent_account_id &&
      allAccounts[account.parent_account_id] &&
      account.parent_account_id !== account.id
    ) {
      if (!allAccounts[account.parent_account_id].children.includes(account.id)) {
        allAccounts[account.parent_account_id].children.push(account.id)
      }
    }

    if (!account.children.includes(account.id)) {
      account.children.push(account.id)
    }
  })

  // sometimes the children are fetched before the parent
  // be sure to add these children to the parent's children array
  for (const acctid in allAccounts) {
    const account = allAccounts[acctid]
    const parentid = account.parent_account_id
    if (parentid && allAccounts[parentid]) {
      if (!allAccounts[parentid].children.includes(account.id)) {
        allAccounts[parentid].children.push(account.id)
      }
    }
  }

  return allAccounts
}
