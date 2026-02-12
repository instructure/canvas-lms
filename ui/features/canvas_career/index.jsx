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

import React from 'react'
import {render, rerender} from '@canvas/react'

import {captureException} from '@sentry/browser'
import {Spinner} from '@instructure/ui-spinner'
import ready from '@instructure/ready'
import {useScope as createI18nScope} from '@canvas/i18n'
import GenericErrorPage from '@canvas/generic-error-page'
import errorShipUrl from '@canvas/images/ErrorShip.svg'

const I18n = createI18nScope('canvascareer')

ready(() => {
  const body = document.querySelector('body')
  const mountPoint = document.createElement('div')
  const fixedBottom = document.querySelector('#fixed_bottom')
  const fixedBottomOffset = fixedBottom?.offsetHeight || 0

  mountPoint.id = 'canvascareer'
  mountPoint.style.height =
    fixedBottomOffset > 0 ? `calc(100vh - ${fixedBottomOffset + 5}px)` : '100vh'
  mountPoint.style.width = '100%'
  mountPoint.style.position = 'relative'

  // Modifying the DOM to add the mount point
  body.prepend(mountPoint)
  body.style.lineHeight = 'normal'
  body.style.margin = '0'
  body.style.padding = '0'
  body.style.overflow = 'hidden'

  const root = render(
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

  let bundles = []
  if (window.REMOTES.canvas_career_learner) {
    bundles = [
      import('canvas_career_learner/bootstrap'),
      import('canvas_career_learner/setupEnvContext'),
    ]
  } else if (window.REMOTES.canvas_career_learning_provider) {
    bundles = [
      import('canvas_career_learning_provider/bootstrap'),
      import('canvas_career_learning_provider/setupEnvContext'),
    ]
  }

  Promise.all(bundles)
    .then(([{mount}, {setupEnvContext}]) => {
      mount(mountPoint, setupEnvContext(), window.REMOTES.canvas_career_config)
    })
    .catch(error => {
      console.error('Failed to load Canvas Career', error)
      captureException(error)

      rerender(
        root,
        <GenericErrorPage
          imageUrl={errorShipUrl}
          errorMessage={error.message}
          errorSubject={I18n.t('Canvas Career loading error')}
          errorCategory={I18n.t('Canvas Career Error Page')}
        />,
      )
    })
})
