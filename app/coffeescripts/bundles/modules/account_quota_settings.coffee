#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'jquery'
  'underscore'
  'Backbone'
  '../../models/Account'
  '../../views/accounts/settings/QuotasView'
  '../../views/accounts/settings/ManualQuotasView'
], ($, _, Backbone, Account, QuotasView, ManualQuotasView) ->

  if ENV.ACCOUNT
    account = new Account(ENV.ACCOUNT)

    # replace toJSON so only the quota fields are sent to the server
    account.toJSON = ->
      id: @get('id')
      account: _.pick(@attributes, 'default_storage_quota_mb', 'default_user_storage_quota_mb', 'default_group_storage_quota_mb')

    quotasView = new QuotasView
      model: account
    $('#tab-quotas').append(quotasView.el)
    quotasView.render()

    manualQuotasView = new ManualQuotasView()
    $('#tab-quotas').append(manualQuotasView.el)
    manualQuotasView.render()
