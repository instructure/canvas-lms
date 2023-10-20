/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {bool, func, oneOf} from 'prop-types'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('hide_assignment_grades_tray')

export const EVERYONE = 'everyone'
export const GRADED = 'graded'

export default function PostTypes({anonymousGrading, defaultValue, disabled, postTypeChanged}) {
  return (
    <RadioInputGroup
      defaultValue={anonymousGrading ? EVERYONE : defaultValue}
      description={
        <ScreenReaderContent>
          {I18n.t('Select whether to post for all submissions, or only graded ones.')}
        </ScreenReaderContent>
      }
      disabled={disabled}
      onChange={postTypeChanged}
      name={I18n.t('Post types')}
    >
      <RadioInput
        label={
          <>
            <Text>{I18n.t('Everyone')}</Text>
            <br />
            <Text size="small">
              {I18n.t('All students will be able to see their grade and/or submission comments.')}
            </Text>
          </>
        }
        value={EVERYONE}
      />
      <RadioInput
        disabled={anonymousGrading}
        label={
          <>
            <Text>{I18n.t('Graded')}</Text>
            <br />
            <Text size="small">
              {I18n.t(
                'Students who have received a grade or a submission comment will be able to see their grade and/or submission comments.'
              )}
            </Text>
          </>
        }
        value={GRADED}
      />
    </RadioInputGroup>
  )
}

PostTypes.propTypes = {
  anonymousGrading: bool.isRequired,
  defaultValue: oneOf([EVERYONE, GRADED]).isRequired,
  disabled: bool.isRequired,
  postTypeChanged: func.isRequired,
}
