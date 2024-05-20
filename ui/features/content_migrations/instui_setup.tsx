/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import ReactDOM from 'react-dom'
import ready from '@instructure/ready'
import App from './react/app'
import extensions from '@canvas/bundles/extensions'

ready(() => {
  if (document.getElementById('instui_content_migrations')) {
    ReactDOM.render(<App />, document.getElementById('instui_content_migrations'))
  }

  const loadExtension = extensions['ui/features/content_migrations/instui_setup.tsx']?.()
  if (loadExtension) {
    loadExtension
      .then(module => {
        module.default()
      })
      .catch(err => {
        throw new Error(
          'Error loading extension for ui/features/content_migrations/instui_setup.tsx',
          err
        )
      })
  }
})
