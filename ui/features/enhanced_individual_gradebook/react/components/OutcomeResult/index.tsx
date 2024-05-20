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
import {useScope as useI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import LoadingIndicator from '@canvas/loading-indicator'
import type {OutcomeScore, ParsedOutcomeRollup} from '../LearningMasteryTabsView'

const I18n = useI18nScope('enhanced_individual_gradebook')

type OutcomeResultProps = {
  outcome?: Outcome | null
  outcomeScore?: OutcomeScore | null
  selectedStudentId?: string | null
  selectedOutcomeRollup?: ParsedOutcomeRollup
  isLoading?: boolean
}

function OutcomeResult({
  outcome,
  outcomeScore,
  selectedStudentId,
  selectedOutcomeRollup,
  isLoading,
}: OutcomeResultProps) {
  if (isLoading) {
    return <LoadingIndicator />
  }

  if (!outcome || !selectedStudentId) {
    return (
      <>
        <View as="div" data-testid="student-outcome-results-empty">
          <View as="div" className="row-fluid">
            <View as="div" className="span4">
              <View as="h2">{I18n.t('Result')}</View>
            </View>
            <View as="div" className="span8 pad-box top-only">
              <View as="p" className="student_outcome_selection">
                {I18n.t('Select a student and an outcome to view results.')}
              </View>
            </View>
          </View>
        </View>
      </>
    )
  }

  function renderOutcomeResult() {
    if (selectedOutcomeRollup && outcome) {
      return (
        <View as="div" data-testid="student-outcome-rollup-results">
          <View as="p" className="student_outcome_selection">
            {I18n.t('Current Mastery Score')}:{selectedOutcomeRollup.score}
            {I18n.t('out of')} {outcome.masteryPoints}
          </View>
          <table className="ic-Table">
            <thead>
              <tr>
                {outcomeScore && (
                  <>
                    <th scope="col">{I18n.t('avg_score', 'Average Score')}</th>
                    <th scope="col">{I18n.t('high_score', 'High Score')}</th>
                    <th scope="col">{I18n.t('low_score', 'Low Score')}</th>
                  </>
                )}
              </tr>
            </thead>
            <tbody>
              <tr data-testid={`student-outcome-rollup-${outcome.id}-data`}>
                {outcomeScore && (
                  <>
                    <td data-testid={`student-outcome-rollup-${outcome.id}-data-average`}>
                      {outcomeScore.average}
                    </td>
                    <td data-testid={`student-outcome-rollup-${outcome.id}-data-max`}>
                      {outcomeScore.max}
                    </td>
                    <td data-testid={`student-outcome-rollup-${outcome.id}-data-min`}>
                      {outcomeScore.min}
                    </td>
                  </>
                )}
              </tr>
            </tbody>
          </table>
        </View>
      )
    }
    return (
      <View as="p" className="student_outcome_selection">
        -
      </View>
    )
  }

  return (
    <View as="div" data-testid="student-outcome-results">
      <View as="div" className="row-fluid">
        <View as="div" className="span4">
          <View as="h2">{I18n.t('Result')}</View>
        </View>
        <View as="div" className="span8 pad-box top-only">
          <View as="p" className="student_outcome_selection" data-testid="student-outcome-title">
            <strong>
              {I18n.t('Results for')}: {outcome.title}
            </strong>
          </View>
          {renderOutcomeResult()}
        </View>
      </View>
    </View>
  )
}

export default OutcomeResult
