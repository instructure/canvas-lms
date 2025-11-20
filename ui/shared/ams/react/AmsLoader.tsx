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

import React, {useRef} from 'react'
import {getAccessToken, refreshToken, getUser} from './auth'
import {createRubricController} from '@canvas/rubrics/react/RubricAssignment'
import type {RubricController} from '@canvas/rubrics/react/RubricAssignment'

interface AmsModule {
  render: (
    container: HTMLElement,
    config: {
      routerBasename: string
      rubrics?: {
        createController: (container: HTMLElement) => RubricController
      }
    },
  ) => void
  unmount: (container: HTMLElement) => void
}

interface AmsLoaderProps {
  containerId: string
}

export function AmsLoader({containerId}: AmsLoaderProps): JSX.Element | null {
  const containerRef = useRef<HTMLDivElement | null>(null)
  const moduleRef = useRef<AmsModule | null>(null)

  React.useEffect(() => {
    containerRef.current = document.querySelector(`#${containerId}`)

    if (!ENV.FEATURES.ams_root_account_integration || !containerRef.current) {
      return
    }

    let stillMounting = true

    // Set window variables for AMS to consume
    if (REMOTES?.ams?.api_url) {
      window.AMS_CONFIG = {
        API_URL: REMOTES?.ams?.api_url,
      }
    }

    loadAmsModule()
      .then(module => {
        if (stillMounting && containerRef.current) {
          moduleRef.current = module
          module.render(containerRef.current, {
            routerBasename: ENV.context_url ?? '',
            themeOverrides: window.CANVAS_ACTIVE_BRAND_VARIABLES ?? null,
            useHighContrast: ENV.use_high_contrast ?? false,
            auth: {
              getAccessToken,
              refreshToken,
              getUser,
            },
            rubrics: {
              createController: createRubricController,
            },
          })
        }
      })
      .catch(err => {
        console.error('Failed to load AMS: ', err)
      })

    return () => {
      stillMounting = false
      if (containerRef.current && moduleRef.current) {
        moduleRef.current.unmount(containerRef.current)
      }
    }
  }, [containerId])

  return null
}

async function loadAmsModule() {
  const moduleUrl = REMOTES?.ams?.launch_url

  if (!moduleUrl) {
    throw new Error('AMS module URL not found')
  }

  return import(/* webpackIgnore: true */ moduleUrl)
}
