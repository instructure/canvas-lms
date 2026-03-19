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

import {useScope as createI18nScope} from '@canvas/i18n'
import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {RubricFormFieldSetter} from '../types/RubricForm'

const I18n = createI18nScope('rubrics-form')

type RubricAssignmentSettingsProps = {
  hideOutcomeResults: boolean
  hidePoints: boolean
  useForGrading: boolean
  hideScoreTotal: boolean
  canUseForGrading: boolean
  setRubricFormField: RubricFormFieldSetter
}
export const RubricAssignmentSettings = ({
  hideOutcomeResults,
  hidePoints,
  useForGrading,
  hideScoreTotal,
  canUseForGrading,
  setRubricFormField,
}: RubricAssignmentSettingsProps) => {
  return (
    <Flex margin="medium 0 0" gap="medium">
      <Flex.Item>
        <Checkbox
          label={I18n.t("Don't post to Learning Mastery Gradebook")}
          checked={hideOutcomeResults}
          onChange={e => setRubricFormField('hideOutcomeResults', e.target.checked)}
          data-testid="hide-outcome-results-checkbox"
        />
      </Flex.Item>
      {!hidePoints && (
        <>
          {canUseForGrading && (
            <Flex.Item>
              <Checkbox
                label={I18n.t('Use this rubric for assignment grading')}
                checked={useForGrading}
                onChange={e => {
                  setRubricFormField('useForGrading', e.target.checked)
                  setRubricFormField('hideScoreTotal', false)
                }}
                data-testid="use-for-grading-checkbox"
              />
            </Flex.Item>
          )}

          {!useForGrading && (
            <Flex.Item>
              <Checkbox
                label={I18n.t('Hide rubric score total from students')}
                checked={hideScoreTotal}
                onChange={e => setRubricFormField('hideScoreTotal', e.target.checked)}
                data-testid="hide-score-total-checkbox"
              />
            </Flex.Item>
          )}
        </>
      )}
    </Flex>
  )
}
