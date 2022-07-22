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

import {Collection, AccountData, Account} from './types'

const I18n = useI18nScope('account_calendar_settings_utils')

const castIdsToInt = (accounts: AccountData[]): Account[] =>
  accounts.map(account => ({
    ...account,
    id: parseInt(account.id, 10),
    parent_account_id:
      account.parent_account_id != null ? parseInt(account.parent_account_id, 10) : null
  }))

export const addAccountsToTree = (
  accountData: AccountData[],
  collections: Collection,
  originAccountId: number
): Collection => {
  const accounts = castIdsToInt(accountData)
  const newCollections = {...collections}

  // Add any new accounts with sub-accounts to collections and to parent's collections array
  // Also add self as the first item in the children array
  accounts.forEach(account => {
    if (
      !newCollections.hasOwnProperty(account.id) &&
      (account.sub_account_count > 0 || account.id === originAccountId)
    ) {
      newCollections[account.id] = {
        id: account.id,
        name: I18n.t('%{accountName} (%{subaccountCount})', {
          accountName: account.name,
          subaccountCount: account.sub_account_count
        }),
        collections: [],
        children: [{id: account.id, name: account.name, calendarVisible: account.visible}]
      }
      if (account.id !== originAccountId) {
        newCollections[account.parent_account_id!].collections.push(account.id)
      }
    }
  })

  // Add any new accounts without sub-accounts to parent's children
  accounts.forEach(account => {
    if (
      account.sub_account_count === 0 &&
      account.id !== originAccountId &&
      !newCollections[account.parent_account_id!].children.some(({id}) => id === account.id)
    ) {
      newCollections[account.parent_account_id!].children = [
        ...newCollections[account.parent_account_id!].children,
        {id: account.id, name: account.name, calendarVisible: account.visible}
      ]
    }
  })

  return newCollections
}
