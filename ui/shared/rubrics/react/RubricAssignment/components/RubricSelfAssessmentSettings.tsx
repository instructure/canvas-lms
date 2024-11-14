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
import {Checkbox} from '@instructure/ui-checkbox'
import {View} from '@instructure/ui-view'
import {useMutation} from '@tanstack/react-query'
import {setRubricSelfAssessment} from '../queries'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'

const I18n = useI18nScope('enhanced-rubrics-self-assessments')

type RubricSelfAssessmentSettingsProps = {
  assignmentId: string
  canUpdateSelfAssessment: boolean
  rubricSelfAssessmentEnabled: boolean
}
export const RubricSelfAssessmentSettings = ({
  assignmentId,
  canUpdateSelfAssessment,
  rubricSelfAssessmentEnabled,
}: RubricSelfAssessmentSettingsProps) => {
  const [selfAssessmentEnabled, setSelfAssessmentEnabled] = React.useState(
    rubricSelfAssessmentEnabled
  )

  const {isLoading: mutationLoading, mutateAsync} = useMutation({
    mutationFn: setRubricSelfAssessment,
    mutationKey: ['set-rubric-self-assessment'],
    onError: _error => {
      showFlashError('Failed to update self assessment settings')()
    },
  })

  const handleSettingChange = async (enabled: boolean) => {
    await mutateAsync({
      assignmentId,
      enabled,
    })

    setSelfAssessmentEnabled(enabled)
  }

  return (
    <View>
      <View as="div" margin="small 0">
        <Checkbox
          data-testid="rubric-self-assessment-checkbox"
          label={I18n.t('Enable self assessment')}
          checked={selfAssessmentEnabled}
          disabled={mutationLoading || !canUpdateSelfAssessment}
          name="self-assessment-settings"
          onChange={e => handleSettingChange(e.target.checked)}
        />
      </View>
    </View>
  )
}
