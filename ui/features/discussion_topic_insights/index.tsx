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
import {createPortal} from 'react-dom'
import {render} from '@canvas/react'
import ready from '@instructure/ready'
import {captureException} from '@sentry/browser'
import {AiInfo} from '@instructure.ai/aiinfo'
import {NutritionFacts} from '@instructure/platform-nutrition-facts'
import {Responsive} from '@instructure/ui-responsive'
import {responsiveQuerySizes} from '@canvas/discussions/react/utils'
import {useScope as createI18nScope} from '@canvas/i18n'
import DiscussionInsightsApp from './react/index'

const I18n = createI18nScope('nutrition_facts')

const nutritionFactsTranslations = () => ({
  title: '',
  triggerScreenReaderLabel: I18n.t('Nutrition facts'),
  dataPermissionLevelsTitle: I18n.t('Data Permission Levels'),
  dataPermissionLevelsCurrentFeatureText: I18n.t('Current Feature:'),
  dataPermissionLevelsCloseIconButtonScreenReaderLabel: I18n.t('Close'),
  dataPermissionLevelsCloseButtonText: I18n.t('Close'),
  dataPermissionLevelsModalLabel: I18n.t('This is a Data Permission Levels modal'),
  nutritionFactsModalLabel: I18n.t('This is a modal for AI facts'),
  nutritionFactsTitle: I18n.t('Nutrition Facts'),
  nutritionFactsCloseButtonText: I18n.t('Close'),
  nutritionFactsCloseIconButtonScreenReaderLabel: I18n.t('Close'),
})

const mountNutritionFacts = (feature: string) => {
  const info = AiInfo[feature]
  if (!info) {
    captureException(new Error(`No nutrition facts data found for feature: ${feature}`))
    return
  }

  const element = (
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
          captureException(
            new Error(`Could not find element with id ${responsiveProps.domElement}`),
          )
          return null
        }
        return createPortal(
          <NutritionFacts
            aiInformation={info.aiInformation.data}
            dataPermissionLevels={info.dataPermissionLevels.data}
            nutritionFacts={info.nutritionFacts}
            translations={nutritionFactsTranslations()}
            fullscreenModals={responsiveProps.fullscreenModals}
            color={responsiveProps.color}
            buttonColor={responsiveProps.buttonColor}
            withBackground={responsiveProps.withBackground}
          />,
          node,
        )
      }}
    />
  )

  const wrapperDiv = document.createElement('div')
  document.body.appendChild(wrapperDiv)
  render(element, wrapperDiv)
}

ready(() => {
  mountNutritionFacts('discussioninsights')
  document.querySelector('body')?.classList.add('full-width')
  const contentElement = document.getElementById('discussion-insights-container')
  if (contentElement) {
    render(<DiscussionInsightsApp />, contentElement)
  }
})
