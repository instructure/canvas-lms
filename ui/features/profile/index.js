/*
 * Copyright (C) 2011 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import FeatureFlagAdminView from '@canvas/feature-flag-admin-view'
import '@canvas/backoff-poller'
import './jquery/index'
import '@canvas/user-sortable-name'
import './jquery/communication_channels'
import React from 'react'
import ReactDOM from 'react-dom'
import GeneratePairingCode from '@canvas/generate-pairing-code'
import ready from '@instructure/ready'
import FeatureFlags from '@canvas/feature-flags'

ready(() => {
  const hiddenFlags = []
  if (!ENV.NEW_USER_TUTORIALS_ENABLED_AT_ACCOUNT) {
    hiddenFlags.push('new_user_tutorial_on_off')
  }

  if (window.ENV.NEW_FEATURES_UI) {
    ReactDOM.render(
      <FeatureFlags hiddenFlags={hiddenFlags} disableDefaults />,
      // There is only one of these
      document.querySelector('.feature-flag-wrapper')
    )
  } else {
    const view = new FeatureFlagAdminView({el: '.feature-flag-wrapper', hiddenFlags})
    view.collection.fetchAll()
  }

  const container = document.querySelector('#pairing-code')
  if (container) {
    ReactDOM.render(<GeneratePairingCode userId={ENV.current_user.id} />, container)
  }
})
