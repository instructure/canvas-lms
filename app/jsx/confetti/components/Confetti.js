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

import React from 'react'
import ConfettiGenerator from 'confetti-js'
import getRandomConfettiFlavor from '../utils/confettiFlavor'
import {showFlashAlert} from 'jsx/shared/FlashAlert'
import I18n from 'i18n!confetti'

export default function Confetti() {
  React.useEffect(() => {
    if (window.ENV.disable_celebrations) {
      return
    }

    let forcefulCleanup
    let clearConfettiOnSpaceOrEscape
    let confetti

    const cleanup = () => {
      confetti.clear()

      document.body.removeEventListener('keydown', clearConfettiOnSpaceOrEscape)

      if (forcefulCleanup) {
        forcefulCleanup = clearTimeout(forcefulCleanup)
      }
    }

    confetti = new ConfettiGenerator({
      target: 'confetti-canvas',
      max: 160,
      clock: 50,
      respawn: false,
      props: ['square', getRandomConfettiFlavor()]
    })

    clearConfettiOnSpaceOrEscape = event => {
      if (event.keyCode === 32 || event.keyCode === 27) {
        event.preventDefault()
        cleanup()
      }
    }

    document.body.addEventListener('keydown', clearConfettiOnSpaceOrEscape)
    confetti.render()
    setTimeout(() => {
      showFlashAlert({
        message: I18n.t('Great work! From the Canvas developers'),
        srOnly: true
      })
    }, 2500)

    // Automatically clear animation after 3 seconds, avoiding 5 second window
    // defined by WCAG Success Criterion 2.2.2: Pause, Stop, Hide.
    forcefulCleanup = setTimeout(cleanup, 3000)

    return cleanup
  }, [])

  return <canvas id="confetti-canvas" style={{position: 'fixed', top: 0, left: 0}} />
}
