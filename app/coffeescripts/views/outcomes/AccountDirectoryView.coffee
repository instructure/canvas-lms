define [
  'jquery'
  'compiled/views/outcomes/OutcomesDirectoryView'
  'compiled/collections/OutcomeCollection'
  'compiled/collections/OutcomeGroupCollection'
], ($, OutcomesDirectoryView, OutcomeCollection, OutcomeGroupCollection) ->

  # for working with Account Standards in the import dialog
  class AccountDirectoryView extends OutcomesDirectoryView

    initialize: (opts) ->
      @outcomes = new OutcomeCollection # empty - not needed
      @groups = new OutcomeGroupCollection
      @groups.url = ENV.ACCOUNT_CHAIN_URL

      super opts

    fetchOutcomes: ->
      # don't fetch outcomes