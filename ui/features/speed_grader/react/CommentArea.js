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
import PropTypes from 'prop-types'
import {TextArea} from '@instructure/ui-text-area'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import CommentLibrary from './CommentLibrary'
import I18n from 'i18n!speed_grader'

const textAreaProps = {
  height: '4rem',
  id: 'speed_grader_comment_textarea',
  label: <ScreenReaderContent>{I18n.t('Add a Comment')}</ScreenReaderContent>,
  placeholder: I18n.t('Add a Comment'),
  resize: 'vertical'
}

export default function CommentArea({getTextAreaRef, courseId, userId}) {
  const [comment, setComment] = useState('')
  const textAreaRef = useRef()
  const [suggestionsRef, setSuggestionsRef] = useState(null)
  const showCommentLibrary = ENV.assignment_comment_library_feature_enabled

  const setTextAreaRef = el => {
    textAreaRef.current = el
    getTextAreaRef(el)
  }

  const setFocusToTextArea = useCallback(() => {
    textAreaRef.current.focus()
  }, [textAreaRef])

  const onSetSuggestionsRef = useCallback(node => {
    setSuggestionsRef(node)
  }, [])

  return (
    <>
      {showCommentLibrary && (
        <CommentLibrary
          setFocusToTextArea={setFocusToTextArea}
          setComment={setComment}
          courseId={courseId}
          userId={userId}
          commentAreaText={comment}
          suggestionsRef={suggestionsRef}
        />
      )}
      <TextArea
        value={comment}
        onChange={e => setComment(e.target.value)}
        textareaRef={setTextAreaRef}
        {...textAreaProps}
      />
      {showCommentLibrary && <div ref={onSetSuggestionsRef} id="library-suggestions" />}
    </>
  )
}

CommentArea.propTypes = {
  getTextAreaRef: PropTypes.func.isRequired,
  courseId: PropTypes.string.isRequired,
  userId: PropTypes.string.isRequired
}
