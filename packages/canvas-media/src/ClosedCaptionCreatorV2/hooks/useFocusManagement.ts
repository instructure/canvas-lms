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

import {useEffect, useRef} from 'react'

type FocusAction =
  | {type: 'addNew'}
  | {type: 'afterDelete'; targetLocale: string}
  | {type: 'creationForm'}

/**
 * Manages focus for the closed caption panel after add/cancel/upload/delete actions.
 *
 * Uses a pending-focus pattern: callers queue a focus action via `queueFocus`,
 * and the action is executed after React commits the render via a no-deps `useEffect`.
 */
export function useFocusManagement() {
  const addNewButtonRef = useRef<HTMLElement | null>(null)
  const creationFormRef = useRef<HTMLElement | null>(null)
  const deleteButtonRefs = useRef<Map<string, HTMLElement>>(new Map())
  const pendingFocusRef = useRef<FocusAction | null>(null)

  // Execute queued focus actions after React commits the render
  useEffect(() => {
    const action = pendingFocusRef.current
    if (!action) return
    pendingFocusRef.current = null

    const focusAddNewOrCreationForm = () => {
      if (addNewButtonRef.current) {
        addNewButtonRef.current.focus()
      } else {
        creationFormRef.current?.focus()
      }
    }

    if (action.type === 'addNew') {
      focusAddNewOrCreationForm()
    } else if (action.type === 'creationForm') {
      creationFormRef.current?.focus()
    } else if (action.type === 'afterDelete') {
      const targetEl = deleteButtonRefs.current.get(action.targetLocale)
      if (targetEl) {
        targetEl.focus()
      } else {
        focusAddNewOrCreationForm()
      }
    }
  })

  // Props accept Element to match InstUI's elementRef signature,
  // but we store as HTMLElement since we call .focus() on them.
  const setAddNewButtonRef = (el: Element | null) => {
    addNewButtonRef.current = el as HTMLElement | null
  }

  const setCreationFormRef = (el: Element | null) => {
    creationFormRef.current = el as HTMLElement | null
  }

  const setDeleteButtonRef = (locale: string) => (el: Element | null) => {
    if (el) {
      deleteButtonRefs.current.set(locale, el as HTMLElement)
    } else {
      deleteButtonRefs.current.delete(locale)
    }
  }

  const queueFocus = (action: FocusAction) => {
    pendingFocusRef.current = action
  }

  return {
    setAddNewButtonRef,
    setCreationFormRef,
    setDeleteButtonRef,
    queueFocus,
  }
}
