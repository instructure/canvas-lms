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

import React from 'react'
import ReactDOM from 'react-dom'
import ThemeEditor from 'jsx/theme_editor/ThemeEditor'

  // framebust out so we don't ever get theme editor inside theme editor
if (window.top.location !== self.location) {
  window.top.location = self.location.href
}

ReactDOM.render(
  <ThemeEditor
    {...{
      brandConfig: window.ENV.brandConfig,
      hasUnsavedChanges: window.ENV.hasUnsavedChanges,
      variableSchema: window.ENV.variableSchema,
      sharedBrandConfigs: window.ENV.sharedBrandConfigs,
      allowGlobalIncludes: window.ENV.allowGlobalIncludes,
      accountID: window.ENV.account_id,
      useHighContrast: window.ENV.use_high_contrast
    }}
  />,
  document.body
)
