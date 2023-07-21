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
import _ from 'lodash'
import PropTypes from 'prop-types'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {TextInput} from '@instructure/ui-text-input'
import {Flex} from '@instructure/ui-flex'
import {useScope as useI18nScope} from '@canvas/i18n'

import {assessmentShape} from './types'

const I18n = useI18nScope('edit_rubricPoints')

export const roundIfWhole = n =>
  I18n.toNumber(n, {
    precision: Math.floor(n) === n ? 0 : 2,
    strip_insignificant_zeros: true,
  })
const pointString = points =>
  points.text === null ? roundIfWhole(points.value).toString() : points.text

export const possibleString = possible =>
  I18n.t('%{possible} pts', {
    possible: I18n.toNumber(possible, {precision: 2, strip_insignificant_zeros: true}),
  })

export const scoreString = (points, possible) =>
  I18n.t('%{points} / %{possible}', {
    points: pointString(points),
    possible: possibleString(possible),
  })

const invalid = () => [{text: I18n.t('Invalid score'), type: 'error'}]
const pointError = points => (points.valid ? [] : invalid())

const noExtraCredit = () => [{text: I18n.t('Cannot give outcomes extra credit'), type: 'error'}]
const extraCreditError = (points, possible, allowExtraCredit) =>
  !allowExtraCredit && points.value > possible ? noExtraCredit() : []

const Points = props => {
  const {allowExtraCredit, assessing, assessment, onPointChange, pointsPossible} = props

  if (assessment === null) {
    return <div className="react-rubric-cell graded-points">{possibleString(pointsPossible)}</div>
  } else {
    const points = _.get(assessment, 'points')
    if (!assessing) {
      return (
        <div className="react-rubric-cell graded-points">{scoreString(points, pointsPossible)}</div>
      )
    } else {
      return (
        <div className="react-rubric-cell graded-points">
          <Flex alignItems="end" wrap="wrap">
            <Flex.Item size="4rem" margin="none small none none">
              <TextInput
                display="inline-block"
                renderLabel={<ScreenReaderContent>{I18n.t('Points')}</ScreenReaderContent>}
                messages={[
                  ...pointError(points),
                  ...extraCreditError(points, pointsPossible, allowExtraCredit),
                ]}
                onChange={e => onPointChange(e.target.value)}
                value={pointString(points)}
                width="4rem"
              />
            </Flex.Item>
            <Flex.Item margin="small none none none">
              {`/ ${possibleString(pointsPossible)}`}
            </Flex.Item>
          </Flex>
        </div>
      )
    }
  }
}
Points.propTypes = {
  allowExtraCredit: PropTypes.bool,
  assessing: PropTypes.bool,
  assessment: PropTypes.shape(assessmentShape),
  onPointChange: PropTypes.func,
  pointsPossible: PropTypes.number.isRequired,
}
Points.defaultProps = {
  allowExtraCredit: true,
  assessing: false,
  onPointChange: null,
}

export default Points
