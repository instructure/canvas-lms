/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import React from 'react'
import {mount} from 'enzyme'
import Lti2Permissions from 'ui/features/external_apps/react/components/Lti2Permissions'

QUnit.module('ExternalApps.Lti2Permissions')

test('renders', () => {
  ok(
    mount(
      <Lti2Permissions
        tool={{
          app_id: 3,
          app_type: 'Lti::ToolProxy',
          description: null,
          enabled: false,
          installed_locally: true,
          name: 'Twitter',
        }}
        handleCancelLti2={() => {}}
        handleActivateLti2={() => {}}
      />
    ).exists()
  )
})
