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
import {arrayOf, bool, func, objectOf, shape, string, element, oneOfType} from 'prop-types'
import {StyleSheet, css} from 'aphrodite'
import {Alert} from '@instructure/ui-alerts'
import {Button, IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Tooltip} from '@instructure/ui-tooltip'
import {IconTrashLine, IconQuestionLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import formatMessage from '../format-message'
import CanvasSelect from '../shared/CanvasSelect'
import {CC_FILE_MAX_BYTES} from '../shared/constants'

export default class ClosedCaptionCreatorRow extends Component {
  static propTypes = {
    languages: arrayOf(
      shape({
        id: string,
        label: string,
      })
    ),
    liveRegion: func,
    uploadMediaTranslations: shape({
      UploadMediaStrings: objectOf(string),
      SelectStrings: objectOf(string),
    }),
    onDeleteRow: func,
    onFileSelected: func,
    onLanguageSelected: func,
    selectedFile: shape({name: string.isRequired}), // there's more, but his is all I care about
    selectedLanguage: shape({id: string.isRequired, label: string.isRequired}),
    inheritedCaption: bool,
    mountNode: oneOfType([element, func]),
  }

  styles = StyleSheet.create({
    messageErrorContainer: {
      position: 'relative',
      minWidth: '350px',
    },
    messageErrorContent: {
      marginTop: '0.5rem',
      position: 'absolute',
      botton: 0,
      left: 0,
    },
  })

  constructor(props) {
    super(props)

    this.state = {
      isValidCC: true,
      messageErrorCC: '',
    }
  }

  _langSelectRef = React.createRef()

  _deleteCCBtnRef = React.createRef()

  handleLanguageChange = (event, selectedLang) => {
    this.props.onLanguageSelected(this.props.languages.find(l => l.id === selectedLang))
  }

  handleDeleteRow = _e => {
    this.props.onDeleteRow(this.props.selectedLanguage.id)
  }

  handleUploadClosedCaption = event => {
    const uploadedCCFileSize = event.target.files[0].size
    const maxCCFileSize = CC_FILE_MAX_BYTES

    if (maxCCFileSize && uploadedCCFileSize > maxCCFileSize) {
      this.props.onFileSelected(null)
      const fileSizeMessageError = formatMessage(
        'The selected file exceeds the {maxSize} Byte limit',
        {
          maxSize: maxCCFileSize,
        }
      )
      this.setState({
        isValidCC: false,
        messageErrorCC: fileSizeMessageError,
      })
    } else {
      this.props.onFileSelected(event.target.files[0])
      this.setState({
        isValidCC: true,
        messageErrorCC: '',
      })
    }
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
          mountNode={this.props.mountNode}
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
    const {NO_FILE_CHOSEN, SUPPORTED_FILE_TYPES, CLOSED_CAPTIONS_CHOOSE_FILE} =
      this.props.uploadMediaTranslations.UploadMediaStrings
    return (
      <Flex.Item margin="0 small small 0">
        <input
          id="attachmentFile"
          accept=".vtt, .srt"
          ref={element => {
            this.fileInput = element
          }}
          onChange={this.handleUploadClosedCaption}
          style={{display: 'none'}}
          type="file"
        />
        <View as="div">
          <Text as="div">{SUPPORTED_FILE_TYPES}</Text>
          <Button
            id="attachmentFileButton"
            onClick={() => {
              this.fileInput.click()
            }}
            ref={element => {
              this.attachmentFileButton = element
            }}
          >
            {this.props.selectedFile ? this.props.selectedFile.name : CLOSED_CAPTIONS_CHOOSE_FILE}
            <ScreenReaderContent>{this.state.messageErrorCC}</ScreenReaderContent>
          </Button>
          {!this.props.selectedFile && (
            <View display="inline-block" margin="0 0 0 small">
              <Text color="secondary">{NO_FILE_CHOSEN}</Text>
            </View>
          )}
          {!this.state.isValidCC && (
            <View as="div" className={css(this.styles.messageErrorContainer)}>
              <div className={css(this.styles.messageErrorContent)}>
                <Text color="danger">{this.state.messageErrorCC}</Text>
                <Alert
                  variant="error"
                  screenReaderOnly={true}
                  isLiveRegionAtomic={true}
                  liveRegion={this.props.liveRegion}
                >
                  {this.state.messageErrorCC}
                </Alert>
              </div>
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
        alignItems="start"
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
                    lang: this.props.selectedLanguage.label,
                  })}
                  disabled={this.props.inheritedCaption}
                >
                  <IconTrashLine />
                </IconButton>
              </Flex.Item>
            </Flex>
          </View>
        </Flex.Item>
        {this.props.inheritedCaption && (
          <Tooltip
            renderTip={
              <Text>
                {formatMessage('Captions inherited from a parent course cannot be removed.')}
                <br />
                {formatMessage('You can replace by uploading a new caption file.')}
              </Text>
            }
          >
            <IconButton
              withBackground={false}
              withBorder={false}
              screenReaderLabel={this.props.selectedLanguage.label}
            >
              <IconQuestionLine size="x-small" color="brand" />
            </IconButton>
          </Tooltip>
        )}
      </Flex>
    )
  }

  render() {
    return (
      <Flex as="div" display="flex" direction="column" width="100%">
        {this.isReadonly ? this.renderChosen() : this.renderChoosing()}
      </Flex>
    )
  }
}
