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

import React, {useEffect, useRef, useState} from 'react'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as createI18nScope} from '@canvas/i18n'
import GenericErrorPage from '@canvas/generic-error-page'
import errorShipUrl from '@instructure/platform-images/assets/ErrorShip.svg'

const I18n = createI18nScope('course_settings')

const CanvasCourseCriteria: React.FC = () => {
  const mountRef = useRef<HTMLDivElement>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<Error | null>(null)

  useEffect(() => {
    const loadCanvasCourseCriteria = async () => {
      try {
        // @ts-expect-error - untyped remote module
        const module = await import('canvascoursecriteria/CanvasCourseCriteria')

        if (typeof module.render === 'function') {
          module.render(mountRef.current)
          setLoading(false)
        } else {
          const renderError = new Error('Canvas Criteria module does not have a render function')
          console.error(renderError)
          setError(renderError)
          setLoading(false)
        }
      } catch (loadError) {
        console.error('Failed to load Canvas Criteria remote module:', loadError)
        setError(loadError as Error)
        setLoading(false)
      }
    }

    loadCanvasCourseCriteria()
  }, [])

  if (error) {
    return (
      <GenericErrorPage
        imageUrl={errorShipUrl}
        errorMessage={I18n.t(
          'We were unable to load Canvas Criteria. Please try refreshing the page.',
        )}
        errorSubject={I18n.t('Canvas Criteria loading error')}
        errorCategory={I18n.t('Canvas Criteria Error Page')}
      />
    )
  }

  return (
    <>
      {loading && (
        <div style={{display: 'flex', justifyContent: 'center', padding: '2rem'}}>
          <Spinner size="large" renderTitle={I18n.t('Loading Canvas Criteria')} />
        </div>
      )}
      <div ref={mountRef} style={{display: loading ? 'none' : 'block'}} />
    </>
  )
}

export default CanvasCourseCriteria
