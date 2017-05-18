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

import React from 'react'
import PropTypes from 'prop-types'
import createStore from './createStore'
import _ from 'underscore'

  var { string, shape, arrayOf } = PropTypes;

  var AccountsTreeStore = createStore({
    getUrl() {
      return `/api/v1/accounts/${this.context.accountId}/sub_accounts`;
    },

    loadTree() {
      var key = this.getKey();
      // fetch the account itself first, then get its subaccounts
      this._load(key, `/api/v1/accounts/${this.context.accountId}`, {}, {wrap: true}).then(() => {
        this.loadAll(null, true);
      });
    },

    normalizeParams() {
      return { recursive: true };
    },

    getTree() {
      var data = this.get();
      if (!data || !data.data) return [];
      var accounts = [];
      var idIndexMap = {};
      data.data.forEach(function(item, i) {
        var account = _.extend({}, item, {subAccounts: []});
        accounts.push(account);
        idIndexMap[account.id] = i;
      })
      accounts.forEach(function(account) {
        var parentIdx = idIndexMap[account.parent_account_id];
        if (typeof parentIdx === "undefined") return;
        accounts[parentIdx].subAccounts.push(account);
      });
      return [accounts[0]];
    }
  });

  AccountsTreeStore.PropType = shape({
    id: string.isRequired,
    parent_account_id: string,
    name: string.isRequired,
    subAccounts: arrayOf(
      function() { AccountsTreeStore.PropType.apply(this, arguments) }
    ).isRequired
  });

export default AccountsTreeStore
