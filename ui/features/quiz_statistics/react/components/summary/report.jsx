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

import Descriptor from '../../../backbone/models/quiz_report_descriptor'
import Popup from '../popup'
import Dispatcher from '../../../dispatcher'
import React from 'react'
import PropTypes from 'prop-types'
import ScreenReaderContent from '@canvas/quiz-legacy-client-apps/react/components/screen_reader_content'
import SightedUserContent from '@canvas/quiz-legacy-client-apps/react/components/sighted_user_content'
import ReportStatus from './report_status'

class Report extends React.Component {
  static propTypes = {
    generatable: PropTypes.bool,
    readableType: PropTypes.string,
    isGenerated: PropTypes.bool,
  }

  static defaultProps = {
    readableType: 'Analysis Report',
    generatable: true,
    isGenerated: false,
  }

  componentDidUpdate(prevProps /* , prevState */) {
    // Restore focus to the generation button which is now the download button
    if (!prevProps.isGenerated && this.props.isGenerated) {
      if (this.refs.popup.screenReaderContentHasFocus()) {
        this.refs.popup.focusAnchor()
      }
    } else if (!prevProps.isGenerating && this.props.isGenerating) {
      if (!this.refs.popup.screenReaderContentHasFocus()) {
        this.refs.popup.focusScreenReaderContent(true)
      }
    }
  }

  render() {
    return (
      <div className="report-generator inline">
        <Popup
          ref="popup"
          content={ReportStatus}
          id={this.props.id}
          isGenerated={this.props.isGenerated}
          isGenerating={this.props.isGenerating}
          generatable={this.props.generatable}
          progress={this.props.progress}
          file={this.props.file}
          reactivePositioning={true}
          anchorSelector=".btn"
          popupOptions={{
            show: {
              event: 'mouseenter focusin',
              delay: 0,
              effect: false,
              solo: true,
            },

            hide: {
              event: 'mouseleave focusout',
              delay: 350,
              effect: false,
              fixed: true,
            },

            position: {
              my: 'bottom center',
              at: 'top center',
            },
          }}
        >
          {this.props.isGenerated ? this.renderDownloader() : this.renderGenerator()}
        </Popup>
      </div>
    )
  }

  renderGenerator() {
    const srLabel = Descriptor.getInteractionLabel(this.props)

    return (
      <button
        type="button"
        disabled={!this.props.generatable}
        onClick={this.generate.bind(this)}
        onKeyPress={this.generateAndFocusContent.bind(this)}
        className="btn generate-report"
      >
        <ScreenReaderContent>{srLabel}</ScreenReaderContent>
        <SightedUserContent>
          <i className="icon-analytics" /> {this.props.readableType}
        </SightedUserContent>
      </button>
    )
  }

  renderDownloader() {
    const srLabel = Descriptor.getInteractionLabel(this.props)

    return (
      <a href={this.props.file.url} className="btn download-report">
        <ScreenReaderContent>{srLabel}</ScreenReaderContent>

        <SightedUserContent>
          <i className="icon-analytics" /> {this.props.readableType}
        </SightedUserContent>
      </a>
    )
  }

  generate(e) {
    e.preventDefault()

    Dispatcher.dispatch('quizReports:generate', this.props.reportType)
  }

  generateAndFocusContent(e) {
    e.preventDefault()

    Dispatcher.dispatch('quizReports:generate', this.props.reportType)
  }
}

export default Report
