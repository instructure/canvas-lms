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
import {Tooltip} from '@instructure/ui-tooltip'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import LatePolicyToolTipContent from './LatePolicyToolTipContent'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

import {Link} from '@instructure/ui-link'

const I18n = useI18nScope('a2LatePolicyStatusDisplay')

export default function LatePolicyStatusDisplay(props) {
  // TODO: actually pass the assignment and submission in here instead of all these
  //       separate props
  const {attempt, gradingType, grade, originalGrade, pointsDeducted, pointsPossible} = props
  return (
    <div data-testid="late-policy-container">
      <Flex justifyItems="end">
        <Flex.Item padding="none xxx-small none none">
          <Text size="medium">{I18n.t('Late Policy:')}</Text>
        </Flex.Item>
        <Flex.Item>
          <Tooltip
            renderTip={
              <LatePolicyToolTipContent
                attempt={attempt}
                grade={grade}
                gradingType={gradingType}
                originalGrade={originalGrade}
                pointsDeducted={pointsDeducted}
                pointsPossible={pointsPossible}
              />
            }
            on={['hover', 'focus']}
            placement="start"
          >
            <Link
              href="#"
              isWithinText={false}
              themeOverride={{mediumPaddingHorizontal: '0', mediumHeight: 'normal'}}
            >
              <ScreenReaderContent>
                {I18n.t(
                  {one: 'Late Policy: minus 1 Point', other: 'Late Policy: minus %{count} Points'},
                  {count: props.pointsDeducted}
                )}
              </ScreenReaderContent>
              <Text aria-hidden="true" size="medium">
                {I18n.t(
                  {one: '-1 Point', other: '-%{count} Points'},
                  {count: props.pointsDeducted}
                )}
              </Text>
            </Link>
          </Tooltip>
        </Flex.Item>
      </Flex>
    </div>
  )
}

LatePolicyStatusDisplay.propTypes = {
  attempt: PropTypes.number.isRequired,
  grade: PropTypes.oneOfType([PropTypes.number, PropTypes.string]).isRequired,
  gradingType: PropTypes.string.isRequired,
  originalGrade: PropTypes.oneOfType([PropTypes.number, PropTypes.string]).isRequired,
  pointsDeducted: PropTypes.number,
  pointsPossible: PropTypes.number.isRequired,
}

LatePolicyStatusDisplay.defaultProps = {
  pointsDeducted: 0,
}
