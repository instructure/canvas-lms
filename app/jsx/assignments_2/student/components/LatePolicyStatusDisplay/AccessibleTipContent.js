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
import I18n from 'i18n!assignments_2_thing'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import PropTypes from 'prop-types'
import GradeFormatHelper from '../../../../gradebook/shared/helpers/GradeFormatHelper'

function AccessibleTipContent(props) {
  const {gradingType, grade, originalGrade, pointsDeducted, pointsPossible} = props
  return (
    <ScreenReaderContent data-test-id="late-policy-accessible-tip-content">
      {I18n.t('Attempt 1: %{grade}', {
        grade: GradeFormatHelper.formatGrade(originalGrade, {
          gradingType,
          pointsPossible,
          formatType: 'points_out_of_fraction'
        })
      })}
      {I18n.t(
        {one: 'Late Penalty: minus 1 Point', other: 'Late Penalty: minus %{count} Points'},
        {count: pointsDeducted}
      )}
      {I18n.t('Grade: %{grade}', {
        grade: GradeFormatHelper.formatGrade(grade, {
          gradingType,
          pointsPossible,
          formatType: 'points_out_of_fraction'
        })
      })}
    </ScreenReaderContent>
  )
}

AccessibleTipContent.propTypes = {
  grade: PropTypes.oneOfType([PropTypes.number, PropTypes.string]).isRequired,
  gradingType: PropTypes.string.isRequired,
  originalGrade: PropTypes.oneOfType([PropTypes.number, PropTypes.string]).isRequired,
  pointsDeducted: PropTypes.number.isRequired,
  pointsPossible: PropTypes.number.isRequired
}

export default React.memo(AccessibleTipContent)
