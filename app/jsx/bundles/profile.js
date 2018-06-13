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

import FeatureFlagAdminView from 'compiled/views/feature_flags/FeatureFlagAdminView'
import 'compiled/util/BackoffPoller'
import 'profile'
import 'user_sortable_name'
import 'communication_channels'
import React from 'react'
import ReactDOM from 'react-dom'
import GeneratePairingCode from '../profiles/GeneratePairingCode'

const hiddenFlags = [];
if (!ENV.NEW_USER_TUTORIALS_ENABLED_AT_ACCOUNT) {
  hiddenFlags.push('new_user_tutorial_on_off')
}

const view = new FeatureFlagAdminView({el: '.feature-flag-wrapper', hiddenFlags})
view.collection.fetchAll()

const container = document.querySelector('#pairing-code')
if (container) {
  ReactDOM.render(<GeneratePairingCode userId={ENV.current_user.id} />, container)
}
