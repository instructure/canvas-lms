define [
  'jquery'
  'underscore'
  'Backbone'
  'compiled/models/Account'
  'compiled/views/accounts/settings/QuotasView'
  'compiled/views/accounts/settings/ManualQuotasView'
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
