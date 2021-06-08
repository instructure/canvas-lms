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

import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'

export default function PointsDisplay(props) {
  const ungradedVisualString = () => {
    if (props.gradingType === 'points' && props.pointsPossible != null) {
      return I18n.t(
        {one: '*1* Possible Point', other: '*%{count}* Possible Points'},
        {
          count: props.pointsPossible,
          wrappers: ['<span class="points-value">$1</span>']
        }
      ).string
    }

    return ''
  }

  const ungradedScreenreaderString = () => {
    if (props.gradingType === 'points' && props.pointsPossible != null) {
      return I18n.t(
        {one: 'Ungraded, 1 Possible Point', other: 'Ungraded, %{count} Possible Points'},
        {count: props.pointsPossible}
      )
    }

    return I18n.t('ungraded')
  }

  const formatGrade = ({forScreenReader = false} = {}) => {
    if (props.gradingStatus === 'excused') {
      return I18n.t('Excused')
    }

    const formattedGrade = GradeFormatHelper.formatGrade(props.receivedGrade, {
      gradingType: props.gradingType,
      pointsPossible: props.pointsPossible,
      defaultValue: forScreenReader ? ungradedScreenreaderString() : ungradedVisualString(),
      formatType: 'points_out_of_fraction'
    })

    if (props.gradingType === 'points' && props.receivedGrade != null) {
      return I18n.t('%{formattedGrade} *Points*', {
        formattedGrade,
        wrappers: [forScreenReader ? '$1' : '<span class="points-text">$1</span>']
      }).string
    } else {
      return formattedGrade
    }
  }

  return (
    <div>
      <ScreenReaderContent>{formatGrade({forScreenReader: true})}</ScreenReaderContent>
      <Flex aria-hidden="true" direction="column" textAlign="end">
        <Flex.Item>
          <Text
            dangerouslySetInnerHTML={{__html: formatGrade()}}
            data-testid="grade-display"
            lineHeight="fit"
            size="x-large"
            transform="capitalize"
          />
        </Flex.Item>
      </Flex>
    </div>
  )
}

PointsDisplay.propTypes = {
  gradingStatus: PropTypes.oneOf(['needs_grading', 'excused', 'needs_review', 'graded']),
  gradingType: PropTypes.string.isRequired,
  pointsPossible: PropTypes.number,
  receivedGrade: PropTypes.oneOfType([PropTypes.number, PropTypes.string])
}

PointsDisplay.defaultProps = {
  gradingStatus: null,
  gradingType: 'points'
}
