// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-nocheck
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
import ReactDOM from 'react-dom/client'
import ready from '@instructure/ready'
import App from './react/app'
import extensions from '@canvas/bundles/extensions'

ready(() => {
  if (document.getElementById('instui_content_migrations')) {
    const node = document.getElementById('instui_content_migrations')
    if (!node) {
      throw new Error('Could not find element with id instui_content_migrations')
    }
    const root = ReactDOM.createRoot(node)
    root.render(<App />)
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
          err,
        )
      })
  }
})
