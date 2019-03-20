/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import Billboard from '@instructure/ui-billboard/lib/components/Billboard'
import {DEFAULT_ICON, getIconByType} from '../../../shared/helpers/mimeClassIconHelper'
import FileDrop from '@instructure/ui-forms/lib/components/FileDrop'
import I18n from 'i18n!assignments_2'
import mimeClass from 'compiled/util/mimeClass'
import React, {Component} from 'react'

export default class ContentUploadTab extends Component {
  state = {
    files: null,
    messages: []
  }

  handleDropAccepted = files => {
    this.setState({
      files,
      messages: []
    })
  }

  handleDropRejected = () => {
    this.setState({
      files: null,
      messages: [
        {
          text: I18n.t('Invalid file type'),
          type: 'error'
        }
      ]
    })
  }

  renderEmptyUpload() {
    return (
      <div data-testid="empty-upload">
        <Billboard
          heading={I18n.t('Upload File')}
          hero={DEFAULT_ICON}
          message={I18n.t('Drag and drop, or click to browse your computer')}
        />
      </div>
    )
  }

  renderUploadedFiles() {
    return (
      <div data-testid="non-empty-upload">
        <Billboard
          heading={I18n.t('Uploaded')}
          headingLevel="h3"
          hero={
            mimeClass(this.state.files[0].type) === 'image' ? (
              <img
                alt={I18n.t('%{filename} preview', {filename: this.state.files[0].name})}
                height="75"
                src={this.state.files[0].preview}
                width="75"
              />
            ) : (
              getIconByType(mimeClass(this.state.files[0].type))
            )
          }
          message={this.state.files[0].name}
        />
      </div>
    )
  }

  render() {
    return (
      <FileDrop
        enablePreview
        label={this.state.files ? this.renderUploadedFiles() : this.renderEmptyUpload()}
        messages={this.state.messages}
        onDropAccepted={files => this.handleDropAccepted(files)}
        onDropRejected={this.handleDropRejected}
      />
    )
  }
}
