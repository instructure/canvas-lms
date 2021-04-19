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
import I18n from 'i18n!epub_exports'
import _ from 'underscore'

class DownloadLink extends React.Component {
  static displayName = 'DownloadLink'

  static propTypes = {
    course: PropTypes.object.isRequired
  }

  epubExport = () => this.props.course.epub_export || {}

  showDownloadLink = () =>
    _.isObject(this.epubExport().permissions) && this.epubExport().permissions.download

  //
  // Rendering
  //

  downloadLink = (attachment, message) => {
    if (_.isObject(attachment)) {
      return (
        <a href={attachment.url} className="icon-download">
          {message}
        </a>
      )
    } else {
      return null
    }
  }

  render() {
    if (!this.showDownloadLink()) {
      return null
    }

    return (
      <span>
        {this.downloadLink(this.epubExport().epub_attachment, I18n.t('Download ePub'))}
        {this.downloadLink(this.epubExport().zip_attachment, I18n.t('Download Associated Files'))}
      </span>
    )
  }
}

export default DownloadLink
