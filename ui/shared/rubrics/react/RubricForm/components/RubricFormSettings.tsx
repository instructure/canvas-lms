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

import {Flex} from '@instructure/ui-flex'
import {RubricRatingOrderSelect} from './RubricFormSelects/RubricRatingOrderSelect'
import {GradingTypeSelect} from './RubricFormSelects/GradingTypeSelect'
import {ScoringTypeSelect} from './RubricFormSelects/ScoringTypeSelect'

import {RubricFormProps, RubricFormFieldSetter} from '../types/RubricForm'
import {RatingDisplaySelect} from './RubricFormSelects/RatingDisplaySelect'

type RubricFormSettingsParams = {
  showAdditionalOptions: boolean
  rubricForm: RubricFormProps
  setRubricFormField: RubricFormFieldSetter
}
export const RubricFormSettings = ({
  showAdditionalOptions,
  rubricForm,
  setRubricFormField,
}: RubricFormSettingsParams) => {
  return (
    <>
      {showAdditionalOptions && (
        <Flex.Item margin="0 0 0 small">
          <GradingTypeSelect
            onChange={isFreeFormComments => {
              setRubricFormField('freeFormCriterionComments', isFreeFormComments)
            }}
            freeFormCriterionComments={rubricForm.freeFormCriterionComments}
          />
        </Flex.Item>
      )}
      {!rubricForm.freeFormCriterionComments && !rubricForm.hidePoints && (
        <Flex.Item margin="0 0 0 small">
          <RatingDisplaySelect
            buttonDisplay={rubricForm.buttonDisplay}
            onChange={buttonDisplay => setRubricFormField('buttonDisplay', buttonDisplay)}
          />
        </Flex.Item>
      )}
      {!rubricForm.freeFormCriterionComments && (
        <Flex.Item margin="0 0 0 small">
          <RubricRatingOrderSelect
            ratingOrder={rubricForm.ratingOrder}
            onChangeOrder={ratingOrder => setRubricFormField('ratingOrder', ratingOrder)}
          />
        </Flex.Item>
      )}
      {showAdditionalOptions && (
        <Flex.Item margin="0 0 0 small">
          <ScoringTypeSelect
            hidePoints={rubricForm.hidePoints}
            onChange={() => {
              const newHidePoints = !rubricForm.hidePoints

              setRubricFormField('hidePoints', newHidePoints)
              setRubricFormField('hideScoreTotal', false)
              setRubricFormField('useForGrading', false)

              if (newHidePoints) {
                setRubricFormField('buttonDisplay', 'numeric')
              }
            }}
          />
        </Flex.Item>
      )}
    </>
  )
}
