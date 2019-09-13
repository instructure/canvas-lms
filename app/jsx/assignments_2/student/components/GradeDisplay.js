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

import {ScreenReaderContent} from '@instructure/ui-a11y'
import {Flex} from '@instructure/ui-layout'
import {Text} from '@instructure/ui-elements'
import GradeFormatHelper from '../../../gradebook/shared/helpers/GradeFormatHelper'

export default function PointsDisplay({displaySize, gradingType, pointsPossible, receivedGrade}) {
  // We need to have a different ungraded values for screenreaders and visual users
  // because voiceover does not read the '–' character in a string like '-/10'
  let ungradedScreenreaderString = null
  let ungradedVisualString = null
  switch (gradingType) {
    case 'points':
      ungradedScreenreaderString = I18n.t('ungraded/%{pointsPossible}', {pointsPossible})
      ungradedVisualString = `–/${pointsPossible}`
      break
    case 'pass_fail':
      ungradedScreenreaderString = I18n.t('ungraded')
      ungradedVisualString = I18n.t('ungraded')
      break
    default:
      ungradedScreenreaderString = I18n.t('ungraded')
      ungradedVisualString = '–'
      break
  }

  const formatGrade = ({forScreenReader}) => {
    const formattedGrade = GradeFormatHelper.formatGrade(receivedGrade, {
      gradingType,
      pointsPossible,
      defaultValue: forScreenReader ? ungradedScreenreaderString : ungradedVisualString,
      formatType: 'points_out_of_fraction'
    })

    if (gradingType === 'points') {
      return I18n.t('%{formattedGrade} Points', {formattedGrade})
    } else {
      return formattedGrade
    }
  }

  return (
    <div>
      <ScreenReaderContent>{formatGrade({forScreenReader: true})}</ScreenReaderContent>
      <Flex aria-hidden="true" direction="column" textAlign="end">
        <Flex.Item>
          <Text transform="capitalize" size={displaySize} data-testid="grade-display">
            {formatGrade({forScreenReader: false})}
          </Text>
        </Flex.Item>
      </Flex>
    </div>
  )
}

PointsDisplay.propTypes = {
  displaySize: PropTypes.string,
  gradingType: PropTypes.string.isRequired,
  receivedGrade: PropTypes.oneOfType([PropTypes.number, PropTypes.string]),
  pointsPossible: PropTypes.number.isRequired
}

PointsDisplay.defaultProps = {
  displaySize: 'x-large',
  gradingType: 'points'
}
