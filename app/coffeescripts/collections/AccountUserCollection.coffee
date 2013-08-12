define [
  'compiled/collections/PaginatedCollection'
  'compiled/models/AccountUser'
], (PaginatedCollection, AccountUser) ->

  class AccountUserCollection extends PaginatedCollection

    model: AccountUser

    ##
    # The account id of this user collection

    @optionProperty 'account_id'

    url: ->
      "/api/v1/accounts/#{@options.account_id}/users"
