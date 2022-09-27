/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import PropTypes from 'prop-types'
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'

const I18n = useI18nScope('a2_AccessibleTipContent')

export default function AccessibleTipContent(props) {
  const {attempt, gradingType, grade, originalGrade, pointsDeducted, pointsPossible} = props
  return (
    <ScreenReaderContent data-testid="late-policy-accessible-tip-content">
      {I18n.t('Attempt %{attempt}: %{grade}', {
        attempt,
        grade: GradeFormatHelper.formatGrade(originalGrade, {
          gradingType,
          pointsPossible,
          formatType: 'points_out_of_fraction',
        }),
      })}
      {I18n.t(
        {
          one: 'Late Penalty: minus 1 Point',
          other: 'Late Penalty: minus %{count} Points',
          zero: 'Late Penalty: None',
        },
        {count: pointsDeducted || 0}
      )}
      {I18n.t('Grade: %{grade}', {
        grade: GradeFormatHelper.formatGrade(grade, {
          gradingType,
          pointsPossible,
          formatType: 'points_out_of_fraction',
        }),
      })}
    </ScreenReaderContent>
  )
}

AccessibleTipContent.propTypes = {
  attempt: PropTypes.number.isRequired,
  grade: PropTypes.oneOfType([PropTypes.number, PropTypes.string]).isRequired,
  gradingType: PropTypes.string.isRequired,
  originalGrade: PropTypes.oneOfType([PropTypes.number, PropTypes.string]).isRequired,
  pointsDeducted: PropTypes.number.isRequired,
  pointsPossible: PropTypes.number.isRequired,
}
