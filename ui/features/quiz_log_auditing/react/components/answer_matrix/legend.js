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

import Emblem from './emblem'
import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'

const I18n = useI18nScope('quiz_log_auditing.table_view')

/**
 * @class Events.Views.AnswerMatrix.Legend
 *
 * A legend that explains what each type of "answer circle" denotes.
 *
 * @seed
 *   {}
 */
const Legend = () => (
  <dl id="ic-AnswerMatrix__Legend">
    <dt>{I18n.t('legend.empty_circle', 'Empty Circle')}</dt>
    <dd>
      <Emblem />
      {I18n.t('legend.empty_circle_desc', 'An empty answer.')}
    </dd>

    <dt>{I18n.t('legend.dotted_circle', 'Dotted Circle')}</dt>
    <dd>
      <Emblem answered={true} />
      {I18n.t('legend.dotted_circle_desc', 'An answer, regardless of correctness.')}
    </dd>

    <dt>{I18n.t('legend.filled_circle', 'Filled Circle')}</dt>
    <dd>
      <Emblem answered={true} last={true} />
      {I18n.t(
        'legend.filled_circle_desc',
        'The final answer for the question, the one that counts.'
      )}
    </dd>
  </dl>
)

export default Legend
