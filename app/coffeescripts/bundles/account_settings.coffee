require [
  'compiled/views/feature_flags/FeatureFlagAdminView'
  'account_settings'
  'compiled/bundles/modules/account_quota_settings'
], (FeatureFlagAdminView) ->
  featureFlags = new FeatureFlagAdminView(el: '#tab-features')
  featureFlags.collection.fetchAll()
