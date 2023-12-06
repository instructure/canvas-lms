/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import React, {useState, useEffect, useRef} from 'react'
import ConfettiGenerator from '../javascript/ConfettiGenerator'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {useScope as useI18nScope} from '@canvas/i18n'
import {getBrandingColors, getProps} from '../javascript/confetti.utils'

const I18n = useI18nScope('confetti')

export default function Confetti({triggerCount}: {triggerCount?: number | null}) {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const [visible, setVisible] = useState(true)
  useEffect(() => {
    if (!visible) {
      setVisible(true)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [triggerCount])

  useEffect(() => {
    if (window.ENV.disable_celebrations || !visible || !canvasRef.current) {
      return
    }

    let forcefulCleanup: number | void
    let clearConfettiOnSpaceOrEscape: (event: KeyboardEvent) => void

    const cleanup = () => {
      confetti.clear()

      document.body.removeEventListener('keydown', clearConfettiOnSpaceOrEscape)

      if (forcefulCleanup) {
        forcefulCleanup = clearTimeout(forcefulCleanup)
      }
      setVisible(false)
    }

    const confetti = new ConfettiGenerator(getProps(), getBrandingColors(), canvasRef.current)

    clearConfettiOnSpaceOrEscape = (event: KeyboardEvent) => {
      if (event.keyCode === 32 || event.keyCode === 27) {
        event.preventDefault()
        cleanup()
      }
    }

    document.body.addEventListener('keydown', clearConfettiOnSpaceOrEscape)
    confetti.render()
    showFlashAlert({
      message: I18n.t('Great work! From the Canvas developers'),
      srOnly: true,
    })

    // Automatically clear animation after 3 seconds, avoiding 5 second window
    // defined by WCAG Success Criterion 2.2.2: Pause, Stop, Hide.
    forcefulCleanup = setTimeout(cleanup, 3000) as unknown as number

    return cleanup
  }, [visible])

  return window.ENV.disable_celebrations || !visible ? null : (
    <canvas
      ref={canvasRef}
      data-testid="confetti-canvas"
      style={{position: 'fixed', top: 0, left: 0}}
    />
  )
}
