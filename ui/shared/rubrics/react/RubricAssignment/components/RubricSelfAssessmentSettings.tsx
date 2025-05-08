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
import {useScope as createI18nScope} from '@canvas/i18n'
import {Checkbox} from '@instructure/ui-checkbox'
import {View} from '@instructure/ui-view'
import {queryClient} from '@canvas/query'
import {getRubricSelfAssessmentSettings, setRubricSelfAssessment} from '../queries'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {Tooltip} from '@instructure/ui-tooltip'
import {useMutation, useQuery} from '@tanstack/react-query'

const I18n = createI18nScope('enhanced-rubrics-self-assessments')

type RubricSelfAssessmentSettingsProps = {
  assignmentId: string
  rubricId?: string
}
export const RubricSelfAssessmentSettings = ({
  assignmentId,
  rubricId,
}: RubricSelfAssessmentSettingsProps) => {
  const queryKey = ['assignment-self-assessment-settings', assignmentId, rubricId ?? '']
  const [showTooltip, setShowTooltip] = React.useState(false)

  const {isPending: mutationLoading, mutateAsync} = useMutation({
    mutationFn: setRubricSelfAssessment,
    mutationKey: ['set-rubric-self-assessment', assignmentId, rubricId],
    onError: _error => {
      showFlashError('Failed to update self assessment settings')()
    },
  })

  const {data: selfAssessmentSettings} = useQuery({
    queryKey,
    queryFn: getRubricSelfAssessmentSettings,
    enabled: !!rubricId,
  })

  const handleSettingChange = async (enabled: boolean) => {
    await mutateAsync({
      assignmentId,
      enabled,
    })

    queryClient.invalidateQueries({queryKey})
  }

  if (!rubricId || !selfAssessmentSettings) {
    return null
  }

  const {canUpdateRubricSelfAssessment, rubricSelfAssessmentEnabled} = selfAssessmentSettings

  return (
    <View as="div">
      <View as="div" margin="small 0">
        <Tooltip
          renderTip={
            <View width="336px" as="div">
              {I18n.t(
                'This toggle will be disabled if the due date has passed OR there have already been self-assessments made on this assignment OR if the assignment is a group assignment.',
              )}
            </View>
          }
          isShowingContent={!canUpdateRubricSelfAssessment && showTooltip}
          placement="top start"
          offsetX="10px"
        >
          <Checkbox
            data-testid="rubric-self-assessment-checkbox"
            label={I18n.t('Enable self assessment')}
            checked={rubricSelfAssessmentEnabled}
            disabled={mutationLoading || !canUpdateRubricSelfAssessment}
            name="self-assessment-settings"
            onChange={e => handleSettingChange(e.target.checked)}
            onMouseOver={() => setShowTooltip(true)}
            onMouseOut={() => setShowTooltip(false)}
          />
        </Tooltip>
      </View>
    </View>
  )
}
