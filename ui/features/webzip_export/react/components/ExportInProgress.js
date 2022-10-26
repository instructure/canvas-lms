/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import ApiProgressBar from '@canvas/progress/react/components/ApiProgressBar'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('webzip_exports')

class ExportInProgress extends React.Component {
  static propTypes = {
    webzip: PropTypes.shape({
      progressId: PropTypes.string.isRequired,
    }),
    loadExports: PropTypes.func.isRequired,
  }

  constructor(props) {
    super(props)
    this.state = {completed: false}
  }

  onComplete = () => {
    this.setState({completed: true})
    this.props.loadExports(this.props.webzip.progressId)
  }

  render() {
    if (!this.props.webzip || this.state.completed) {
      return null
    }

    return (
      <div className="webzipexport__inprogress">
        <span>{I18n.t('Processing')}</span>
        <p>{I18n.t('This may take a while...')}</p>
        <ApiProgressBar
          progress_id={this.props.webzip.progressId}
          onComplete={this.onComplete}
          key={this.props.webzip.progressId}
        />
        <p>
          {I18n.t(`The download process has started. This
          can take a while for large courses. You can leave the
          page and you'll get a notification when the download
          is complete.`)}
        </p>
        <hr />
      </div>
    )
  }
}

export default ExportInProgress
