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

import React, {useCallback, useEffect, useState} from 'react'
import PropTypes from 'prop-types'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Link} from '@instructure/ui-link'
import {IconCommentLine} from '@instructure/ui-icons'
import {ScreenReaderContent, PresentationContent} from '@instructure/ui-a11y-content'
import {Tooltip} from '@instructure/ui-tooltip'
import Tray from './Tray'
import Suggestions from './Suggestions'
import {useScope as useI18nScope} from '@canvas/i18n'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

const I18n = useI18nScope('CommentLibrary')

const renderTooltip = () => (
  <Tooltip renderTip={I18n.t('Comment Library (Suggestions Disabled)')} on={['hover']}>
    <IconCommentLine />
  </Tooltip>
)

const Library = ({
  comments,
  setComment,
  onAddComment,
  onDeleteComment,
  isAddingComment,
  removedItemIndex,
  showSuggestions,
  setShowSuggestions,
  searchResults,
  setFocusToTextArea,
  updateComment,
  suggestionsRef,
  setRemovedItemIndex,
}) => {
  const [isTrayOpen, setIsTrayOpen] = useState(false)
  const [showResults, setShowResults] = useState(false)

  useEffect(() => {
    const parent = suggestionsRef?.parentNode
    const handleBlur = event => {
      if (!parent.contains(event.relatedTarget)) {
        setShowResults(false)
      }
    }
    if (parent) {
      parent.addEventListener('focusout', handleBlur)
      return () => {
        parent.removeEventListener('focusout', handleBlur)
      }
    }
  }, [suggestionsRef])

  useEffect(() => {
    if (showResults && searchResults.length === 0) {
      setShowResults(false)
    }
    if (searchResults.length > 0) {
      showFlashAlert({
        message: I18n.t(
          'There are new comment suggestions available. Press Tab to access the suggestions menu.'
        ),
        srOnly: true,
      })
      setShowResults(true)
    }
  }, [searchResults]) // eslint-disable-line react-hooks/exhaustive-deps

  const handleCommentClick = comment => {
    if (isTrayOpen) {
      setIsTrayOpen(false)
    }
    setComment(comment)
  }

  const setCommentFromSuggestion = useCallback(
    comment => {
      setShowResults(false)
      setComment(comment)
    },
    [setComment]
  )

  const closeSuggestions = useCallback(() => {
    setShowResults(false)
    setFocusToTextArea()
  }, [setFocusToTextArea])

  return (
    <>
      <Flex direction="row-reverse" padding="medium 0 xx-small small">
        <Flex.Item>
          <View as="div" padding="0 0 0 x-small" display="flex">
            <Link
              isWithinText={false}
              onClick={() => setIsTrayOpen(true)}
              renderIcon={showSuggestions ? <IconCommentLine /> : renderTooltip()}
              iconPlacement="start"
              data-testid="comment-library-link"
            >
              <ScreenReaderContent>{I18n.t('Open Comment Library')}</ScreenReaderContent>
              <PresentationContent data-testid="comment-library-count">
                {I18n.n(comments.length)}
              </PresentationContent>
            </Link>
            {showSuggestions && suggestionsRef && (
              <Suggestions
                searchResults={searchResults}
                setComment={setCommentFromSuggestion}
                closeSuggestions={closeSuggestions}
                showResults={showResults}
                suggestionsRef={suggestionsRef}
              />
            )}
          </View>
        </Flex.Item>
      </Flex>
      <Tray
        isOpen={isTrayOpen}
        comments={comments}
        isAddingComment={isAddingComment}
        onAddComment={onAddComment}
        onItemClick={handleCommentClick}
        onDeleteComment={onDeleteComment}
        setIsOpen={setIsTrayOpen}
        removedItemIndex={removedItemIndex}
        showSuggestions={showSuggestions}
        setShowSuggestions={setShowSuggestions}
        updateComment={updateComment}
        setRemovedItemIndex={setRemovedItemIndex}
      />
    </>
  )
}

Library.propTypes = {
  comments: PropTypes.arrayOf(
    PropTypes.shape({
      comment: PropTypes.string.isRequired,
      _id: PropTypes.string.isRequired,
    })
  ).isRequired,
  setComment: PropTypes.func.isRequired,
  isAddingComment: PropTypes.bool.isRequired,
  onAddComment: PropTypes.func.isRequired,
  onDeleteComment: PropTypes.func.isRequired,
  removedItemIndex: PropTypes.number,
  showSuggestions: PropTypes.bool.isRequired,
  setShowSuggestions: PropTypes.func.isRequired,
  searchResults: PropTypes.array.isRequired,
  setFocusToTextArea: PropTypes.func.isRequired,
  updateComment: PropTypes.func.isRequired,
  suggestionsRef: PropTypes.object,
  setRemovedItemIndex: PropTypes.func.isRequired,
}

export default Library
