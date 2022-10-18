/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

/* eslint-disable no-restricted-globals */

import 'formdata-polyfill' // Need to support FormData.has for IE
import React from 'react'
import ReactDOM from 'react-dom'
import ThemeEditor from './react/ThemeEditor'
import ready from '@instructure/ready'

// framebust out so we don't ever get theme editor inside theme editor
if (window.top.location !== self.location) {
  window.top.location = self.location.href
}

ready(() => {
  ReactDOM.render(
    <ThemeEditor
      {...{
        brandConfig: window.ENV.brandConfig,
        hasUnsavedChanges: window.ENV.hasUnsavedChanges,
        isDefaultConfig: window.ENV.isDefaultConfig,
        variableSchema: window.ENV.variableSchema,
        sharedBrandConfigs: window.ENV.sharedBrandConfigs,
        allowGlobalIncludes: window.ENV.allowGlobalIncludes,
        accountID: window.ENV.account_id,
        useHighContrast: window.ENV.use_high_contrast,
      }}
    />,
    document.body
  )
})
