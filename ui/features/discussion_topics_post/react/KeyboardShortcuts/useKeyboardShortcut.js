/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {useEffect} from 'react'

export const KeyboardShortcuts = {
  TOGGLE_RATING_KEYBOARD: 'toggleRatingKeyboard',
  ON_SHOW_REPLIES_KEYBOARD: 'onShowRepliesKeyboard',
  ON_THREAD_REPLY_KEYBOARD: 'onThreadReplyKeyboard',
  ON_DELETE_KEYBOARD: 'onDeleteKeyboard',
  ON_EDIT_KEYBOARD: 'onEditKeyboard',
  ON_OPEN_TOPIC_REPLY: 'onOpenTopicReply',
  ON_NEXT_REPLY: 'onNextReply',
  ON_PREV_REPLY: 'onPrevReply',
  ON_SPEEDGRADER_COMMENT: 'onSpeedGraderComment',
  ON_SPEEDGRADER_GRADE: 'onSpeedGraderGrade',
}

export function useEventHandler(eventName, callback) {
  useEffect(() => {
    if (ENV.disable_keyboard_shortcuts) return
    document.addEventListener(eventName, callback)
    return () => {
      document.removeEventListener(eventName, callback)
    }
  }, [callback, eventName])
}

export function useKeyboardShortcuts() {
  useEffect(() => {
    if (ENV.disable_keyboard_shortcuts) return

    const dispatchCustomEvent = (eventType, entryId) => {
      document.dispatchEvent(
        new CustomEvent(eventType, {
          detail: {
            entryId,
          },
        }),
      )
    }

    const handleKeydown = e => {
      if (e.repeat) return
      const nodeName = e.target.nodeName.toLowerCase()
      if (nodeName === 'input' || nodeName === 'textarea') return
      if (e.ctrlKey || e.shiftKey || e.metaKey || e.altKey) return

      const entryId = e.target.closest('div[data-entry-id]')?.getAttribute('data-entry-id')

      const keyEventMap = {
        n: () => document.dispatchEvent(new Event(KeyboardShortcuts.ON_OPEN_TOPIC_REPLY)),
        l: () => dispatchCustomEvent(KeyboardShortcuts.TOGGLE_RATING_KEYBOARD, entryId),
        r: () => dispatchCustomEvent(KeyboardShortcuts.ON_THREAD_REPLY_KEYBOARD, entryId),
        e: () => dispatchCustomEvent(KeyboardShortcuts.ON_EDIT_KEYBOARD, entryId),
        d: () => dispatchCustomEvent(KeyboardShortcuts.ON_DELETE_KEYBOARD, entryId),
        x: () => dispatchCustomEvent(KeyboardShortcuts.ON_SHOW_REPLIES_KEYBOARD, entryId),
        k: () => dispatchCustomEvent(KeyboardShortcuts.ON_PREV_REPLY, entryId),
        j: () => dispatchCustomEvent(KeyboardShortcuts.ON_NEXT_REPLY, entryId),
        c: () => dispatchCustomEvent(KeyboardShortcuts.ON_SPEEDGRADER_COMMENT, entryId),
        g: () => dispatchCustomEvent(KeyboardShortcuts.ON_SPEEDGRADER_GRADE, entryId),
      }

      if (keyEventMap[e.key]) {
        keyEventMap[e.key]()
        return
      }
    }

    document.addEventListener('keydown', handleKeydown)
    return () => {
      document.removeEventListener('keydown', handleKeydown)
    }
  }, [])
}
