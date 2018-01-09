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
import I18n from 'i18n!webzip_exports'
import ExportListItem from '../../webzip_export/components/ExportListItem'
  class ExportList extends React.Component {
    static propTypes = {
      exports: PropTypes.arrayOf(PropTypes.shape({
        date: PropTypes.string.isRequired,
        link: PropTypes.string,
        workflowState: PropTypes.string.isRequired,
        newExport: PropTypes.bool.isRequired
      })).isRequired
    }

    renderExportListItems () {
      return this.props.exports.map((webzip, key) => (
        <ExportListItem
          key={key}
          link={webzip.link}
          date={webzip.date}
          workflowState={webzip.workflowState}
          newExport={webzip.newExport}
        />
      ))
    }

    render () {
      if (this.props.exports.length === 0) {
        return (
          <p className="webzipexport__list">
            {I18n.t('No exports to display')}
          </p>
        )
      }
      return (
        <ul className="webzipexport__list">
          {this.renderExportListItems()}
        </ul>
      )
    }
  }

export default ExportList
