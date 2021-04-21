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
import {arrayOf, func, objectOf, shape, string} from 'prop-types'
import formatMessage from 'format-message'

import {Button, IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconTrashLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

import CanvasSelect from '../shared/CanvasSelect'

export default class ClosedCaptionCreatorRow extends Component {
  static propTypes = {
    languages: arrayOf(
      shape({
        id: string,
        label: string
      })
    ),
    liveRegion: func,
    uploadMediaTranslations: shape({
      UploadMediaStrings: objectOf(string),
      SelectStrings: objectOf(string)
    }),
    onDeleteRow: func,
    onFileSelected: func,
    onLanguageSelected: func,
    selectedFile: shape({name: string.isRequired}), // there's more, but his is all I care about
    selectedLanguage: shape({id: string.isRequired, label: string.isRequired})
  }

  _langSelectRef = React.createRef()

  _deleteCCBtnRef = React.createRef()

  handleLanguageChange = (event, selectedLang) => {
    this.props.onLanguageSelected(this.props.languages.find(l => l.id === selectedLang))
  }

  handleDeleteRow = _e => {
    this.props.onDeleteRow(this.props.selectedLanguage.id)
  }

  get isReadonly() {
    return this.props.selectedFile && this.props.selectedLanguage
  }

  focus() {
    if (this._langSelectRef.current) {
      this._langSelectRef.current.focus()
    } else if (this._deleteCCBtnRef.current) {
      this._deleteCCBtnRef.current.focus()
    }
  }

  renderChoosing() {
    return (
      <Flex
        as="div"
        wrap="wrap"
        justifyItems="start"
        alignItems="end"
        data-testid="CC-CreatorRow-choosing"
      >
        {this.renderSelectLanguage()}
        {this.renderChooseFile()}
      </Flex>
    )
  }

  renderSelectLanguage() {
    const {CLOSED_CAPTIONS_SELECT_LANGUAGE} = this.props.uploadMediaTranslations.UploadMediaStrings
    return (
      <Flex.Item margin="0 small small 0">
        <CanvasSelect
          ref={this._langSelectRef}
          value={this.props.selectedLanguage?.id}
          label={<ScreenReaderContent>{CLOSED_CAPTIONS_SELECT_LANGUAGE}</ScreenReaderContent>}
          liveRegion={this.props.liveRegion}
          onChange={this.handleLanguageChange}
          placeholder={CLOSED_CAPTIONS_SELECT_LANGUAGE}
          translatedStrings={this.props.uploadMediaTranslations.SelectStrings}
        >
          {this.props.languages.map(o => {
            return (
              <CanvasSelect.Option key={o.id} id={o.id} value={o.id}>
                {o.label}
              </CanvasSelect.Option>
            )
          })}
        </CanvasSelect>
      </Flex.Item>
    )
  }

  renderChooseFile() {
    const {
      NO_FILE_CHOSEN,
      SUPPORTED_FILE_TYPES,
      CLOSED_CAPTIONS_CHOOSE_FILE
    } = this.props.uploadMediaTranslations.UploadMediaStrings

    return (
      <Flex.Item margin="0 small small 0">
        <input
          id="attachmentFile"
          accept=".vtt, .srt"
          ref={element => {
            this.fileInput = element
          }}
          onChange={e => {
            this.props.onFileSelected(e.target.files[0])
          }}
          style={{display: 'none'}}
          type="file"
        />
        <View as="div">
          <Text as="div">{SUPPORTED_FILE_TYPES}</Text>
          <Button
            margin="xx-small 0 0 0"
            id="attachmentFileButton"
            onClick={() => {
              this.fileInput.click()
            }}
            ref={element => {
              this.attachmentFileButton = element
            }}
          >
            {this.props.selectedFile ? this.props.selectedFile.name : CLOSED_CAPTIONS_CHOOSE_FILE}
          </Button>
          {!this.props.selectedFile && (
            <View display="inline-block" margin="0 0 0 small">
              <Text color="secondary">{NO_FILE_CHOSEN}</Text>
            </View>
          )}
        </View>
      </Flex.Item>
    )
  }

  renderChosen() {
    const {REMOVE_FILE} = this.props.uploadMediaTranslations.UploadMediaStrings

    return (
      <Flex
        as="div"
        wrap="wrap"
        justifyItems="start"
        alignItems="end"
        data-testid="CC-CreatorRow-chosen"
      >
        <Flex.Item margin="0 0 small 0">
          <View
            as="div"
            borderWidth="small"
            padding="0 0 0 small"
            borderRadius="medium"
            width="100%"
          >
            <Flex justifyItems="space-between">
              <Flex.Item>
                <Text weight="bold">{this.props.selectedLanguage.label}</Text>
              </Flex.Item>
              <Flex.Item margin="0 0 0 x-small">
                <IconButton
                  ref={this._deleteCCBtnRef}
                  withBackground={false}
                  withBorder={false}
                  onClick={this.handleDeleteRow}
                  screenReaderLabel={formatMessage(REMOVE_FILE, {
                    lang: this.props.selectedLanguage.label
                  })}
                >
                  <IconTrashLine />
                </IconButton>
              </Flex.Item>
            </Flex>
          </View>
        </Flex.Item>
      </Flex>
    )
  }

  render() {
    return this.isReadonly ? this.renderChosen() : this.renderChoosing()
  }
}
