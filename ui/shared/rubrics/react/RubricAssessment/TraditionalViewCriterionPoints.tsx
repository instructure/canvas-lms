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

import React, {FC} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Table} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import type {RubricCriterion, UpdateAssessmentData} from '../types/rubric'
import {TextInput} from '@instructure/ui-text-input'

const I18n = createI18nScope('rubrics-assessment-tray')

type TraditionalViewCriterionPointsProps = {
  criterion: RubricCriterion
  isPreviewMode: boolean
  pointTextInput: string
  possibleString: (points: number) => string
  setPointTextInput: React.Dispatch<React.SetStateAction<string>>
  updateAssessmentData: (params: Partial<UpdateAssessmentData>) => void
}

export const TraditionalViewCriterionPoints: FC<TraditionalViewCriterionPointsProps> = ({
  criterion,
  isPreviewMode,
  pointTextInput,
  possibleString,
  setPointTextInput,
  updateAssessmentData,
}) => {
  const setPoints = (value: string) => {
    const points = Number(value)

    if (!value.trim().length || Number.isNaN(points)) {
      updateAssessmentData({points: undefined, ratingId: undefined})
      return
    }

    updateAssessmentData({
      points,
      ratingId: undefined,
    })
  }

  return (
    <Table.Cell>
      <View as="div" height="100%" width="100%">
        <Flex direction="row" height="100%">
          <div style={{display: 'flex', alignItems: 'center', textWrap: 'nowrap'}}>
            {!isPreviewMode && !criterion.ignoreForScoring && (
              <Flex.Item>
                <TextInput
                  autoComplete="off"
                  renderLabel={
                    <ScreenReaderContent>{I18n.t('Criterion Score')}</ScreenReaderContent>
                  }
                  readOnly={isPreviewMode}
                  data-testid={`criterion-score-${criterion.id}`}
                  placeholder="--"
                  width="3.375rem"
                  height="2.375rem"
                  value={pointTextInput}
                  onChange={e => setPointTextInput(e.target.value)}
                  onBlur={e => setPoints(e.target.value)}
                />
              </Flex.Item>
            )}
            <Flex.Item style={{textWrap: 'nowrap'}}>
              {criterion.ignoreForScoring ? (
                <Text>--</Text>
              ) : (
                isPreviewMode && (
                  <Text data-testid={`criterion-score-${criterion.id}-readonly`}>
                    {pointTextInput}
                  </Text>
                )
              )}
              <Text>{'/' + possibleString(criterion.points)}</Text>
            </Flex.Item>
          </div>
        </Flex>
      </View>
    </Table.Cell>
  )
}
