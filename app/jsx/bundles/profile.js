require [
  'compiled/views/feature_flags/FeatureFlagAdminView'
  'compiled/util/BackoffPoller'
  'profile'
  'user_sortable_name'
  'communication_channels'
  'compiled/profile/confirmEmail'
], (FeatureFlagAdminView) ->

  view = new FeatureFlagAdminView(el: '.feature-flag-wrapper')
  view.collection.fetchAll()
