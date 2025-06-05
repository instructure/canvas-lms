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

import classNames from 'classnames'
import React, {useLayoutEffect, useRef, useContext} from 'react'
import {DiscussionManagerUtilityContext} from '../../utils/constants'
import theme from '@instructure/canvas-theme'
import {scrollToHighlight} from './ScrollToHighlight'

interface HighlightProps {
  /**
   * Boolean to define if the Highlight is highlighted.
   */
  isHighlighted?: boolean
  children?: React.ReactNode
  discussionEntryId?: string
}

export function Highlight({isHighlighted = false, children, discussionEntryId}: HighlightProps) {
  const highlightRef = useRef<HTMLDivElement>(null)
  const urlParams = new URLSearchParams(window.location.search)
  const isPersistEnabled = urlParams.get('persist') === '1'
  const className = isPersistEnabled ? 'highlight-discussion' : 'highlight-fadeout'
  const {focusSelector, setFocusSelector} = useContext(DiscussionManagerUtilityContext) as {
    focusSelector: string
    setFocusSelector: (value: string) => void
  }

  const triggerFocus = (element: HTMLElement | null) => {
    if (!element) {
      return
    }
    const eventType = 'onfocusin' in element ? 'focusin' : 'focus'
    const bubbles = 'onfocusin' in element
    let event

    if ('createEvent' in document) {
      event = document.createEvent('Event')
      event.initEvent(eventType, bubbles, true)
    } else if ('Event' in window) {
      event = new Event(eventType, {bubbles, cancelable: true})
    }

    element.focus()
    if (event) {
      element.dispatchEvent(event)
    }
  }

  useLayoutEffect(() => {
    if (isHighlighted && highlightRef.current) {
      setTimeout(() => {
        if (focusSelector) {
          const speedGraderDiv = highlightRef.current?.querySelector(
            '#speedgrader-navigator',
          ) as HTMLElement | null
          if (speedGraderDiv) {
            triggerFocus(speedGraderDiv)
          }
          const focusElement = highlightRef.current?.querySelector(
            focusSelector,
          ) as HTMLElement | null
          focusElement?.focus({preventScroll: true})
          setFocusSelector('')
        } else {
          const button = highlightRef.current?.querySelector('button') as HTMLButtonElement | null
          button?.focus({preventScroll: true})
        }
        void scrollToHighlight(highlightRef.current)
      }, 0)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isHighlighted, highlightRef])

  return (
    <div
      style={{
        borderRadius: theme.borders.radiusLarge,
        padding: `${isHighlighted ? theme.spacing.xSmall : 0} 0 0 0`,
      }}
      className={classNames({[className]: isHighlighted})}
      data-testid={isHighlighted ? 'isHighlighted' : 'notHighlighted'}
      ref={highlightRef}
      data-entry-id={discussionEntryId}
    >
      {children}
    </div>
  )
}

export default Highlight
