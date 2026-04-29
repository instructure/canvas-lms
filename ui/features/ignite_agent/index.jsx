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

import React, {useState, useEffect, useRef} from 'react'
import {render} from '@canvas/react'
import {captureException} from '@sentry/browser'
import {canvas, canvasHighContrast} from '@instructure/ui-themes'
import {getTypography} from '@instructure/platform-instui-bindings'
import {Portal} from '@instructure/ui-portal'
import ready from '@instructure/ready'
import {FallbackChatOverlay} from './FallbackChatOverlay'

/**
 * Main IgniteAgent component that auto-loads the agent
 */
function IgniteAgent() {
  const [error, setError] = useState(null)
  const errorOverlayMountRef = useRef(null)

  useEffect(() => {
    // Create an error overlay mount point
    const overlayMount = document.createElement('div')
    overlayMount.id = 'ignite-agent-error-overlay'
    document.body.appendChild(overlayMount)
    errorOverlayMountRef.current = overlayMount

    loadAgent()

    return () => {
      if (errorOverlayMountRef.current) {
        errorOverlayMountRef.current.remove()
      }
    }
  }, [])

  const renderToMountPoint = (module, mountPointId, props) => {
    const mountPoint = document.getElementById(mountPointId)
    if (mountPoint) {
      module.render(mountPoint, props)
      console.log(`[Ignite Agent] Rendered to #${mountPointId}`)
    }
  }

  const loadAgent = async () => {
    try {
      console.log('[Ignite Agent] Loading remote module...')
      const module = await import('igniteagent/appInjector')
      console.log('[Ignite Agent] Remote module loaded successfully')

      if (typeof module.render !== 'function') {
        const renderError = new Error('Remote module does not have a render function')
        captureException(renderError)
        setError(renderError)
        return
      }

      const isHighContrast = Boolean(window.ENV?.use_high_contrast)
      const baseTheme = isHighContrast ? canvasHighContrast : canvas
      // Do not spread brand vars in HC mode — brand colors would override HC colors (a11y regression)
      const brandVars = isHighContrast ? {} : (window.CANVAS_ACTIVE_BRAND_VARIABLES ?? {})
      const props = {
        hostTheme: {
          ...baseTheme,
          ...brandVars,
          typography: {
            ...baseTheme.typography,
            ...getTypography(
              Boolean(ENV.K5_USER),
              Boolean(ENV.USE_CLASSIC_FONT),
              Boolean(ENV.use_dyslexic_font),
            ),
          },
        },
      }
      renderToMountPoint(module, 'oak-mount-point', props)
      renderToMountPoint(module, 'oak-mobile-mount-point', props)
    } catch (loadError) {
      console.error('Failed to load Ignite Agent remote module:', loadError)
      captureException(loadError)
      setError(loadError)
    }
  }

  const handleCloseError = () => {
    setError(null)
    if (errorOverlayMountRef.current) {
      errorOverlayMountRef.current.innerHTML = ''
    }
  }

  return (
    <Portal mountPoint={errorOverlayMountRef.current} open={error !== null}>
      <FallbackChatOverlay error={error} onClose={handleCloseError} />
    </Portal>
  )
}

/**
 * Initialize the Ignite Agent
 */
function initIgniteAgent() {
  // Create a container for the controller component
  const container = document.createElement('div')
  container.id = 'ignite-agent-controller'
  document.body.appendChild(container)

  render(<IgniteAgent />, container)
  console.log('[Ignite Agent] Controller initialized')
}

// Start the initialization process
ready(() => {
  initIgniteAgent()
})
