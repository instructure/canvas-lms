/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {Alert} from '@instructure/ui-alerts'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('groups')

const SameSectionInfoAlert = () => (
  <div style={{maxWidth: '400px'}}>
    <Alert variant="info" margin="small">
      {I18n.t(
        'Restrict by Section keeps students in the same section, but students enrolled in multiple sections may be grouped unpredictably. For exact section groupings, create groups manually.',
      )}
    </Alert>
  </div>
)
export default SameSectionInfoAlert
