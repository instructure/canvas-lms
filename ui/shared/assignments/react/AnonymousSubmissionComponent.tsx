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
import {useScope as createI18nScope} from '@canvas/i18n'
import {Checkbox} from '@instructure/ui-checkbox'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('assignment_anonymous_submission')

interface AnonymousSubmissionComponentProps {
  isAnonymous: boolean
  disabled: boolean
  onChange: (isAnonymous: boolean) => void
}

export const AnonymousSubmissionComponent: React.FC<AnonymousSubmissionComponentProps> = ({
  isAnonymous,
  disabled,
  onChange,
}) => {
  const handleChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    onChange(event.target.checked)
  }

  return (
    <fieldset id="overrides-wrapper">
      <div className="form-column-left" style={{width: 'unset'}}>
        <label>{I18n.t('anonymous_submission', 'Anonymous Submission')}</label>
      </div>
      <div className="overrides-column-right js-assignment-overrides overrideFormFlex border border-trbl border-round">
        <View as="div" padding="space24 space12" margin="0 0 0 space4">
          <Checkbox
            label={I18n.t('keep_submission_anonymous', 'Keep Submission Anonymous')}
            checked={isAnonymous}
            onChange={handleChange}
            name="new_quizzes_anonymous_submission"
            value="1"
            disabled={disabled}
          />
          <View as="div" display="block" margin="space12 0 0 space24" padding="0 0 0 space4">
            <Text as="div" size="small">
              {I18n.t(
                'anonymous_submission_description',
                'Anonymity can only be changed when creating a new Survey',
              )}
            </Text>
            <View as="div" margin="space12 0 0 0">
              <Text size="small">
                {I18n.t(
                  'anonymous_submission_description2',
                  'To ensure complete anonymity, student responses will be shown in random order.',
                )}
              </Text>
            </View>
          </View>
        </View>
      </div>
    </fieldset>
  )
}
