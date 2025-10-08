/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

const I18n = createI18nScope('assignments.no_assignments_search')

export default function NoAssignmentsSearch() {
  return (
    <div>
      <div className="ig-header">
        <h2 className="ig-header-title" aria-label={I18n.t('Assignments')}>
          <i className="icon-mini-arrow-down"></i>
          {I18n.t('Assignments')}
        </h2>
      </div>
      <ul className="ig-list">
        <li>
          <div className="ig-row ig-row-empty">
            <div className="ig-empty-msg" data-testid="no-assignments-found">
              {I18n.t('No assignments found')}
            </div>
          </div>
        </li>
      </ul>
    </div>
  )
}
