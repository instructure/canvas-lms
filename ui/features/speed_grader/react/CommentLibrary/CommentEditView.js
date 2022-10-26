/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import React, {useState, useRef, useEffect} from 'react'
import PropTypes from 'prop-types'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {TextArea} from '@instructure/ui-text-area'
import {View} from '@instructure/ui-view'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('CommentLibrary')

const CommentEditView = ({comment, id, updateComment, onClose}) => {
  const textAreaRef = useRef(null)
  const [isSaving, setIsSaving] = useState(false)
  const [updatedComment, setUpdatedComment] = useState(comment)

  useEffect(() => {
    textAreaRef.current.focus()
  }, [])

  const handleSave = async () => {
    setIsSaving(true)
    await updateComment({variables: {id, comment: updatedComment}})
    onClose()
  }

  const allowSave = !isSaving && updatedComment.length > 0 && updatedComment !== comment

  return (
    <View
      as="div"
      position="relative"
      borderWidth="none none small none"
      padding="small small 0 small"
    >
      <TextArea
        textareaRef={el => (textAreaRef.current = el)}
        value={updatedComment}
        onChange={e => setUpdatedComment(e.target.value)}
        placeholder={I18n.t('Write something...')}
        label={<ScreenReaderContent>{I18n.t('Edit comment')}</ScreenReaderContent>}
        resize="vertical"
        data-testid="comment-library-edit-text-area"
      />
      <Flex justifyItems="end">
        <Flex.Item margin="xxx-small 0 0 xxx-small">
          <Button size="small" margin="small" onClick={onClose}>
            {I18n.t('Cancel')}
          </Button>
        </Flex.Item>
        <Flex.Item margin="xxx-small 0 0 xxx-small">
          <Button
            size="small"
            color="primary"
            onClick={handleSave}
            interaction={allowSave ? 'enabled' : 'disabled'}
            data-testid="comment-library-edit-save-button"
          >
            {I18n.t('Save')}
          </Button>
        </Flex.Item>
      </Flex>
    </View>
  )
}

CommentEditView.propTypes = {
  comment: PropTypes.string.isRequired,
  id: PropTypes.string.isRequired,
  updateComment: PropTypes.func.isRequired,
  onClose: PropTypes.func.isRequired,
}

export default CommentEditView
