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

import PropTypes from 'prop-types'
import React from 'react'
import I18n from 'i18n!assignments_2_student_points_display'

import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'
import Text from '@instructure/ui-elements/lib/components/Text'
import GradeFormatHelper from '../../../gradebook/shared/helpers/GradeFormatHelper'

const ACCESSIBLE = 'accessible'

function defaultValue(gradingType, pointsPossible, options = {}) {
  switch (gradingType) {
    case 'points':
      return options.content === ACCESSIBLE
        ? I18n.t('ungraded out of %{pointsPossible}', {pointsPossible})
        : `–/${pointsPossible}`
    case 'pass_fail':
      return I18n.t('ungraded')
    default:
      return options.content === ACCESSIBLE ? I18n.t('ungraded') : '–'
  }
}

function PointsDisplay(props) {
  const {gradingType, receivedGrade, pointsPossible} = props

  return (
    <div>
      <ScreenReaderContent>
        {GradeFormatHelper.formatGrade(receivedGrade, {
          gradingType,
          pointsPossible,
          defaultValue: defaultValue(gradingType, pointsPossible, {content: ACCESSIBLE}),
          formatType: 'points_out_of_fraction'
        })}
        {gradingType === 'points' ? I18n.t(' Points') : null}
      </ScreenReaderContent>
      <Flex aria-hidden="true" direction="column" textAlign="end">
        <FlexItem>
          <Text transform="capitalize" size="x-large" data-test-id="grade-display">
            {GradeFormatHelper.formatGrade(receivedGrade, {
              gradingType,
              pointsPossible,
              defaultValue: defaultValue(gradingType, pointsPossible),
              formatType: 'points_out_of_fraction'
            })}
            {gradingType === 'points' ? I18n.t(' Points') : null}
          </Text>
        </FlexItem>
      </Flex>
    </div>
  )
}

PointsDisplay.propTypes = {
  gradingType: PropTypes.string.isRequired,
  receivedGrade: PropTypes.oneOfType([PropTypes.number, PropTypes.string]),
  pointsPossible: PropTypes.number.isRequired
}

PointsDisplay.defaultProps = {
  gradingType: 'points'
}

export default React.memo(PointsDisplay)
