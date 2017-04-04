import FeatureFlagAdminView from 'compiled/views/feature_flags/FeatureFlagAdminView'
import 'compiled/util/BackoffPoller'
import 'profile'
import 'user_sortable_name'
import 'communication_channels'

const hiddenFlags = [];
if (!ENV.NEW_USER_TUTORIALS_ENABLED_AT_ACCOUNT) {
  hiddenFlags.push('new_user_tutorial_on_off')
}

const view = new FeatureFlagAdminView({el: '.feature-flag-wrapper', hiddenFlags})
view.collection.fetchAll()
