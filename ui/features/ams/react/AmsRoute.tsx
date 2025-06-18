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

interface AmsModule {
  render: (container: HTMLElement, config: {routerBasename: string}) => void
  unmount: (container: HTMLElement) => void
}

export function Component(): JSX.Element | null {
  const containerRef = useRef<HTMLDivElement | null>(document.querySelector('#ams_container'))
  const moduleRef = useRef<AmsModule | null>(null)

  React.useEffect(() => {
    if (!ENV.FEATURES.ams_service || !containerRef.current) {
      return
    }

    let stillMounting = true

    loadAmsModule()
      .then(module => {
        if (stillMounting && containerRef.current) {
          moduleRef.current = module
          module.render(containerRef.current, {
            routerBasename: ENV.context_url ?? '',
            themeOverrides: window.CANVAS_ACTIVE_BRAND_VARIABLES ?? null,
            useHighContrast: ENV.use_high_contrast ?? false,
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
  }, [])

  return null
}

async function loadAmsModule() {
  const moduleUrl = REMOTES?.ams?.launch_url

  if (!moduleUrl) {
    throw new Error('AMS module URL not found')
  }

  return import(/* webpackIgnore: true */ moduleUrl)
}
