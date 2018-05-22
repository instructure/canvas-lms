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
import PropTypes from 'prop-types'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import TextInput from '@instructure/ui-forms/lib/components/TextInput'
import I18n from 'i18n!edit_rubric'

export const roundIfWhole = (n) => (
  I18n.toNumber(n, { precision: Math.floor(n) === n ? 0 : 1 })
)
const pointString = (n) => n !== null ? roundIfWhole(n) : ''

export const possibleString = (possible) =>
  I18n.t('/ %{possible} pts', {
    possible: I18n.toNumber(possible, { precision : 1 })
  })

const invalid = () => [{ text: I18n.t('Invalid value'), type: 'error' }]
const messages = (points) => points === null ? invalid() : undefined

const Points = ({ assessing, onPointChange, points, pointsText, pointsPossible }) => {
  if (!assessing) {
    return (
      <div className="container graded-points">
        {roundIfWhole(points)} {possibleString(pointsPossible)}
      </div>
    )
  } else {
    return (
      <div className="container graded-points">
        <TextInput
          inline
          label={<ScreenReaderContent>{I18n.t('Points')}</ScreenReaderContent>}
          messages={messages(points)}
          onChange={(e) => onPointChange(e.target.value)}
          value={pointsText || pointString(points)}
          width="4rem"
        /> {possibleString(pointsPossible)}
      </div>
    )
  }
}
Points.propTypes = {
  assessing: PropTypes.bool,
  onPointChange: PropTypes.func,
  points: PropTypes.number,
  pointsPossible: PropTypes.number.isRequired,
  pointsText: PropTypes.string,
}
Points.defaultProps = {
  assessing: false,
  points: null,
  pointsText: null,
  onPointChange: null
}

export default Points
