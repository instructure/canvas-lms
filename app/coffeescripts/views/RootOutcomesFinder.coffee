define [
  'i18n!rootOutcomesFinder'
  'compiled/models/OutcomeGroup'
  'compiled/str/splitAssetString'
], (I18n, OutcomeGroup, splitAssetString) ->

  class RootOutcomesFinder

    find: ->
      # purposely sharing these across instances of RootOutcomesFinder
      RootOutcomesFinder.rootFolders ||= do =>
        contextOutcomeGroups = null
        contextTypeAndId = splitAssetString(ENV.context_asset_string || '')

        contextOutcomeGroups = new OutcomeGroup
        contextOutcomeGroups.url = "/api/v1/#{contextTypeAndId[0]}/#{contextTypeAndId[1]}/root_outcome_group"
        contextOutcomeGroups.fetch()

        [contextOutcomeGroups]