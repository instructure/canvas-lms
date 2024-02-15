//
// Copyright (C) 2013 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import $ from 'jquery'
import {pick} from 'lodash'
import Account from './models/Account'
import extensions from '@canvas/bundles/extensions'
import QuotasView from '@canvas/account-quota-settings-view'
import ManualQuotasView from './views/ManualQuotasView'
import ready from '@instructure/ready'

if (ENV.ACCOUNT) {
  const account = new Account(ENV.ACCOUNT)

  // replace toJSON so only the quota fields are sent to the server
  account.toJSON = function () {
    return {
      id: this.get('id'),
      account: pick(this.attributes, [
        'default_storage_quota_mb',
        'default_user_storage_quota_mb',
        'default_group_storage_quota_mb',
      ]),
    }
  }

  ready(function () {
    const quotasView = new QuotasView({model: account})
    $('#tab-quotas').append(quotasView.el)
    quotasView.render()

    const manualQuotasView = new ManualQuotasView()
    $('#tab-quotas').append(manualQuotasView.el)
    manualQuotasView.render()
  })
}

const loadExtension =
  extensions['ui/features/account_settings/backbone/account_quota_settings.js']?.()
if (loadExtension) {
  loadExtension
    .then(module => module.default())
    .catch(error => {
      throw new Error(
        `Failed to load extension for ui/features/account_settings/backbone/account_quota_settings.js`,
        error
      )
    })
}
