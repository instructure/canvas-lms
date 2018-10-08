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
import createReactClass from 'create-react-class';
import I18n from 'i18n!react_files'
import classnames from 'classnames'
import UploadProgress from 'compiled/react_files/components/UploadProgress'
import ProgressBar from '../shared/ProgressBar'
import mimeClass from 'compiled/util/mimeClass'

    UploadProgress.renderProgressBar = function () {
      if (this.props.uploader.error) {
        var errorMessage = (this.props.uploader.error.message) ?
                          I18n.t('Error: %{message}', {message: this.props.uploader.error.message}) :
                          I18n.t('Error uploading file.')

        return (
          <span>
            {errorMessage}
            <button type='button' className='btn-link' onClick={ () => this.props.uploader.upload()}>
              {I18n.t('Retry')}
            </button>
          </span>
        );
      } else {
        return <ProgressBar progress={this.props.uploader.roundProgress()} />
      }
    };

    UploadProgress.render = function () {

      var rowClassNames = classnames({
        'ef-item-row': true,
        'text-error': this.props.uploader.error
      });

      return (
        <div className={rowClassNames}>
          <div className='col-xs-6'>
            <div className='media ellipsis'>
              <span className='pull-left'>
                <i className={`media-object mimeClass-${mimeClass(this.props.uploader.file.type)}`} />
              </span>
              <span className='media-body' ref='fileName'>
                {this.props.uploader.getFileName()}
              </span>
            </div>
          </div>
          <div className='col-xs-5'>
            {this.renderProgressBar()}
          </div>
          <button
            type='button'
            onClick={this.props.uploader.cancel}
            aria-label={I18n.t('Cancel')}
            className='btn-link upload-progress-view__button'
          >
            x
          </button>
        </div>
      );
    };

export default createReactClass(UploadProgress);
