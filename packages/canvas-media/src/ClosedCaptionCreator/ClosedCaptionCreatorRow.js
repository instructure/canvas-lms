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
import React, {Component} from 'react'

import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-layout'
import {IconTrashLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y'
import {Text} from '@instructure/ui-elements'

import SingleSelect from '../shared/SingleSelect'

export default class ClosedCaptionCreatorRow extends Component {
  render() {
    const {
      CLOSED_CAPTIONS_CHOOSE_FILE,
      CLOSED_CAPTIONS_SELECT_LANGUAGE
    } = this.props.uploadMediaTranslations.UploadMediaStrings

    const selectOptions = [
      {id: 'none_selected', label: CLOSED_CAPTIONS_SELECT_LANGUAGE},
      ...this.props.languages
    ]

    return (
      <Flex justifyItems="space-between">
        <Flex.Item size="200px">
          <div style={{paddingRight: '10px'}}>
            <SingleSelect
              liveRegion={this.props.liveRegion}
              options={selectOptions}
              selectedOption={this.props.onOptionSelected}
              renderLabel={
                <ScreenReaderContent>{CLOSED_CAPTIONS_SELECT_LANGUAGE}</ScreenReaderContent>
              }
            />
          </div>
        </Flex.Item>
        <Flex.Item textAlign="start">
          {!this.props.fileSelected ? (
            <>
              <input
                id="attachmentFile"
                accept=".vtt, .srt"
                ref={element => {
                  this.fileInput = element
                }}
                onChange={this.props.onFileSelected}
                style={{
                  display: 'none'
                }}
                type="file"
              />
              <Button
                id="attachmentFileButton"
                onClick={() => {
                  this.fileInput.click()
                }}
                ref={element => {
                  this.attachmentFileButton = element
                }}
              >
                {CLOSED_CAPTIONS_CHOOSE_FILE}
              </Button>
            </>
          ) : (
            <Text>{this.props.selectedFileName}</Text>
          )}
        </Flex.Item>
        <Flex.Item textAlign="end" shrink grow>
          {this.props.renderTrashButton && (
            <Button variant="icon" onClick={this.props.trashButtonOnClick} icon={IconTrashLine}>
              <ScreenReaderContent>Delete Row</ScreenReaderContent>
            </Button>
          )}
        </Flex.Item>
      </Flex>
    )
  }
}
