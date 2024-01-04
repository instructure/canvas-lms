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
import {useScope as useI18nScope} from '@canvas/i18n'
import numberFormat from '@canvas/i18n/numberFormat'

import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'

const I18n = useI18nScope('assignments_2_student_points_display')

export default function PointsDisplay(props) {
  const ungradedVisualString = () => {
    if (
      !ENV.restrict_quantitative_data &&
      props.gradingType === 'points' &&
      props.pointsPossible != null
    ) {
      const formattedPoints = numberFormat._format(props.pointsPossible, {
        precision: 2,
        strip_insignificant_zeros: true,
      })
      return I18n.t(
        {one: '*1* Point Possible', other: '*%{formattedPoints}* Points Possible'},
        {
          count: props.pointsPossible,
          formattedPoints,
          wrappers: ['<span class="points-value">$1</span>'],
        }
      )
    }

    return ''
  }

  const ungradedScreenreaderString = () => {
    if (
      !ENV.restrict_quantitative_data &&
      props.gradingType === 'points' &&
      props.pointsPossible != null
    ) {
      const formattedPoints = numberFormat._format(props.pointsPossible, {
        precision: 2,
        strip_insignificant_zeros: true,
      })
      return I18n.t(
        {one: 'Ungraded, 1 Possible Point', other: 'Ungraded, %{formattedPoints} Possible Points'},
        {
          count: props.pointsPossible,
          formattedPoints,
        }
      )
    }

    return I18n.t('ungraded')
  }

  const formatGrade = ({forScreenReader = false} = {}) => {
    if (props.gradingStatus === 'excused') {
      return I18n.t('Excused')
    }

    if (
      ENV.restrict_quantitative_data &&
      GradeFormatHelper.QUANTITATIVE_GRADING_TYPES.includes(props.gradingType) &&
      props.pointsPossible === 0 &&
      props.receivedScore <= 0
    ) {
      return null
    }

    const formattedGrade = GradeFormatHelper.formatGrade(props.receivedGrade, {
      gradingType: props.gradingType,
      pointsPossible: props.pointsPossible,
      score: props.receivedScore != null ? props.receivedScore : null,
      defaultValue: forScreenReader ? ungradedScreenreaderString() : ungradedVisualString(),
      formatType: 'points_out_of_fraction',
      restrict_quantitative_data: ENV.restrict_quantitative_data,
      grading_scheme: ENV.grading_scheme,
    })

    if (
      !ENV.restrict_quantitative_data &&
      props.gradingType === 'points' &&
      props.receivedGrade != null
    ) {
      return I18n.t('*%{formattedGrade}*', {
        formattedGrade,
        wrappers: [
          forScreenReader ? '$1' : '<span class="points-value"><strong>$1</strong> Points</span>',
        ],
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
            size={window.ENV.FEATURES.instui_nav ? 'medium' : 'x-large'}
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
  receivedGrade: PropTypes.oneOfType([PropTypes.number, PropTypes.string]),
  receivedScore: PropTypes.number,
}

PointsDisplay.defaultProps = {
  gradingStatus: null,
  gradingType: 'points',
}
