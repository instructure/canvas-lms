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

import React, {memo, useEffect, useCallback, useState} from 'react'
import {CloseButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {TruncateText} from '@instructure/ui-truncate-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Menu} from '@instructure/ui-menu'
import {Popover} from '@instructure/ui-popover'
import {InstUISettingsProvider} from '@instructure/emotion'

const I18n = createI18nScope('CommentLibrary')

const componentOverrides = {
  [Menu.componentId]: {
    maxWidth: '340px',
    minWidth: '280px',
    maxHeight: '200px',
    minHeight: '140px',
  },
  [Menu.Item.componentId]: {
    labelPadding: '8px',
    padding: '8px',
  },
}

interface SearchResult {
  comment: string
  _id: string
}

interface SuggestionsProps {
  searchResults: SearchResult[]
  showResults: boolean
  setComment: (comment: string) => void
  closeSuggestions: () => void
  suggestionsRef: HTMLElement | null
}

const Suggestions = ({
  searchResults,
  showResults,
  setComment,
  closeSuggestions,
  suggestionsRef,
}: SuggestionsProps) => {
  const [mountRef, setMountRef] = useState<HTMLDivElement | null>(null)
  useEffect(() => {
    // Hide/show suggestions div when showResults changes
    // There is an arrow that appears from the popover that needs to be hidden
    // when not showing results.
    if (suggestionsRef) {
      const ref = suggestionsRef
      ref.style.visibility = showResults ? 'visible' : 'hidden'
    }
  }, [showResults, suggestionsRef])

  const onSetMountRef = useCallback((node: HTMLDivElement | null) => {
    setMountRef(node)
  }, [])

  const suggestionsPosition = suggestionsRef?.getBoundingClientRect()
  const inlinePosition = mountRef?.getBoundingClientRect()

  const header = () => (
    <>
      <Text weight="bold">{I18n.t('Insert Comment from Library')}</Text>
      <CloseButton
        placement="end"
        screenReaderLabel={I18n.t('Close suggestions')}
        onClick={closeSuggestions}
      />
    </>
  )
  return (
    <>
      <Popover
        placement="top center"
        shouldRenderOffscreen={true}
        isShowingContent={true}
        offsetY={(suggestionsPosition?.y ?? 0) - (inlinePosition?.y ?? 0)}
        mountNode={() => suggestionsRef}
        onHideContent={() => showResults && closeSuggestions()}
      >
        {showResults && (
          <InstUISettingsProvider theme={{componentOverrides}}>
            <Menu show={showResults} label={I18n.t('Comment suggestions')} onToggle={() => {}}>
              <Menu.Group label={header()}>
                {searchResults.map(result => (
                  <Menu.Item
                    as="span"
                    selected={false}
                    key={result._id}
                    onSelect={_e => setComment(result.comment)}
                    data-testid="comment-suggestion"
                  >
                    <TruncateText maxLines={3}>{result.comment}</TruncateText>
                  </Menu.Item>
                ))}
              </Menu.Group>
            </Menu>
          </InstUISettingsProvider>
        )}
      </Popover>
      <div ref={onSetMountRef} />
    </>
  )
}

export default memo(Suggestions)
