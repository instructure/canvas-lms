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
import Button from '@instructure/ui-buttons/lib/components/Button'
import {chunk} from 'lodash'
import {DEFAULT_ICON, getIconByType} from '../../../shared/helpers/mimeClassIconHelper'
import FileDrop from '@instructure/ui-forms/lib/components/FileDrop'
import Grid, {GridCol, GridRow} from '@instructure/ui-layout/lib/components/Grid'
import I18n from 'i18n!assignments_2'
import IconTrash from '@instructure/ui-icons/lib/Line/IconTrash'
import mimeClass from 'compiled/util/mimeClass'
import React, {Component} from 'react'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'

export default class ContentUploadTab extends Component {
  state = {
    files: [],
    messages: []
  }

  handleDropAccepted = files => {
    // add a unique index with which to key off of
    let currIndex = this.state.files.length ? this.state.files[this.state.files.length - 1].id : 0
    files.map(file => (file.id = ++currIndex))

    this.setState(prevState => ({
      files: prevState.files.concat(files),
      messages: []
    }))
  }

  handleDropRejected = () => {
    this.setState({
      messages: [
        {
          text: I18n.t('Invalid file type'),
          type: 'error'
        }
      ]
    })
  }

  handleRemoveFile = e => {
    e.preventDefault()
    const fileId = parseInt(e.currentTarget.id, 10)
    const fileIndex = this.state.files.findIndex(file => file.id === fileId)

    this.setState(
      prevState => ({
        files: prevState.files.filter((_, i) => i !== fileIndex),
        messages: []
      }),
      () => {
        const focusElement =
          this.state.files.length === 0 || fileIndex === 0
            ? 'inputFileDrop'
            : this.state.files[fileIndex - 1].id
        document.getElementById(focusElement).focus()
      }
    )
  }

  ellideString = title => {
    if (title.length > 21) {
      return `${title.substr(0, 9)}${I18n.t('...')}${title.substr(-9)}`
    } else {
      return title
    }
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
    const fileRows = chunk(this.state.files, 3)
    return (
      <div data-testid="non-empty-upload">
        <Grid>
          {fileRows.map(row => (
            <GridRow key={row.map(file => file.id).join()}>
              {row.map(file => (
                <GridCol key={file.id} vAlign="bottom">
                  <Billboard
                    heading={I18n.t('Uploaded')}
                    headingLevel="h3"
                    hero={
                      mimeClass(file.type) === 'image' ? (
                        <img
                          alt={I18n.t('%{filename} preview', {filename: file.name})}
                          height="75"
                          src={file.preview}
                          width="75"
                        />
                      ) : (
                        getIconByType(mimeClass(file.type))
                      )
                    }
                    message={
                      <div>
                        <span aria-hidden title={file.name}>
                          {this.ellideString(file.name)}
                        </span>
                        <ScreenReaderContent>{file.name}</ScreenReaderContent>
                        <Button
                          icon={IconTrash}
                          id={file.id}
                          margin="0 0 0 x-small"
                          onClick={this.handleRemoveFile}
                          size="small"
                        >
                          <ScreenReaderContent>
                            {I18n.t('Remove %{filename}', {filename: file.name})}
                          </ScreenReaderContent>
                        </Button>
                      </div>
                    }
                  />
                </GridCol>
              ))}
            </GridRow>
          ))}
        </Grid>
      </div>
    )
  }

  render() {
    return (
      <FileDrop
        allowMultiple
        enablePreview
        id="inputFileDrop"
        label={this.state.files.length ? this.renderUploadedFiles() : this.renderEmptyUpload()}
        messages={this.state.messages}
        onDropAccepted={this.handleDropAccepted}
        onDropRejected={this.handleDropRejected}
      />
    )
  }
}
