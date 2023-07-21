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
import {useScope as useI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import React from 'react'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'
import AccessibleTipContent from './AccessibleTipContent'

const I18n = useI18nScope('a2LatePolicyToolTipContent')

export default function LatePolicyToolTipContent(props) {
  // TODO - At this point we really should just pass in the whole assignment and
  //        submission into this component and let it grab the data itself.
  const {attempt, gradingType, grade, originalGrade, pointsDeducted, pointsPossible} = props
  return (
    <>
      <AccessibleTipContent
        attempt={attempt}
        grade={grade}
        gradingType={gradingType}
        originalGrade={originalGrade}
        pointsDeducted={pointsDeducted}
        pointsPossible={pointsPossible}
      />
      <Flex
        aria-hidden="true"
        data-testid="late-policy-tip-content"
        margin="x-small"
        direction="column"
      >
        <Flex.Item>
          <Flex>
            <Flex.Item margin="0 small 0 0">
              <Text size="small">{I18n.t('Attempt %{attempt}', {attempt})}</Text>
            </Flex.Item>
            <Flex.Item shouldGrow={true} textAlign="end">
              <Text size="small">
                {GradeFormatHelper.formatGrade(originalGrade, {
                  gradingType,
                  pointsPossible,
                  formatType: 'points_out_of_fraction',
                })}
              </Text>
            </Flex.Item>
          </Flex>
        </Flex.Item>
        <Flex.Item>
          <Flex>
            <Flex.Item margin="0 small 0 0">
              <Text size="small">{I18n.t('Late Penalty')}</Text>
            </Flex.Item>
            <Flex.Item shouldGrow={true} textAlign="end">
              <Text size="small">
                {pointsDeducted ? `-${props.pointsDeducted}` : I18n.t('None')}
              </Text>
            </Flex.Item>
          </Flex>
        </Flex.Item>
        <Flex.Item>
          <Flex>
            <Flex.Item margin="0 small 0 0">
              <Text size="small">{I18n.t('Grade')}</Text>
            </Flex.Item>
            <Flex.Item shouldGrow={true} textAlign="end">
              <Text size="small">
                {GradeFormatHelper.formatGrade(grade, {
                  gradingType,
                  pointsPossible,
                  formatType: 'points_out_of_fraction',
                })}
              </Text>
            </Flex.Item>
          </Flex>
        </Flex.Item>
      </Flex>
    </>
  )
}

LatePolicyToolTipContent.propTypes = {
  attempt: PropTypes.number.isRequired,
  grade: PropTypes.oneOfType([PropTypes.number, PropTypes.string]).isRequired,
  gradingType: PropTypes.string.isRequired,
  originalGrade: PropTypes.oneOfType([PropTypes.number, PropTypes.string]).isRequired,
  pointsDeducted: PropTypes.number.isRequired,
  pointsPossible: PropTypes.number.isRequired,
}
