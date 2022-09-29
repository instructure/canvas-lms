/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

// This is now just a text element, not a donut chart.
// Name is retained to avoid a larger refactor.

import React from 'react'
import PropTypes from 'prop-types'
import round from '@canvas/quiz-legacy-client-apps/util/round'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('quiz_statistics')

const CorrectAnswerDonut = props => {
  return (
    <section className="correct-answer-ratio-section">
      <p>
        {I18n.t('%{ratio}% answered correctly', {
          ratio: round(props.correctResponseRatio * 100.0, 0),
        })}
      </p>
    </section>
  )
}

CorrectAnswerDonut.propTypes = {
  correctResponseRatio: PropTypes.number.isRequired,
}

export default CorrectAnswerDonut
