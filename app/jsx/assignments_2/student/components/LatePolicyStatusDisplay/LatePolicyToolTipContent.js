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
import I18n from 'i18n!assignments_2_thing'
import PropTypes from 'prop-types'
import React from 'react'
import Text from '@instructure/ui-elements/lib/components/Text'
import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'
import GradeFormatHelper from '../../../../gradebook/shared/helpers/GradeFormatHelper'
import AccessibleTipContent from './AccessibleTipContent'

function LatePolicyToolTipContent(props) {
  const {gradingType, grade, originalGrade, pointsDeducted, pointsPossible} = props
  return (
    <React.Fragment>
      <AccessibleTipContent
        grade={grade}
        gradingType={gradingType}
        originalGrade={originalGrade}
        pointsDeducted={pointsDeducted}
        pointsPossible={pointsPossible}
      />
      <Flex
        aria-hidden="true"
        data-test-id="late-policy-tip-content"
        margin="x-small"
        direction="column"
      >
        <FlexItem>
          <Flex>
            <FlexItem margin="0 small 0 0">
              <Text size="small">{I18n.t('Attempt 1')}</Text>
            </FlexItem>
            <FlexItem grow textAlign="end">
              <Text size="small">
                {GradeFormatHelper.formatGrade(originalGrade, {
                  gradingType,
                  pointsPossible,
                  formatType: 'points_out_of_fraction'
                })}
              </Text>
            </FlexItem>
          </Flex>
        </FlexItem>
        <FlexItem>
          <Flex>
            <FlexItem margin="0 small 0 0">
              <Text size="small">{I18n.t('Late Penalty')}</Text>
            </FlexItem>
            <FlexItem grow textAlign="end">
              <Text size="small">-{props.pointsDeducted}</Text>
            </FlexItem>
          </Flex>
        </FlexItem>
        <FlexItem>
          <Flex>
            <FlexItem margin="0 small 0 0">
              <Text size="small">{I18n.t('Grade')}</Text>
            </FlexItem>
            <FlexItem grow textAlign="end">
              <Text size="small">
                {GradeFormatHelper.formatGrade(grade, {
                  gradingType,
                  pointsPossible,
                  formatType: 'points_out_of_fraction'
                })}
              </Text>
            </FlexItem>
          </Flex>
        </FlexItem>
      </Flex>
    </React.Fragment>
  )
}

LatePolicyToolTipContent.propTypes = {
  grade: PropTypes.oneOfType([PropTypes.number, PropTypes.string]).isRequired,
  gradingType: PropTypes.string.isRequired,
  originalGrade: PropTypes.oneOfType([PropTypes.number, PropTypes.string]).isRequired,
  pointsDeducted: PropTypes.number.isRequired,
  pointsPossible: PropTypes.number.isRequired
}

export default React.memo(LatePolicyToolTipContent)
