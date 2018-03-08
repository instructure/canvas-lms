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
import I18n from 'i18n!link_validator'
var ValidatorResultsRow = React.createClass({
  render() {
    var invalid_links = this.props.result.invalid_links
    var rows = []

    invalid_links.forEach(link => {
      var label, label_elem
      if (link.reason == 'unpublished_item') {
        label = I18n.t('unpublished')
      } else if (link.reason == 'missing_item') {
        label = I18n.t('deleted')
      } else if (link.reason == 'course_mismatch') {
        label = I18n.t('different course')
      }

      if (label) {
        label_elem = <span className="label">{label}</span>
      }

      rows.push(
        <li key={link.url + invalid_links.indexOf(link)}>
          {link.url}
          {!!label_elem && label_elem}
        </li>
      )
    })

    return (
      <div className="result">
        <h4>
          <a href={this.props.result.content_url} target="_blank">
            {this.props.result.name}
          </a>
        </h4>
        <ul>{rows}</ul>
      </div>
    )
  }
})

export default ValidatorResultsRow
