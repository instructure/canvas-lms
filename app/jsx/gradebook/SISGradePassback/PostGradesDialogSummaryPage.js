/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import _ from 'underscore'
import I18n from 'i18n!modules'
import React from 'react'

export default function PostGradesDialogSummaryPage(props) {
  return (
    <div className="post-summary text-center">
      <h1 className="lead">
        <span className="assignments-to-post-count">
          {I18n.t(
            {
              one: 'You are ready to sync 1 assignment.',
              other: 'You are ready to sync %{count} assignments.'
            },
            {count: props.postCount}
          )}
        </span>
      </h1>

      <h4 style={{color: '#AAAAAA'}}>
        {props.needsGradingCount > 0 ? (
          <button className="btn btn-link" onClick={props.advanceToNeedsGradingPage}>
            {I18n.t(
              'assignments_to_grade',
              {
                one: '1 assignment has ungraded submissions',
                other: '%{count} assignments have ungraded submissions'
              },
              {count: props.needsGradingCount}
            )}
          </button>
        ) : null}
      </h4>
      <form className="form-horizontal form-dialog form-inline">
        <div className="form-controls">
          <button type="button" className="btn btn-primary" onClick={props.postGrades}>
            {I18n.t('Sync Grades')}
          </button>
        </div>
      </form>
    </div>
  )
}
