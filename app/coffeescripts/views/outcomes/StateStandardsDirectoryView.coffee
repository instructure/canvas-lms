define [
  'jquery'
  'underscore'
  'compiled/views/outcomes/OutcomesDirectoryView'
  'compiled/collections/OutcomeCollection'
], ($, _, OutcomesDirectoryView, OutcomeCollection) ->

  # for working with State Standards in the import dialog
  class StateStandardsDirectoryView extends OutcomesDirectoryView

    initialize: (opts) ->
      @outcomes = new OutcomeCollection # empty - not needed
      super
      @groups.on 'reset', @interceptMultiple
      @groups.on 'add', @interceptCommonCore
      @interceptMultiple @groups

    fetchOutcomes: ->
      # don't fetch outcomes

    # Calls @interceptCommonCore for multiple groups.
    interceptMultiple: (groups) =>
      _.each groups.models, @interceptCommonCore

    # Common core is a group in state standards.
    # We don't want to show it here because it's shown
    # one level up.
    interceptCommonCore: (group) =>
      if group.id is ENV.COMMON_CORE_GROUP_ID
        @groups.remove group, silent: true
        @reset()