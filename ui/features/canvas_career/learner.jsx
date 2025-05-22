/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

import ReactDOM from 'react-dom'

import GenericErrorPage from '@canvas/generic-error-page'
import {useScope as createI18nScope} from '@canvas/i18n'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import ready from '@instructure/ready'
import {Spinner} from '@instructure/ui-spinner'
import {captureException} from '@sentry/browser'

const I18n = createI18nScope('canvascareer')

ready(() => {
  const body = document.querySelector('body')
  const mountPoint = document.createElement('div')

  mountPoint.id = 'canvascareer'
  mountPoint.style.height = '100vh'
  mountPoint.style.width = '100vw'
  mountPoint.style.position = 'relative'

  // Modifying the DOM to add the mount point
  body.prepend(mountPoint)
  body.style.lineHeight = 'normal'
  body.style.margin = '0'
  body.style.padding = '0'

  ReactDOM.render(
    <div
      style={{
        position: 'fixed',
        left: 0,
        top: 0,
        right: 0,
        bottom: 0,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
      }}
    >
      <Spinner renderTitle={I18n.t('Loading')} margin="large auto 0 auto" />
    </div>,
    mountPoint,
  )

  Promise.all([
    import('canvascareerlearner/bootstrap'),
    import('canvascareerlearner/setupEnvContext'),
  ])
    .then(([{mount}, {setupEnvContext}]) => {
      mount(mountPoint, setupEnvContext())
    })
    .catch(error => {
      console.error('Failed to load CanvasCareer learner app', error)
      captureException(error)

      ReactDOM.render(
        <GenericErrorPage
          imageUrl={errorShipUrl}
          errorMessage={error.message}
          errorSubject={'CanvasCareer learner app loading error'}
          errorCategory={'CanvasCareer Error Page'}
        />,
        mountPoint,
      )
    })
})
