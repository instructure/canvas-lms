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
import ready from '@instructure/ready'
import {captureException} from '@sentry/browser'
import {AiInfo} from '@instructure.ai/aiinfo'
import {NutritionFacts} from './react/NutritionFacts'

const renderNutritionFacts = (elementId: string, feature: string) => {
  const node = document.getElementById(elementId)
  if (!node) {
    captureException(new Error(`Could not find element with id ${elementId}`))
    return null
  }

  const info = AiInfo[feature]
  if (!info) {
    captureException(new Error(`No nutrition facts data found for feature: ${feature}`))
    return null
  }

  const root = ReactDOM.createRoot(node)
  root.render(
    <NutritionFacts
      aiInformation={info.aiInformation}
      dataPermissionLevels={info.dataPermissionLevels}
      nutritionFacts={info.nutritionFacts}
    />,
  )
  return root
}

export const mountNutritionFacts = (feature: string) => {
  ready(() => {
    try {
      renderNutritionFacts('nutrition_facts_container', feature)
    } catch (error) {
      captureException(error)
    }
  })
}
