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
import {useScope as createI18nScope} from '@canvas/i18n'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import friendlyBytes from '../../util/friendlyBytes'
import customPropTypes from '../modules/customPropTypes'
import getFileStatus from '../../util/getFileStatus'
import mimeClass from '@canvas/mime/mimeClass'

const I18n = createI18nScope('file_preview')

class FilePreviewInfoPanel extends React.Component {
  static displayName = 'FilePreviewInfoPanel'

  static propTypes = {
    displayedItem: customPropTypes.filesystemObject.isRequired,
    usageRightsRequiredForContext: PropTypes.bool,
  }

  constructor(props) {
    super(props)
    this.displayNameRef = React.createRef()
    this.statusRef = React.createRef()
    this.contentTypeRef = React.createRef()
    this.sizeRef = React.createRef()
    this.dateModifiedRef = React.createRef()
    this.modifedByRef = React.createRef()
    this.licenseNameRef = React.createRef()
    this.legalCopyrightRef = React.createRef()
  }

  render() {
    return (
      <div className="ef-file-preview-information-container">
        <table className="ef-file-preview-infotable">
          <tbody>
            <tr>
              <th scope="row">{I18n.t('Name')}</th>
              <td data-testid="display-name" ref={this.displayNameRef}>
                {this.props.displayedItem.displayName()}
              </td>
            </tr>
            <tr>
              <th scope="row">{I18n.t('Status')}</th>
              <td data-testid="status" ref={this.statusRef}>
                {getFileStatus(this.props.displayedItem)}
              </td>
            </tr>
            <tr>
              <th scope="row">{I18n.t('Kind')}</th>
              <td data-testid="content-type" ref={this.contentTypeRef}>
                {mimeClass.displayName(this.props.displayedItem.get('content-type'))}
              </td>
            </tr>
            <tr>
              <th scope="row">{I18n.t('Size')}</th>
              <td data-testid="size" ref={this.sizeRef}>
                {friendlyBytes(this.props.displayedItem.get('size'))}
              </td>
            </tr>
            <tr>
              <th scope="row">{I18n.t('Date Modified')}</th>
              <td id="dateModified" data-testid="date-modified" ref={this.dateModifiedRef}>
                <FriendlyDatetime dateTime={this.props.displayedItem.get('updated_at')} />
              </td>
            </tr>
            {this.props.displayedItem.get('user') && (
              <tr>
                <th scope="row">{I18n.t('Last Modified By')}</th>
                <td data-testid="modified-by" ref={this.modifedByRef}>
                  <a href={this.props.displayedItem.get('user').html_url}>
                    {this.props.displayedItem.get('user').display_name}
                  </a>
                </td>
              </tr>
            )}
            <tr>
              <th scope="row">{I18n.t('Date Created')}</th>
              <td id="dateCreated" data-testid="date-created">
                <FriendlyDatetime dateTime={this.props.displayedItem.get('created_at')} />
              </td>
            </tr>
            {this.props.usageRightsRequiredForContext && (
              <tr className="FilePreviewInfoPanel__usageRights">
                <th scope="row">{I18n.t('Usage Rights')}</th>
                <td>
                  {this.props.displayedItem &&
                    this.props.displayedItem.get('usage_rights') &&
                    this.props.displayedItem.get('usage_rights').license_name && (
                      <div data-testid="license-name" ref={this.licenseNameRef}>
                        {this.props.displayedItem.get('usage_rights').license_name}
                      </div>
                    )}
                  {this.props.displayedItem &&
                    this.props.displayedItem.get('usage_rights') &&
                    this.props.displayedItem.get('usage_rights').legal_copyright && (
                      <div data-testid="legal-copyright" ref={this.legalCopyrightRef}>
                        {this.props.displayedItem.get('usage_rights').legal_copyright}
                      </div>
                    )}
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    )
  }
}

export default FilePreviewInfoPanel
