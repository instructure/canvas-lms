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
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ModuleStatistics} from '../utils/types.d'
import {Pill} from '@instructure/ui-pill'

const I18n = createI18nScope('context_modules_v2')

type Props = {
  submissionStatistics?: ModuleStatistics
}

export const ModuleHeaderMissingCount = ({submissionStatistics}: Props) => {
  const missingCount = submissionStatistics?.missingAssignmentCount || 0
  return (
    <Pill color="danger">
      <Text size="x-small" color="danger">
        {I18n.t(
          {
            one: '1 Missing Assignment',
            other: '%{count} Missing Assignments',
          },
          {
            count: missingCount,
          },
        )}
      </Text>
    </Pill>
  )
}
