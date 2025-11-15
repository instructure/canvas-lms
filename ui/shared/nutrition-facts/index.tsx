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
import ReactDOM from 'react-dom/client'
import {createPortal} from 'react-dom'
import ready from '@instructure/ready'
import {captureException} from '@sentry/browser'
import {AiInfo} from '@instructure.ai/aiinfo'
import {NutritionFacts} from './react/NutritionFacts'
import {Responsive} from '@instructure/ui-responsive'
import {responsiveQuerySizes} from '@canvas/discussions/react/utils'

const ResponsiveNutritionFacts = (feature: string) => {
  const info = AiInfo[feature]
  if (!info) {
    captureException(new Error(`No nutrition facts data found for feature: ${feature}`))
    return null
  }

  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({mobile: true, desktop: true}) as any}
      props={{
        mobile: {
          domElement: 'nutrition_facts_mobile_container',
          fullscreenModals: true,
          color: 'secondary',
          buttonColor: 'primary',
          withBackground: false,
        },
        desktop: {
          domElement: 'nutrition_facts_container',
          fullscreenModals: false,
          color: 'primary',
          buttonColor: 'primary-inverse',
          withBackground: false,
        },
      }}
      render={(responsiveProps: any) => {
        const node = document.getElementById(responsiveProps.domElement)
        if (!node) {
          captureException(new Error(`Could not find element with id ${responsiveProps.domElement}`))
          return null
        }
        return createPortal(
          <NutritionFacts 
            responsiveProps={responsiveProps} 
            aiInformation={info.aiInformation}
            dataPermissionLevels={info.dataPermissionLevels}
            nutritionFacts={info.nutritionFacts}
          />
          , node
        )
      }}
    />
  )
}

export const mountNutritionFacts = (feature: string) => {
  ready(() => {
    try {
      const wrapperDiv = document.createElement('div')
      document.body.appendChild(wrapperDiv)
      const root = ReactDOM.createRoot(wrapperDiv)
      root.render(ResponsiveNutritionFacts(feature))
    } catch (error) {
      captureException(error)
    }
  })
}
