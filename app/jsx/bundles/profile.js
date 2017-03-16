import FeatureFlagAdminView from 'compiled/views/feature_flags/FeatureFlagAdminView'
import 'compiled/util/BackoffPoller'
import 'profile'
import 'user_sortable_name'
import 'communication_channels'
import 'compiled/profile/confirmEmail'

const view = new FeatureFlagAdminView({el: '.feature-flag-wrapper'})
view.collection.fetchAll()
