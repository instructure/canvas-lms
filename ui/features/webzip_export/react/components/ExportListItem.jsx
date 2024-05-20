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
import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import '@canvas/datetime/jquery'

const I18n = useI18nScope('webzip_exports')

// eslint-disable-next-line react/prefer-stateless-function
class ExportListItem extends React.Component {
  static propTypes = {
    date: PropTypes.string.isRequired,
    link: PropTypes.string.isRequired,
    workflowState: PropTypes.string.isRequired,
    newExport: PropTypes.bool.isRequired,
  }

  render() {
    let text = <span>{I18n.t('Package export from')}</span>
    let body = <a href={this.props.link}>{$.datetimeString(this.props.date)}</a>
    if (this.props.workflowState === 'failed') {
      text = <span className="text-error">{I18n.t('Export failed')}</span>
      body = $.datetimeString(this.props.date)
    } else if (this.props.newExport) {
      text = <span>{I18n.t('Most recent export')}</span>
    }
    return (
      <li className="webzipexport__list__item">
        {text}
        <span>: {body}</span>
      </li>
    )
  }
}

export default ExportListItem
