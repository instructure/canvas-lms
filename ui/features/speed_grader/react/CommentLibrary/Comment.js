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
import {IconTrashLine} from '@instructure/ui-icons'
import {TruncateText} from '@instructure/ui-truncate-text'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import I18n from 'i18n!CommentLibrary'

const Comment = ({comment, onClick, onDelete, shouldFocus}) => {
  const deleteButtonRef = useRef(null)
  const [isTruncated, setIsTruncated] = useState(false)
  const [isExpanded, setIsExpanded] = useState(false)
  const [isFocused, setIsFocused] = useState(false)
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
    if (shouldFocus) {
      deleteButtonRef.current.focus()
    }
  }, [shouldFocus])

  return (
    <View as="div" position="relative" borderWidth="none none small none">
      <Flex>
        <Flex.Item as="div" shouldGrow size="80%" shouldShrink>
          <View
            as="div"
            padding="small"
            cursor="pointer"
            isWithinText={false}
            onClick={() => onClick(comment)}
            background={isFocused ? 'brand' : 'transparent'}
            onMouseEnter={() => setIsFocused(true)}
            onMouseLeave={() => setIsFocused(false)}
            onFocus={() => setIsFocused(true)}
            onBlur={() => setIsFocused(false)}
          >
            <PresentationContent>
              {!isExpanded ? (
                <TruncateText onUpdate={handleUpdate} maxLines={4}>
                  {comment}
                </TruncateText>
              ) : (
                <Text wrap="break-word">{comment}</Text>
              )}
            </PresentationContent>
            <ScreenReaderContent>
              <Button onClick={() => onClick(comment)}>
                {I18n.t('Use comment %{comment}', {comment})}
              </Button>
            </ScreenReaderContent>
          </View>
        </Flex.Item>
        <Flex.Item size="20%" shouldGrow align="start" textAlign="end">
          <View as="div" padding="x-small small 0 0">
            <IconButton
              screenReaderLabel={I18n.t('Delete comment: %{comment}', {comment})}
              renderIcon={IconTrashLine}
              onClick={handleDelete}
              withBackground={false}
              withBorder={false}
              elementRef={el => (deleteButtonRef.current = el)}
              size="small"
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

Comment.propTypes = {
  comment: PropTypes.string.isRequired,
  onClick: PropTypes.func.isRequired,
  onDelete: PropTypes.func.isRequired,
  shouldFocus: PropTypes.bool.isRequired
}

export default Comment
