// @ts-nocheck
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
import {useScope as useI18nScope} from '@canvas/i18n'
import {TextArea} from '@instructure/ui-text-area'
import {Button} from '@instructure/ui-buttons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {EmojiPicker, EmojiQuickPicker} from '@canvas/emoji'

const I18n = useI18nScope('gradebook')

type Props = {
  cancelCommenting: () => void
  comment?: string
  processing: boolean
  setProcessing: (processing: boolean) => void
}

type State = {
  comment: string
}

export default class SubmissionCommentForm extends React.Component<Props, State> {
  textarea: HTMLTextAreaElement | null = null

  constructor(props: Props) {
    super(props)
    const methodsToBind = [
      'bindTextarea',
      'handleCancel',
      'handleCommentChange',
      'handlePublishComment',
      'insertEmoji',
      'focusTextarea',
    ]
    methodsToBind.forEach(method => {
      this[method] = this[method].bind(this)
    })
    this.state = {comment: props.comment || ''}
  }

  focusTextarea() {
    this.textarea?.focus()
  }

  handleCancel(event: Event, callback) {
    event.preventDefault()

    this.setState({comment: this.props.comment || ''}, () => {
      this.props.cancelCommenting()
      if (callback) {
        callback()
      }
    })
  }

  handleCommentChange(event) {
    this.setState({comment: event.target.value})
  }

  insertEmoji(emoji) {
    const value = this.state.comment + emoji.native
    this.handleCommentChange({target: {value}})
    this.focusTextarea()
  }

  handlePublishComment(event) {
    event.preventDefault()
    this.props.setProcessing(true)
    this.publishComment().catch(() => this.props.setProcessing(false))
  }

  commentIsValid() {
    const comment = this.state.comment.trim()
    return comment.length > 0
  }

  bindTextarea(ref) {
    this.textarea = ref
  }

  render() {
    const {cancelButtonLabel, submitButtonLabel} = this.buttonLabels()
    return (
      <div>
        <div id="textarea-container">
          <TextArea
            label={<ScreenReaderContent>{I18n.t('Leave a comment')}</ScreenReaderContent>}
            placeholder={I18n.t('Leave a comment')}
            onChange={this.handleCommentChange}
            value={this.state.comment}
            textareaRef={this.bindTextarea}
          />
          {!!ENV.EMOJIS_ENABLED && (
            <span id="emoji-picker-container">
              <EmojiPicker insertEmoji={this.insertEmoji} />
            </span>
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
