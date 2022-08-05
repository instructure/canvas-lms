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
import ConfettiGenerator from '../javascript/ConfettiGenerator'
import getRandomConfettiFlavor from './confettiFlavor'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {useScope as useI18nScope} from '@canvas/i18n'
import hex2Rgb from '@canvas/util/hex2rgb'

const I18n = useI18nScope('confetti')

const getBrandingColors = () => {
  if (window.ENV.confetti_branding_enabled && window.ENV.active_brand_config) {
    const colorVars = window.ENV.active_brand_config.variables
    const primaryBrand = colorVars['ic-brand-primary']
    const secondaryBrand = colorVars['ic-brand-global-nav-bgd']
    const colors = []
    if (primaryBrand) colors.push(Object.values(hex2Rgb(primaryBrand)))
    if (secondaryBrand) colors.push(Object.values(hex2Rgb(secondaryBrand)))
    if (colors.length > 0) {
      return {
        colors
      }
    }
  }
  return {}
}

export default function Confetti({triggerCount}) {
  const [visible, setVisible] = React.useState(true)
  React.useEffect(() => {
    if (!visible) {
      setVisible(true)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [triggerCount])

  React.useEffect(() => {
    if (window.ENV.disable_celebrations || !visible) {
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
      setVisible(false)
    }

    confetti = new ConfettiGenerator({
      props: ['square', getRandomConfettiFlavor()].filter(p => p !== null),
      ...getBrandingColors()
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
  }, [visible])

  return window.ENV.disable_celebrations || !visible ? null : (
    <canvas
      id="confetti-canvas"
      data-testid="confetti-canvas"
      style={{position: 'fixed', top: 0, left: 0}}
    />
  )
}
