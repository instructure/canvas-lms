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

import {useScope as createI18nScope} from '@canvas/i18n'
import AbstractTextQuestion from './abstract_text_question'
import React from 'react'

const I18n = createI18nScope('quiz_statistics')

const Essay = props => (
  <AbstractTextQuestion
    {...props}
    linkButtonComponent={props.speedGraderUrl && <SpeedGraderLink {...props} />}
  />
)

const SpeedGraderLink = props => (
  <a
    className="btn"
    href={props.speedGraderUrl}
    target="_blank"
    rel="noopener noreferrer"
    style={{marginBottom: '20px', maxWidth: '50%'}}
  >
    {I18n.t('speedgrader', 'View in SpeedGrader')}
  </a>
)

export default Essay
