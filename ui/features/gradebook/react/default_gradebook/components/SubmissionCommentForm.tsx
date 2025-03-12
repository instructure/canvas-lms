/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import {useScope as createI18nScope} from '@canvas/i18n'
import {TextArea} from '@instructure/ui-text-area'
import {Button} from '@instructure/ui-buttons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {EmojiPicker, EmojiQuickPicker} from '@canvas/emoji'
import CanvasRce from '@canvas/rce/react/CanvasRce'
import styled from 'styled-components'
import {stripHtmlTags} from '@canvas/util/TextHelper'
import RCEWrapper from '@instructure/canvas-rce/es/rce/RCEWrapper'
import {Editor} from 'tinymce'
import {ViewProps} from '@instructure/ui-view'

const StyledEmojiPickerContainer = styled.span.attrs<{$useRCELite?: boolean}>(props => ({
  style: {
    bottom: props.$useRCELite ? '55px' : '0px',
    right: props.$useRCELite ? '0px' : '10px',
  },
}))`
  position: absolute;
`

const I18n = createI18nScope('gradebook')

type Props = {
  cancelCommenting: () => void
  comment?: string
  processing: boolean
  setProcessing: (processing: boolean) => void
}

type State = {
  comment: string
  rceKey: number
}

type InsertEmojiParams = {native: string}

export default abstract class SubmissionCommentForm extends React.Component<Props, State> {
  textarea: HTMLTextAreaElement | null = null
  rceRef: React.RefObject<RCEWrapper> = React.createRef()
  tinyeditor: Editor | null = null

  constructor(props: Props) {
    super(props)
    const methodsToBind = [
      'bindTextarea',
      'focusTextarea',
      'handleCancel',
      'handleCommentChange',
      'handlePublishComment',
      'handleRCEFocus',
      'initRCE',
      'insertEmoji',
      'isRceLiteEnabled',
      'mapCommentValueToInputValue',
    ]
    methodsToBind.forEach(method => {
      // @ts-expect-error
      this[method] = this[method].bind(this)
    })

    // RCE input has to be rerendered if state update happens from outside
    this.state = {comment: this.mapCommentValueToInputValue(props.comment || ''), rceKey: 0}
  }

  abstract initRCE(tinyeditor: Editor): void
  abstract buttonLabels(): {cancelButtonLabel: string; submitButtonLabel: string}
  abstract showButtons(): boolean
  abstract publishComment(): Promise<void> | void

  isRceLiteEnabled() {
    return ENV.FEATURES?.rce_lite_enabled_speedgrader_comments
  }

  mapCommentValueToInputValue(value: string) {
    return this.isRceLiteEnabled() ? value : (stripHtmlTags(value) ?? '')
  }

  focusTextarea() {
    this.textarea?.focus()
  }

  handleCancel(
    e: React.KeyboardEvent<ViewProps> | React.MouseEvent<ViewProps>,
    callback?: () => void,
  ) {
    e.preventDefault()

    this.handleCommentChange(this.props.comment || '', {
      rerenderRCE: true,
      callback: () => {
        this.props.cancelCommenting()
        callback?.()
      },
    })
  }

  handleCommentChange(
    value: string,
    {rerenderRCE, callback}: {rerenderRCE?: boolean; callback?: () => void} = {},
  ) {
    this.setState({comment: value, rceKey: this.state.rceKey + (rerenderRCE ? 1 : 0)}, () => {
      callback?.()
    })
  }

  insertEmoji(emoji: InsertEmojiParams) {
    this.handleCommentChange(this.state.comment + emoji.native, {rerenderRCE: true})
    // input should be focused after inserting an emoji
    // regular textarea is refocused using this.focusTextarea()
    // RCE is rerendered on emoji insertion, and it is refocused automatically by onInit
    if (!this.isRceLiteEnabled()) this.focusTextarea()
  }

  handlePublishComment(e: React.KeyboardEvent<ViewProps> | React.MouseEvent<ViewProps>) {
    e.preventDefault()
    this.props.setProcessing(true)
    this.publishComment()?.catch(() => this.props.setProcessing(false))
  }

  commentIsValid() {
    const comment = this.state.comment.trim()
    return comment.length > 0
  }

  handleRCEFocus() {
    this.tinyeditor?.selection.select(this.tinyeditor.getBody(), true)
    this.tinyeditor?.selection.collapse(false)
  }

  bindTextarea(ref: HTMLTextAreaElement | null) {
    this.textarea = ref
  }

  render() {
    const {cancelButtonLabel, submitButtonLabel} = this.buttonLabels()

    return (
      <div>
        <div id="textarea-container">
          {this.isRceLiteEnabled() ? (
            <CanvasRce
              key={this.state.rceKey}
              ref={this.rceRef}
              autosave={false}
              defaultContent={this.state.comment}
              height={300}
              textareaId="comment_rce_textarea"
              variant="lite"
              onContentChange={this.handleCommentChange}
              onFocus={this.handleRCEFocus}
              onInit={this.initRCE}
            />
          ) : (
            <TextArea
              data-testid="comment-textarea"
              label={<ScreenReaderContent>{I18n.t('Leave a comment')}</ScreenReaderContent>}
              placeholder={I18n.t('Leave a comment')}
              onChange={e => this.handleCommentChange(e.target.value)}
              value={this.state.comment}
              textareaRef={this.bindTextarea}
              resize="vertical"
            />
          )}
          {!!ENV.EMOJIS_ENABLED && (
            <StyledEmojiPickerContainer $useRCELite={this.isRceLiteEnabled()}>
              <EmojiPicker insertEmoji={this.insertEmoji} />
            </StyledEmojiPickerContainer>
          )}
        </div>
        {!!ENV.EMOJIS_ENABLED && (
          <div id="emoji-quick-picker-container">
            <EmojiQuickPicker insertEmoji={this.insertEmoji} />
          </div>
        )}
        {this.showButtons() && (
          <div
            style={{
              textAlign: 'right',
              marginTop: '0rem',
              border: 'none',
              padding: '0rem',
              background: 'transparent',
            }}
          >
            <Button
              data-testid="comment-cancel-button"
              disabled={this.props.processing}
              label={cancelButtonLabel}
              margin="small small small 0"
              onClick={this.handleCancel}
            >
              {I18n.t('Cancel')}
            </Button>

            <Button
              data-testid="comment-submit-button"
              disabled={this.props.processing || !this.commentIsValid()}
              label={submitButtonLabel}
              margin="small 0"
              onClick={this.handlePublishComment}
              color="primary"
            >
              {I18n.t('Submit')}
            </Button>
          </div>
        )}
      </div>
    )
  }
}
