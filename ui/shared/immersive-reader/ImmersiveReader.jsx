/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import ReactDOM from 'react-dom'
import {Button, IconButton} from '@instructure/ui-buttons'
import {SVGIcon} from '@instructure/ui-svg-images'
import {useScope as useI18nScope} from '@canvas/i18n'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {defaultFetchOptions} from '@canvas/util/xhr'
import {CookiePolicy} from '@microsoft/immersive-reader-sdk'
import WithBreakpoints from '@canvas/with-breakpoints'
import ContentChunker from './ContentChunker'
import ContentUtils from './ContentUtils'
import { captureException } from '@sentry/react'

const I18n = useI18nScope('ImmersiveReader')

/**
 * This comes from https://github.com/microsoft/immersive-reader-sdk/blob/master/assets/icon.svg
 */
const LOGO = `
<!-- Copyright (c) Microsoft Corporation. All rights reserved.
     Licensed under the MIT License. -->

<svg viewBox="0 0 40 37" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
    <g stroke="none" stroke-width="1" fill="none" fill-rule="evenodd">
        <g fill-rule="nonzero">
            <path d="M37.4,0.9 L37.4,9.6 L35.4,9.6 L35.4,2.9 L24.4,2.9 C22.9,3.3 20,4.5 20,6 L20,17.2 L18,17.2 L18,6 C18,5 15.6,3.6 13.8,2.9 L2,2.9 L2,29 L12.4,29 L12.4,31 L0,31 L0,0.9 L14.1,0.9 L14.3,1 C15,1.2 17.5,2.2 18.9,3.7 C20.5,1.9 23.5,1.1 23.9,1 L24.1,1 L37.4,1 L37.4,0.9 Z" fill="#000000"></path>
            <path d="M27.4,37 L25.8,37 L18.4,29.4 L14,29.4 L14,21 L18.4,20.9 L26.1,13 L27.4,13 L27.4,37 Z M16,27.4 L19.2,27.4 L25.3,33.7 L25.3,16.6 L19.2,22.9 L15.9,22.9 L15.9,27.4 L16,27.4 Z" fill="#0197F2"></path>
            <path d="M31.3,32.7 L29.6,31.7 C29.6,31.7 31.7,28.3 31.7,25.2 C31.7,21.9 29.6,18.5 29.6,18.4 L31.3,17.4 C31.4,17.6 33.7,21.3 33.7,25.2 C33.7,28.8 31.4,32.6 31.3,32.7 Z" fill="#0197F2"></path>
            <path d="M36.4,36.2 L34.8,35 C34.8,35 38,30.8 38,25.2 C38,19.6 34.8,15.4 34.8,15.4 L36.4,14.2 C36.5,14.4 40,19 40,25.3 C40,31.5 36.5,36 36.4,36.2 Z" fill="#0197F2"></path>
        </g>
    </g>
</svg>
`

function handleClick({title, content}, readerSDK) {
  ;(readerSDK || import('@microsoft/immersive-reader-sdk'))
    .then(({launchAsync}) => {
      fetch('/api/v1/immersive_reader/authenticate', defaultFetchOptions())
        .then(response => response.json())
        .then(({token, subdomain}) => {
          let htmlPayload = content()

          // For any images that are hyperlinked (i.e. their immedediate parent is an anchor tag)
          // we want to remove each hyperlinked image's parent anchor tag before sending the html payload
          // to Immersive Reader (IR)
          // Otherwise IR will not read the hyperlinked image's alt text; it will instead read the anchor's href value
          const contentUtils = new ContentUtils(htmlPayload)
          if (contentUtils.htmlContainsHyperlinkedImage()) {
            htmlPayload = contentUtils.removeAnchorFromHyperlinkedImages()
          }

          const chunks = new ContentChunker().chunk(htmlPayload)
          const requestContent = {
            title,
            chunks,
          }
          const options = {
            cookiePolicy: CookiePolicy.Disable,
          }
          launchAsync(token, subdomain, requestContent, options)
        })
        .catch(e => {
          // eslint-disable-next-line no-console
          console.error('Getting authentication details failed', e)
          captureException(e)
          showFlashError(I18n.t('Immersive Reader Failed to Load'))()
        })
    })
    .catch(e => {
      // eslint-disable-next-line no-console
      console.error('Loading the Immersive Reader SDK failed', e)
      captureException(e)
      showFlashError(I18n.t('Immersive Reader Failed to Load'))()
    })
}

export function ImmersiveReaderButton({content, readerSDK, breakpoints}) {
  return breakpoints?.mobileOnly ? (
    <IconButton
      onClick={() => handleClick(content, readerSDK)}
      screenReaderLabel={I18n.t('Immersive Reader')}
    >
      <SVGIcon src={LOGO} />
    </IconButton>
  ) : (
    <Button onClick={() => handleClick(content, readerSDK)} renderIcon={<SVGIcon src={LOGO} />}>
      {I18n.t('Immersive Reader')}
    </Button>
  )
}

const ImmersiveReaderButtonWithBreakpoints = WithBreakpoints(ImmersiveReaderButton)

export function initializeReaderButton(mountPoint, content) {
  ReactDOM.render(<ImmersiveReaderButtonWithBreakpoints content={content} />, mountPoint)
}
