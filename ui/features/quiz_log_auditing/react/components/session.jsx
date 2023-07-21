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

import Actions from '../../actions'
import Button from './button'
import Config from '../../config'
import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import ScreenReaderContent from '@canvas/quiz-legacy-client-apps/react/components/screen_reader_content'
import {IconRefreshLine} from '@instructure/ui-icons'
import {Link} from 'react-router-dom'

const I18n = useI18nScope('quiz_log_auditing')

class Session extends React.Component {
  static defaultProps = {
    submission: {},
    availableAttempts: [],
  }

  state = {
    accessibilityWarningFocused: false,
  }

  render() {
    let accessibilityWarningClasses = 'ic-QuizInspector__accessibility-warning'
    if (!this.state.accessibilityWarningFocused) {
      accessibilityWarningClasses += ' screenreader-only'
    }

    const warningMessage = I18n.t(
      'links.log_accessibility_warning',
      'Warning: For improved accessibility when using Quiz Logs, please remain in the current Stream View.'
    )

    return (
      <div id="ic-QuizInspector__Session">
        <div className="ic-QuizInspector__Header">
          <h1>{I18n.t('page_header', 'Session Information')}</h1>

          <div className="ic-QuizInspector__HeaderControls">
            <Button onClick={Actions.reloadEvents}>
              <ScreenReaderContent>{I18n.t('buttons.reload_events', 'Reload')}</ScreenReaderContent>
              <IconRefreshLine />
            </Button>{' '}
            {Config.allowMatrixView && (
              <span>
                <span
                  id="refreshButtonDescription"
                  // eslint-disable-next-line jsx-a11y/no-noninteractive-tabindex
                  tabIndex="0"
                  className={accessibilityWarningClasses}
                  onFocus={this.toggleViewable.bind(this)}
                  onBlur={this.toggleViewable.bind(this)}
                  aria-label={warningMessage}
                >
                  {warningMessage}
                </span>
                <Link
                  data-testid="view-table-button"
                  to={{pathname: '/answer_matrix', search: window.location.search}}
                  className="btn btn-default"
                  aria-describedby="refreshButtonDescription"
                >
                  {I18n.t('buttons.table_view', 'View Table')}
                </Link>
              </span>
            )}
          </div>
        </div>

        <table>
          <tbody>
            <tr>
              <th scope="row">{I18n.t('session_table_headers.started_at', 'Started at')}</th>
              <td>{new Date(this.props.submission.startedAt).toString()}</td>
            </tr>

            <tr>
              <th scope="row">{I18n.t('session_table_headers.attempt', 'Attempt')}</th>
              <td>
                <div id="ic-QuizInspector__AttemptController">
                  {this.props.availableAttempts.map(this.renderAttemptLink.bind(this))}
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    )
  }

  renderAttemptLink(attempt) {
    let className = 'ic-AttemptController__Attempt'

    if (attempt === this.props.attempt) {
      className += ' ic-AttemptController__Attempt--is-active'

      return (
        <div data-testid="current-attempt" className={className} key={'attempt-' + attempt}>
          {attempt}
        </div>
      )
    } else {
      return (
        <Link
          data-testid={`attempt-${attempt}`}
          key={attempt}
          to={{
            pathname: '/',
            search: `?attempt=${attempt}`,
          }}
          className={className}
        >
          {attempt}
        </Link>
      )
    }
  }

  toggleViewable() {
    this.setState(state => ({
      accessibilityWarningFocused: !state.accessibilityWarningFocused,
    }))
  }
}

export default Session
