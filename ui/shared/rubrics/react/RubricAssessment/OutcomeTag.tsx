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
import {Tag} from '@instructure/ui-tag'
import {AccessibleContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'

const I18n = useI18nScope('rubrics-assessment-tray')

type OutcomeTagProps = {
  displayName: string
}
export const OutcomeTag = ({displayName}: OutcomeTagProps) => {
  return (
    <Tag
      text={
        <AccessibleContent alt={I18n.t('Outcome Name')}>
          <Text>
            {I18n.t('%{displayName}', {
              displayName,
            })}
          </Text>
        </AccessibleContent>
      }
      size="small"
      themeOverride={{
        defaultBackground: 'white',
        defaultBorderColor: 'rgb(3, 116, 181)',
        defaultColor: 'rgb(3, 116, 181)',
      }}
      data-testid="rubric-criteria-row-outcome-tag"
    />
  )
}
