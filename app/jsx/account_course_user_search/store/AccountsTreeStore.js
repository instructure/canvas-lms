/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import {string, shape, arrayOf} from 'prop-types'
import createStore from './createStore'

const AccountsTreeStore = createStore({
  getUrl() {
    return `/api/v1/accounts/${this.context.accountId}/sub_accounts`
  },

  loadTree() {
    // fetch the account itself first, then get its subaccounts
    return this._load(
      this.getKey(),
      `/api/v1/accounts/${this.context.accountId}`,
      {},
      {wrap: true}
    ).then(() => this.loadAll(null, true))
  },

  normalizeParams() {
    return {recursive: true}
  },

  getTree() {
    const {data, loading} = this.get()
    if (!data) return {loading}
    const accounts = data.map(account => ({...account, subAccounts: []}))
    accounts.forEach(account => {
      const parent = accounts.find(p => p.id === account.parent_account_id)
      if (parent) parent.subAccounts.push(account)
    })
    return {loading, accounts: [accounts[0]]}
  }
})

AccountsTreeStore.PropType = shape({
  id: string.isRequired,
  parent_account_id: string,
  name: string.isRequired,
  subAccounts: arrayOf((...args) => AccountsTreeStore.PropType(...args)).isRequired
})

export default AccountsTreeStore
