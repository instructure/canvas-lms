/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {useScope as useI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'

const I18n = useI18nScope('lti_registrations')

function Disclaimer() {
  return (
    <Text color="secondary">
      {I18n.t(
        'Apps offered in the Canvas Apps library are not reviewed or otherwise vetted by Instructure. We encourage you to review the AI, privacy, and security practices of each provider before connecting to your Canvas LMS account.'
      )}
    </Text>
  )
}

export default Disclaimer
