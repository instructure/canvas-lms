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
import {useBlockContentEditorContext} from '../BlockContentEditorContext'

export const useFocusElement = (focus: boolean | undefined, isRCE: boolean = false) => {
  const {settingsTray} = useBlockContentEditorContext()
  const elementRef = useRef<HTMLElement | null>(null)

  const focusHandler = () => {
    if (settingsTray.isOpen) {
      return
    }
    if (focus && elementRef.current) {
      elementRef.current.focus()
    }
  }

  useEffect(() => focusHandler(), [focus, elementRef, settingsTray.isOpen])

  const elementRefHandler = (element: Element | null) => {
    if (element && 'current' in elementRef) {
      elementRef.current = element as HTMLElement
    }
  }

  const rceHandler = () => {
    focusHandler()
  }

  return {
    elementRef,
    refHandler: isRCE ? rceHandler : elementRefHandler,
  }
}
