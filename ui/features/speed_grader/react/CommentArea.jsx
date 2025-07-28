/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import React, {useState, useRef, useCallback} from 'react'
import CanvasRce from '@canvas/rce/react/CanvasRce'
import PropTypes from 'prop-types'
import {TextArea} from '@instructure/ui-text-area'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import CommentLibrary from './CommentLibrary'
import {useScope as createI18nScope} from '@canvas/i18n'
import {EmojiPicker, EmojiQuickPicker} from '@canvas/emoji'
import ReactDOM from 'react-dom'
import {stripHtmlTags} from '@canvas/outcomes/stripHtmlTags'

const I18n = createI18nScope('speed_grader')

function Portal({node, children}) {
  return ReactDOM.createPortal(children, node)
}

const textAreaProps = {
  height: '4rem',
  id: 'speed_grader_comment_textarea',
  label: <ScreenReaderContent>{I18n.t('Add a Comment')}</ScreenReaderContent>,
  placeholder: I18n.t('Add a Comment'),
}

export default function CommentArea({
  getTextAreaRef,
  courseId,
  userId,
  useRCELite,
  handleCommentChange,
  currentText,
  readOnly,
}) {
  const [comment, setComment] = useState('')
  const textAreaRef = useRef()
  const [suggestionsRef, setSuggestionsRef] = useState(null)
  const showCommentLibrary = ENV.assignment_comment_library_feature_enabled

  const setTextAreaRef = el => {
    textAreaRef.current = el
    getTextAreaRef(el)
  }

  const setFocusToTextArea = useCallback(() => {
    if (textAreaRef.current) {
      textAreaRef.current.focus()
    }
  }, [textAreaRef])

  const onSetSuggestionsRef = useCallback(node => {
    setSuggestionsRef(node)
  }, [])

  const handleContentChange = (content, shouldRerender) => {
    setComment(content)
    handleCommentChange(content, shouldRerender)
  }

  const insertEmoji = emoji => {
    if (useRCELite) {
      textAreaRef.current?.editor?.insertContent(emoji.native)
      // handleCommentChange will be called onContentChange
    } else {
      const value = comment + emoji.native
      setComment(value)
      handleCommentChange(value, false)
    }

    if (textAreaRef.current) {
      textAreaRef.current.focus()
    }
  }

  return (
    <>
      {showCommentLibrary && (
        <CommentLibrary
          setFocusToTextArea={setFocusToTextArea}
          setComment={content => handleContentChange(content, useRCELite)}
          courseId={courseId}
          userId={userId}
          commentAreaText={stripHtmlTags(comment)}
          suggestionsRef={suggestionsRef}
        />
      )}
      <div id="textarea-container">
        {useRCELite ? (
          <CanvasRce
            ref={textAreaRef}
            autosave={false}
            defaultContent={currentText}
            height={300}
            textareaId="comment_rce_textarea"
            variant="lite"
            onContentChange={content => handleContentChange(content, false)}
            readOnly={readOnly}
          />
        ) : (
          <TextArea
            value={comment}
            onChange={e => setComment(e.target.value)}
            textareaRef={setTextAreaRef}
            resize="vertical"
            {...textAreaProps}
          />
        )}
        {!!ENV.EMOJIS_ENABLED && (
          <span className={`emoji-picker-container ${useRCELite ? 'with-rce-lite' : ''}`}>
            <EmojiPicker insertEmoji={insertEmoji} />
          </span>
        )}
      </div>
      {!!ENV.EMOJIS_ENABLED && (
        <Portal node={document.getElementById('emoji-quick-picker-container')}>
          <EmojiQuickPicker insertEmoji={insertEmoji} />
        </Portal>
      )}
      {showCommentLibrary && <div ref={onSetSuggestionsRef} id="library-suggestions" />}
    </>
  )
}

CommentArea.propTypes = {
  getTextAreaRef: PropTypes.func.isRequired,
  courseId: PropTypes.string.isRequired,
  userId: PropTypes.string.isRequired,
}
