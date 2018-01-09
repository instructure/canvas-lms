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
import I18n from 'i18n!file_preview'
import FriendlyDatetime from '../shared/FriendlyDatetime'
import friendlyBytes from 'compiled/util/friendlyBytes'
import customPropTypes from 'compiled/react_files/modules/customPropTypes'
import getFileStatus from 'compiled/react_files/utils/getFileStatus'
import mimeClass from 'compiled/util/mimeClass'

  var FilePreviewInfoPanel = React.createClass({
    displayName: 'FilePreviewInfoPanel',

    propTypes: {
      displayedItem: customPropTypes.filesystemObject.isRequired,
      usageRightsRequiredForContext: PropTypes.bool
    },

    render () {
      return (
        <div className='ef-file-preview-information-container'>
          <table className='ef-file-preview-infotable'>
            <tbody>
              <tr>
                <th scope='row'>{I18n.t('Name')}</th>
                <td ref='displayName'>{this.props.displayedItem.displayName()}</td>
              </tr>
              <tr>
                <th scope='row'>{I18n.t('Status')}</th>
                <td ref='status'>{getFileStatus(this.props.displayedItem)}</td>
              </tr>
              <tr>
                <th scope='row'>{I18n.t('Kind')}</th>
                <td ref='contentType'>{mimeClass.displayName(this.props.displayedItem.get('content-type'))}</td>
              </tr>
              <tr>
                <th scope='row'>{I18n.t('Size')}</th>
                <td ref='size'>{friendlyBytes(this.props.displayedItem.get('size'))}</td>
              </tr>
              <tr>
                <th scope='row'>{I18n.t('Date Modified')}</th>
                <td id='dateModified' ref='dateModified'><FriendlyDatetime dateTime={this.props.displayedItem.get('updated_at')} /></td>
              </tr>
              {this.props.displayedItem.get('user') && (
                <tr>
                  <th scope='row'>{I18n.t('Last Modified By')}</th>
                  <td ref='modifedBy'>
                    <a href={this.props.displayedItem.get('user').html_url}>{this.props.displayedItem.get('user').display_name}</a>
                  </td>
                </tr>
              )}
              <tr>
                <th scope='row'>{I18n.t('Date Created')}</th>
                <td id= 'dateCreated'><FriendlyDatetime dateTime={this.props.displayedItem.get('created_at')} /></td>
              </tr>
              {this.props.usageRightsRequiredForContext && (
                <tr className='FilePreviewInfoPanel__usageRights'>
                  <th scope='row'>{I18n.t('Usage Rights')}</th>
                  <td>
                    {this.props.displayedItem && this.props.displayedItem.get('usage_rights') && this.props.displayedItem.get('usage_rights').license_name && (
                      <div ref='licenseName'>{this.props.displayedItem.get('usage_rights').license_name}</div>
                    )}
                    {this.props.displayedItem && this.props.displayedItem.get('usage_rights') && this.props.displayedItem.get('usage_rights').legal_copyright && (
                      <div ref='legalCopyright'>{this.props.displayedItem.get('usage_rights').legal_copyright}</div>
                    )}
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      );
    }

  });

export default FilePreviewInfoPanel
