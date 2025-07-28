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

import '@canvas/backoff-poller'
import './jquery/index'
import '@canvas/user-sortable-name'
import './jquery/communication_channels'
import React from 'react'
import {createRoot} from 'react-dom/client'
import GeneratePairingCode from '@canvas/generate-pairing-code'
import ready from '@instructure/ready'
import FeatureFlags from '@canvas/feature-flags'
import {initializeTopNavPortal} from '@canvas/top-navigation/react/TopNavPortal'

ready(() => {
  const hiddenFlags = []
  if (!ENV.NEW_USER_TUTORIALS_ENABLED_AT_ACCOUNT) {
    hiddenFlags.push('new_user_tutorial_on_off')
  }

  initializeTopNavPortal()

  const featureFlagContainer = document.querySelector('.feature-flag-wrapper') // there is only one of these
  if (featureFlagContainer) {
    const ffRoot = createRoot(featureFlagContainer)
    ffRoot.render(<FeatureFlags hiddenFlags={hiddenFlags} disableDefaults={true} />)
  }

  const pairingCodeContainer = document.querySelector('#pairing-code')
  if (pairingCodeContainer) {
    const pcRoot = createRoot(pairingCodeContainer)
    pcRoot.render(<GeneratePairingCode userId={ENV.current_user.id} />)
  }
})
