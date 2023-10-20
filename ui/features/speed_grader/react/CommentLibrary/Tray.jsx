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

import React, {useEffect, useRef} from 'react'
import PropTypes from 'prop-types'
import {ScreenReaderContent, PresentationContent} from '@instructure/ui-a11y-content'
import {Checkbox} from '@instructure/ui-checkbox'
import {IconButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Tray as InstuiTray} from '@instructure/ui-tray'
import {IconArrowOpenStartLine} from '@instructure/ui-icons'
import {useScope as useI18nScope} from '@canvas/i18n'
import Comment from './Comment'
import TrayTextArea from './TrayTextArea'

const I18n = useI18nScope('CommentLibrary')

const Tray = ({
  isOpen,
  setIsOpen,
  onItemClick,
  comments,
  onDeleteComment,
  onAddComment,
  isAddingComment,
  removedItemIndex,
  showSuggestions,
  setShowSuggestions,
  updateComment,
  setRemovedItemIndex,
}) => {
  const closeButtonRef = useRef(null)
  useEffect(() => {
    if (removedItemIndex === 0 && comments.length === 0 && isOpen) {
      closeButtonRef.current.focus()
      setRemovedItemIndex(null)
    }
  }, [removedItemIndex]) // eslint-disable-line react-hooks/exhaustive-deps

  return (
    <InstuiTray
      size="regular"
      label={I18n.t('Comment Library')}
      placement="end"
      open={isOpen}
      onDismiss={() => setIsOpen(false)}
    >
      <View as="div" padding="small">
        <Flex direction="column" as="div">
          <Flex.Item textAlign="center" as="header">
            <View as="div" padding="small 0 medium xx-small">
              <div style={{float: 'left', margin: '6px'}}>
                <IconButton
                  size="small"
                  screenReaderLabel={I18n.t('Close comment library')}
                  renderIcon={IconArrowOpenStartLine}
                  withBorder={false}
                  withBackground={false}
                  elementRef={el => (closeButtonRef.current = el)}
                  onClick={() => setIsOpen(false)}
                  data-testid="close-comment-library-button"
                />
              </div>
              <View display="inline-block" margin="0 auto">
                <Text weight="bold" size="medium" as="h2">
                  {I18n.t('Manage Comment Library')}
                </Text>
              </View>
            </View>
            <View
              textAlign="start"
              as="div"
              padding="0 0 medium small"
              borderWidth="none none medium none"
            >
              <PresentationContent>
                <View as="div" display="inline-block">
                  <Text size="small" weight="bold">
                    {I18n.t('Show suggestions when typing')}
                  </Text>
                </View>
              </PresentationContent>
              <div
                style={{display: 'inline-block', float: 'right'}}
                data-testid="comment-suggestions-when-typing"
              >
                <Checkbox
                  label={
                    <ScreenReaderContent>
                      {I18n.t('Show suggestions when typing')}
                    </ScreenReaderContent>
                  }
                  variant="toggle"
                  size="small"
                  inline={true}
                  onChange={e => setShowSuggestions(e.target.checked)}
                  checked={showSuggestions}
                />
              </div>
            </View>
          </Flex.Item>
          <Flex.Item size="65vh" shouldGrow={true} data-testid="library-comment-area">
            {comments.map((commentItem, index) => {
              const shouldFocus =
                removedItemIndex !== null && index === Math.max(removedItemIndex - 1, 0)
              return (
                <Comment
                  key={commentItem._id}
                  onClick={onItemClick}
                  id={commentItem._id}
                  onDelete={() => onDeleteComment(commentItem._id)}
                  comment={commentItem.comment}
                  shouldFocus={shouldFocus}
                  updateComment={updateComment}
                  setRemovedItemIndex={setRemovedItemIndex}
                />
              )
            })}
          </Flex.Item>
          <Flex.Item padding="medium small small small">
            <TrayTextArea onAdd={onAddComment} isAdding={isAddingComment} />
          </Flex.Item>
        </Flex>
      </View>
    </InstuiTray>
  )
}

Tray.propTypes = {
  comments: PropTypes.arrayOf(
    PropTypes.shape({
      comment: PropTypes.string.isRequired,
      _id: PropTypes.string.isRequired,
    })
  ).isRequired,
  isOpen: PropTypes.bool.isRequired,
  onItemClick: PropTypes.func.isRequired,
  setIsOpen: PropTypes.func.isRequired,
  onAddComment: PropTypes.func.isRequired,
  onDeleteComment: PropTypes.func.isRequired,
  isAddingComment: PropTypes.bool.isRequired,
  removedItemIndex: PropTypes.number,
  showSuggestions: PropTypes.bool.isRequired,
  setShowSuggestions: PropTypes.func.isRequired,
  updateComment: PropTypes.func.isRequired,
  setRemovedItemIndex: PropTypes.func.isRequired,
}

Tray.defaultProps = {
  removedItemIndex: null,
}

export default Tray
