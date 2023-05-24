// @ts-nocheck
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

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'

const I18n = useI18nScope('modules')

type Props = {
  needsGrading: {
    id: string
    name: string
    due_at: string
    needs_grading_count: number
  }[]
  leaveNeedsGradingPage: () => void
}

class PostGradesDialogNeedsGradingPage extends React.Component<Props> {
  onClickRow = assignment_id => {
    window.location.href = `gradebook/speed_grader?assignment_id=${assignment_id}`
  }

  render() {
    return (
      <div>
        <small>
          <em className="text-left" style={{color: '#555555'}}>
            {I18n.t(
              'NOTE: Students have submitted work for these assignments' +
                'that has not been graded. If you post these grades now, you' +
                'will need to re-post their scores after grading their' +
                'latest submissions.'
            )}
          </em>
        </small>
        <br />
        <br />
        <table className="ic-Table ic-Table--hover-row ic-Table--condensed">
          <tbody>
            <thead>
              <td>{I18n.t('Assignment Name')}</td>
              <td>{I18n.t('Due Date')}</td>
              <td>{I18n.t('Ungraded Submissions')}</td>
            </thead>
            {this.props.needsGrading.map(a => (
              <tr className="clickable-row" onClick={this.onClickRow.bind(this, a.id)}>
                <td>{a.name}</td>
                <td>{I18n.l('#date.formats.full', a.due_at)}</td>
                <td>{a.needs_grading_count}</td>
              </tr>
            ))}
          </tbody>
        </table>
        <form className="form-horizontal form-dialog form-inline">
          <div className="form-controls">
            <button
              type="button"
              className="btn btn-primary"
              onClick={this.props.leaveNeedsGradingPage}
            >
              {I18n.t('Continue')}&nbsp;
              <i className="icon-arrow-right" />
            </button>
          </div>
        </form>
      </div>
    )
  }
}

export default PostGradesDialogNeedsGradingPage
