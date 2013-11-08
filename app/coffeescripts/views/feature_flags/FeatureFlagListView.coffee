define [
  'underscore'
  'compiled/views/CollectionView'
  'compiled/views/feature_flags/FeatureFlagView'
  'jst/feature_flags/featureFlagList'
], (_, CollectionView, FeatureFlagView, template) ->

  class FeatureFlagListView extends CollectionView

    tagName: 'div'

    @optionProperty 'flags'

    @optionProperty 'title'

    template: template

    itemView: FeatureFlagView

    toJSON: ->
      _.extend(super, title: @title)
