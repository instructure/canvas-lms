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
import {type Outcome} from '../../../types'
import CalculationMethodContent from '@canvas/grading/CalculationMethodContent'
import {useScope as useI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {type OutcomeScore} from '../LearningMasteryTabsView'

const I18n = useI18nScope('enhanced_individual_gradebook')

type OutcomeInformationProps = {
  outcome?: Outcome
  outcomeScore?: OutcomeScore | null
}

function OutcomeInformation({outcome, outcomeScore}: OutcomeInformationProps) {
  if (!outcome) {
    return (
      <>
        <View as="div" data-testid="outcome-information-empty">
          <View as="div" className="row-fluid">
            <View as="div" className="span4">
              <View as="h2">{I18n.t('Outcome')}</View>
            </View>
            <View as="div" className="span8 pad-box top-only">
              <View as="p" className="outcome_selection">
                {I18n.t('Select a outcome to view additional information')}
              </View>
            </View>
          </View>
        </View>
      </>
    )
  }

  const calculationMethods = new CalculationMethodContent({
    calculation_method: outcome.calculationMethod,
    calculation_int: outcome.calculationInt,
    is_individual_outcome: true,
    mastery_points: outcome.masteryPoints,
  }).present()

  const {method, exampleText, exampleScores, exampleResult} = calculationMethods

  return (
    <>
      <View as="div" data-testid="outcome-information-result">
        <View as="div" className="row-fluid">
          <View as="div" className="span4">
            <View as="h2">{I18n.t('Outcome Information')}</View>
          </View>
          <View as="div" className="span8">
            <View as="h3" className="outcome_selection" margin="0 0 medium 0">
              {outcome.title}
            </View>

            <View
              as="div"
              className="outcome_description"
              borderWidth="small"
              padding="x-small"
              margin="0 0 medium 0"
            >
              <View as="p" margin="0" data-testid="outcome-information-calculation-method">
                {I18n.t('Calculation Method')}: {method}
              </View>
              <View as="p" margin="0" data-testid="outcome-information-example">
                {I18n.t('Example')}: {exampleText}
              </View>
              <View as="p" margin="0" data-testid="outcome-information-item-score">
                1 - {I18n.t('Item score')}: {exampleScores}
              </View>
              <View as="p" data-testid="outcome-information-final-score">
                2 - {I18n.t('Final score')}: {exampleResult}
              </View>
            </View>

            <View
              as="div"
              className="outcome_description"
              data-testid="outcome-information-total-result"
            >
              <View as="p">
                {I18n.t('Total results')}: {outcomeScore?.cnt}
              </View>
            </View>
          </View>
        </View>
      </View>
    </>
  )
}

export default OutcomeInformation
