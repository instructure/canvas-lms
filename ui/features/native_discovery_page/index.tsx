/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import {createRoot} from 'react-dom/client'
import {NativeDiscoveryPage} from './react/components/NativeDiscoveryPage'
import ready from '@instructure/ready'

ready(() => {
  const reactRoot = document.getElementById('native-discovery-page-root')
  const hiddenField = document.getElementById(
    'native_discovery_enabled_field',
  ) as HTMLInputElement | null
  if (reactRoot && hiddenField) {
    const currentValue = hiddenField.value === 'true'
    createRoot(reactRoot).render(
      <NativeDiscoveryPage
        initialEnabled={currentValue}
        onChange={newValue => {
          hiddenField.value = String(newValue)
        }}
      />,
    )
  }
})
