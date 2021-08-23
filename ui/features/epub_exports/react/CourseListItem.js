/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import React from 'react'
import PropTypes from 'prop-types'
import _ from 'underscore'
import GenerateLink from './GenerateLink'
import DownloadLink from './DownloadLink'
import ApiProgressBar from '@canvas/progress/react/components/ApiProgressBar'
import CourseEpubExportStore from './CourseStore'
import I18n from 'i18n!epub_exports'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import classnames from 'classnames'

class CourseListItem extends React.Component {
  static displayName = 'CourseListItem'

  static propTypes = {
    course: PropTypes.object.isRequired
  }

  epubExport = () => this.props.course.epub_export || {}

  //
  // Rendering
  //

  getDisplayState = () => {
    let state

    if (_.isEmpty(this.epubExport())) {
      return null
    }

    switch (this.epubExport().workflow_state) {
      case 'generated':
        state = I18n.t('Generated:')
        break
      case 'failed':
        state = I18n.t('Failed:')
        break
      default:
        state = I18n.t('Generating:')
    }
    return state
  }

  getDisplayTimestamp = () => {
    let timestamp

    if (_.isEmpty(this.epubExport())) {
      return null
    }
    timestamp = this.epubExport().updated_at

    return <FriendlyDatetime dateTime={timestamp} />
  }

  render() {
    const course = this.props.course,
      classes = {
        'ig-row': true
      }
    classes[this.epubExport().workflow_state] = !_.isEmpty(this.epubExport())

    return (
      <li>
        <div className={classnames(classes)}>
          <div className="ig-row__layout">
            <span className="ig-title">{course.name}</span>
            <div className="ig-details">
              <div className="ellipses">
                {this.getDisplayState()} {this.getDisplayTimestamp()}
              </div>
            </div>
            <div className="ig-admin epub-exports-admin-controls">
              <ApiProgressBar
                progress_id={this.epubExport().progress_id}
                onComplete={this._onComplete}
                key={this.epubExport().progress_id}
              />
              <DownloadLink course={this.props.course} />
              <GenerateLink course={this.props.course} />
            </div>
          </div>
        </div>
      </li>
    )
  }

  //
  // Callbacks
  //

  _onComplete = () => {
    CourseEpubExportStore.get(this.props.course.id, this.epubExport().id)
  }
}

export default CourseListItem
