/* eslint-disable react/prop-types */
/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Menu} from '@instructure/ui-menu'
import {Popover} from '@instructure/ui-popover'
import {Text} from '@instructure/ui-text'
import {TruncateText} from '@instructure/ui-truncate-text'
import {memo, useCallback, useEffect, useRef} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('CommentLibrary')

const menuOverrides = {
  maxWidth: '340px',
  minWidth: '280px',
  maxHeight: '200px',
  minHeight: '140px',
}

const menuItemOverrides = {
  labelPadding: '8px',
  padding: '8px',
}

const TruncatedComment = memo(({comment}: {comment: string}) => {
  return (
    <div style={{width: '100%', minHeight: '20px'}} data-testid="truncate-container">
      <TruncateText maxLines={3} position="middle">
        {comment}
      </TruncateText>
    </div>
  )
})

export type SuggestionsProps = {
  searchResults: Array<{comment: string; _id: string}>
  showResults: boolean
  setComment: (comment: string) => void
  onClose: () => void
}

const Suggestions: React.FC<SuggestionsProps> = ({
  searchResults,
  showResults,
  setComment,
  onClose,
}) => {
  const ref = useRef<HTMLDivElement | null>(null)
  const callbackRef = useCallback((node: HTMLDivElement | null) => {
    ref.current = node
  }, [])

  const renderTrigger = useCallback(() => <span ref={callbackRef} />, [callbackRef])

  useEffect(() => {
    const fn = () => {
      if (showResults) onClose()
    }
    document.addEventListener('click', fn)
    return () => {
      document.removeEventListener('click', fn)
    }
  }, [showResults, onClose])

  const header = (
    <>
      <Flex.Item shouldGrow>
        <Text weight="bold">{I18n.t('Insert Comment from Library')}</Text>
      </Flex.Item>
      <CloseButton
        data-testid="close-suggestions"
        screenReaderLabel={I18n.t('Close suggestions')}
        onClick={onClose}
      />
    </>
  )
  return (
    <>
      <span ref={callbackRef} data-testid="comment-suggestions-anchor" />
      <Popover
        renderTrigger={renderTrigger}
        placement="top end"
        isShowingContent={showResults}
        shouldContainFocus
        onBlur={onClose}
        shouldCloseOnDocumentClick
      >
        <Menu
          label={I18n.t('Comment suggestions')}
          onKeyDown={e => {
            if (e.key === 'Escape') onClose()
          }}
          maxHeight="200px"
          themeOverride={menuOverrides}
        >
          <Menu.Group label={header}>
            {searchResults.map(result => (
              <Menu.Item
                key={result._id}
                onSelect={() => setComment(result.comment)}
                data-testid={`comment-suggestion-${result._id}`}
                themeOverride={menuItemOverrides}
              >
                <TruncatedComment comment={result.comment} />
              </Menu.Item>
            ))}
          </Menu.Group>
        </Menu>
      </Popover>
    </>
  )
}

export default memo(Suggestions) as React.FC<SuggestionsProps>
