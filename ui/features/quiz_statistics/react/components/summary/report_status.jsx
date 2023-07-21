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

import Actions from '../../../actions'
import Descriptor from '../../../backbone/models/quiz_report_descriptor'
import {useScope as useI18nScope} from '@canvas/i18n'
import K from '../../../constants'
import React from 'react'
import PropTypes from 'prop-types'

const I18n = useI18nScope('quiz_reports')

class ReportStatus extends React.Component {
  static propTypes = {
    file: PropTypes.shape({
      createdAt: PropTypes.string,
    }),

    progress: PropTypes.shape({
      workflowState: PropTypes.string,
      completion: PropTypes.number,
    }),
  }

  static defaultProps = {
    file: {},
    progress: {},
  }

  render() {
    const label = Descriptor.getDetailedStatusLabel(this.props)

    return (
      <div className="quiz-report-status">
        {this.props.isGenerating ? this.renderProgress(label) : label}
      </div>
    )
  }

  renderProgress(label) {
    const completion = this.props.progress.completion
    const cancelable = this.props.progress.workflowState === K.PROGRESS_QUEUED

    return (
      <div className="auxiliary">
        <p>
          <span className="screenreader-only">{label}</span>
          <span aria-hidden="true">
            {I18n.t('generating', 'Report is being generated...')}{' '}
            {cancelable && (
              <button type="button" className="btn-link" onClick={this.cancel.bind(this)}>
                {I18n.t('cancel_generation', 'Cancel')}
              </button>
            )}
          </span>
        </p>

        <div className="progress">
          <div className="bar" style={{width: (completion || 0) + '%'}} />
        </div>
      </div>
    )
  }

  cancel() {
    Actions.abortReportGeneration(this.props.id)
  }
}

export default ReportStatus
