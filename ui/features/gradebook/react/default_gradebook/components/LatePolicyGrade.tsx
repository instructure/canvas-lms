/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import {Text} from '@instructure/ui-text'
import {useScope as useI18nScope} from '@canvas/i18n'
import type {SubmissionData} from '@canvas/grading/grading.d'
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'

const I18n = useI18nScope('gradebook')

type Props = {
  assignment: {
    pointsPossible: number
  }
  enterGradesAs: 'points' | 'percent' | 'passFail' | 'gradingScheme'
  gradingScheme: Array<Array<string | number>>
  submission: SubmissionData
}

export default function LatePolicyGrade(props: Props) {
  // @ts-expect-error
  const pointsDeducted = I18n.n(-props.submission.pointsDeducted)
  const formatOptions = {
    formatType: props.enterGradesAs,
    pointsPossible: props.assignment.pointsPossible,
    gradingScheme: props.gradingScheme,
    version: 'final',
  }
  const finalGrade = GradeFormatHelper.formatSubmissionGrade(props.submission, formatOptions)

  return (
    <div style={{display: 'flex', flexDirection: 'row'}}>
      <div style={{paddingRight: '.5rem'}}>
        <div>
          <Text color="danger" as="span">
            {I18n.t('Late Penalty:')}
          </Text>
        </div>
        <div>
          <Text color="secondary" as="span">
            {I18n.t('Final Grade:')}
          </Text>
        </div>
      </div>
      <div style={{flex: 1}}>
        <div id="late-penalty-value">
          <Text color="danger" as="span">
            {pointsDeducted}
          </Text>
        </div>
        <div id="final-grade-value">
          <Text color="secondary" as="span">
            {finalGrade}
          </Text>
        </div>
      </div>
    </div>
  )
}
