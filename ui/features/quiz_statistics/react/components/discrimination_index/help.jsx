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

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import PropTypes from 'prop-types'

const I18n = useI18nScope('quiz_statistics.discrimination_index_help')

const Help = ({style}) => (
  <div style={style}>
    <p>
      {I18n.t(`
        This metric provides a measure of how well a single question can tell the
        difference (or discriminate) between students who do well on an exam and
        those who do not.
      `)}
    </p>

    <p>
      {I18n.t(`
        It divides students into three groups based on their score on the whole
        quiz and displays those groups by who answered the question correctly.
      `)}
    </p>

    <p>
      <a
        href={I18n.t('#community.instructor_quiz_statistics')}
        target="_blank"
        rel="noopener noreferrer"
      >
        {I18n.t('Learn more about quiz statistics.')}
      </a>
    </p>
  </div>
)

Help.propTypes = {style: PropTypes.object}

export default Help
