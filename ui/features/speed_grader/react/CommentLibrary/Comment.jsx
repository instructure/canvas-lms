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
import {PresentationContent, ScreenReaderContent} from '@instructure/ui-a11y-content'
import {IconButton, Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {IconTrashLine, IconEditLine} from '@instructure/ui-icons'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {useScope as useI18nScope} from '@canvas/i18n'
import CommentEditView from './CommentEditView'
import shave from '@canvas/shave'

const I18n = useI18nScope('CommentLibrary')

const Comment = ({
  comment,
  onClick,
  onDelete,
  shouldFocus,
  id,
  updateComment,
  setRemovedItemIndex,
}) => {
  const deleteButtonRef = useRef(null)
  const editButtonRef = useRef(null)
  const [hasMounted, setHasMounted] = useState(false)
  const [isEditing, setIsEditing] = useState(false)
  const [isTruncated, setIsTruncated] = useState(false)
  const [isExpanded, setIsExpanded] = useState(false)
  const handleUpdate = truncated => {
    setIsTruncated(truncated)
  }

  const handleDelete = () => {
    // This uses window.confirm due to poor focus
    // behavior caused by using a Tray with a
    // Modal.
    // eslint-disable-next-line no-alert
    const confirmed = window.confirm(I18n.t('Are you sure you want to delete this comment?'))
    if (confirmed) {
      onDelete()
    }
  }

  useEffect(() => {
    setHasMounted(true)
  }, [])

  useEffect(() => {
    if (shouldFocus) {
      deleteButtonRef.current.focus()
      setRemovedItemIndex(null)
    }
  }, [setRemovedItemIndex, shouldFocus])

  useEffect(() => {
    if (hasMounted && !isEditing) {
      editButtonRef.current.focus()
    }
  }, [isEditing]) // eslint-disable-line react-hooks/exhaustive-deps

  if (isEditing) {
    return (
      <CommentEditView
        comment={comment}
        id={id}
        updateComment={updateComment}
        onClose={() => setIsEditing(false)}
      />
    )
  }

  return (
    <View
      as="div"
      position="relative"
      borderWidth="none none small none"
      data-testid="comment-library"
    >
      <Flex>
        <Flex.Item as="div" shouldGrow={true} size="80%" shouldShrink={true}>
          <FocusedComment
            onClick={onClick}
            comment={comment}
            handleUpdate={handleUpdate}
            isExpanded={isExpanded}
          />
        </Flex.Item>
        <Flex.Item size="20%" shouldGrow={true} align="start" textAlign="end">
          <View as="div" display="inline-block" padding="x-small x-small 0 0">
            <IconButton
              screenReaderLabel={I18n.t('Edit comment: %{comment}', {comment})}
              renderIcon={IconEditLine}
              onClick={() => setIsEditing(true)}
              withBackground={false}
              withBorder={false}
              elementRef={el => (editButtonRef.current = el)}
              size="small"
              data-testid="comment-library-edit-button"
            />
          </View>
          <View as="div" display="inline-block" padding="x-small small 0 0">
            <IconButton
              screenReaderLabel={I18n.t('Delete comment: %{comment}', {comment})}
              renderIcon={IconTrashLine}
              onClick={handleDelete}
              withBackground={false}
              withBorder={false}
              elementRef={el => (deleteButtonRef.current = el)}
              size="small"
              data-testid="comment-library-delete-button"
            />
          </View>
          <PresentationContent>
            {isTruncated && (
              <View as="div" insetBlockEnd="12px" insetInlineEnd="20px" position="absolute">
                <Link isWithinText={false} onClick={() => setIsExpanded(!isExpanded)}>
                  {isExpanded ? (
                    <Text size="x-small">{I18n.t('show less')}</Text>
                  ) : (
                    <Text size="x-small">{I18n.t('show more')}</Text>
                  )}
                </Link>
              </View>
            )}
          </PresentationContent>
        </Flex.Item>
      </Flex>
    </View>
  )
}

const FocusedComment = ({onClick, comment, handleUpdate, isExpanded}) => {
  const [isFocused, setIsFocused] = useState(false)
  const commentRef = useRef(null)

  useEffect(() => {
    if (!isExpanded) {
      const truncated = shave(commentRef.current, 70)

      handleUpdate(truncated)
    }
  }, [handleUpdate, isExpanded])

  return (
    <View
      as="div"
      padding="small"
      cursor="pointer"
      isWithinText={false}
      onClick={e => {
        if (e.detail === 1) {
          onClick(comment)
        }
      }}
      background={isFocused ? 'brand' : 'transparent'}
      onMouseEnter={() => setIsFocused(true)}
      onMouseLeave={() => setIsFocused(false)}
      onFocus={() => setIsFocused(true)}
      onBlur={() => setIsFocused(false)}
    >
      <PresentationContent>
        {/* key=isExpanded make sure it'll rebuild this component when key changes */}
        <Text key={isExpanded} wrap="break-word" elementRef={el => (commentRef.current = el)}>
          {comment}
        </Text>
      </PresentationContent>
      <ScreenReaderContent>
        <Button onClick={() => onClick(comment)}>
          {I18n.t('Use comment %{comment}', {comment})}
        </Button>
      </ScreenReaderContent>
    </View>
  )
}

Comment.propTypes = {
  comment: PropTypes.string.isRequired,
  onClick: PropTypes.func.isRequired,
  onDelete: PropTypes.func.isRequired,
  shouldFocus: PropTypes.bool.isRequired,
  id: PropTypes.string.isRequired,
  updateComment: PropTypes.func.isRequired,
  setRemovedItemIndex: PropTypes.func.isRequired,
}

export default Comment
