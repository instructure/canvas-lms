/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {DiscussionTopicsPost} from './react/index'
import ready from '@instructure/ready'
import $ from 'jquery'
import React from 'react'
import {legacyRender, render} from '@canvas/react'
import DiscussionTopicKeyboardShortcutModal from './react/KeyboardShortcuts/DiscussionTopicKeyboardShortcutModal'
import {Portal} from '@instructure/ui-portal'
import {mountNutritionFacts} from '@canvas/nutrition-facts'
import {NutritionFacts} from '@canvas/nutrition-facts/react/NutritionFacts'
import {AiInfo} from '@instructure.ai/aiinfo'
import type {FeatureInfo} from '@instructure.ai/aiinfo'
import {captureException} from '@sentry/browser'
import {createPortal} from 'react-dom'
import {Responsive} from '@instructure/ui-responsive'
import {responsiveQuerySizes} from '@canvas/discussions/react/utils'

// @ts-expect-error TS7031 (typescriptify)
function DiscussionPageLayout({navbarHeight}) {
  return (
    <>
      {!window.ENV.disable_keyboard_shortcuts && (
        <Portal open={true} mountNode={document.getElementById('content')}>
          <div id="keyboard-shortcut-modal">
            <DiscussionTopicKeyboardShortcutModal />
          </div>
        </Portal>
      )}
      <Portal open={true} mountNode={document.getElementById('content')}>
        <div id="discussion-redesign-layout" className="discussion-redesign-layout">
          <DiscussionTopicsPost
            // @ts-expect-error TS2322 (typescriptify)
            discussionTopicId={ENV.discussion_topic_id}
            navbarHeight={navbarHeight}
          />
        </div>
      </Portal>
    </>
  )
}

const renderFooter = () => {
  import('@canvas/module-sequence-footer').then(() => {
    $(() => {
      $(`<div id="module_sequence_footer" style="position: fixed; bottom: 0px; z-index: 100" />`)
        .appendTo('#content')
        // @ts-expect-error TS2339 (typescriptify)
        .moduleSequenceFooter({
          assetType: 'Discussion',
          // @ts-expect-error TS2339 (typescriptify)
          assetID: ENV.SEQUENCE.ASSET_ID,
          // @ts-expect-error TS2339 (typescriptify)
          courseID: ENV.SEQUENCE.COURSE_ID,
        })
      adjustFooter()
      // @ts-expect-error TS2345 (typescriptify)
      new ResizeObserver(adjustFooter).observe(document.getElementById('content'))
    })
  })
}

export const adjustFooter = () => {
  const masqueradeBar = document.getElementById('masquerade_bar')
  const container = $('#module_sequence_footer_container')
  const footer = $('#module_sequence_footer')

  if (container.length > 0) {
    const containerRightPosition = container.css('padding-right')
    const containerWidth = $(container).width() + 'px'
    // @ts-expect-error TS2339,TS2769 (typescriptify)
    const masqueradeBarHeight = $(masqueradeBar).height() + 10 + 'px'

    footer.css('width', `calc(${containerWidth} - ${containerRightPosition})`) // width with padding
    footer.css('right', `${containerRightPosition}`)
    footer.css('bottom', masqueradeBarHeight)
  }
}

const mergeFeatureData = (features: string[]) => {
  const validInfos = features
    .map(feature => {
      const info = AiInfo[feature]
      if (!info) {
        captureException(new Error(`No nutrition facts data found for feature: ${feature}`))
      }
      return info
    })
    .filter((info): info is FeatureInfo => Boolean(info))

  if (validInfos.length === 0) return null
  if (validInfos.length === 1) return validInfos[0]

  return {
    aiInformation: {
      data: validInfos.flatMap(info => info.aiInformation.data),
    },
    dataPermissionLevels: validInfos[0].dataPermissionLevels,
    nutritionFacts: {
      featureName: 'IgniteAI Features',
      data: validInfos.flatMap(info =>
        info.nutritionFacts.data.map((block: any, index: number) => ({
          ...block,
          blockTitle: index === 0 ? info.nutritionFacts.featureName : block.blockTitle,
        })),
      ),
    },
  }
}

const mountMergedNutritionFacts = (features: string[]) => {
  const merged = mergeFeatureData(features)
  if (!merged) return

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
            responsiveProps={responsiveProps}
            aiInformation={merged.aiInformation}
            dataPermissionLevels={merged.dataPermissionLevels}
            nutritionFacts={merged.nutritionFacts}
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
  const nutritionFeatures: string[] = []
  // @ts-expect-error TS2339 (typescriptify)
  if (ENV?.discussion_translation_available && ENV?.cedar_translation) {
    nutritionFeatures.push('canvascoursetranslation')
  }
  // @ts-expect-error TS2339 (typescriptify)
  if (ENV?.user_can_summarize) {
    nutritionFeatures.push('canvasdiscussionsummaries')
  }
  if (nutritionFeatures.length === 1) {
    mountNutritionFacts(nutritionFeatures[0])
  } else if (nutritionFeatures.length > 1) {
    mountMergedNutritionFacts(nutritionFeatures)
  }
  document.querySelector('body')?.classList.add('full-width')
  document.querySelector('div.ic-Layout-contentMain')?.classList.remove('ic-Layout-contentMain')
  const navbar = document.querySelector('.ic-app-nav-toggle-and-crumbs.no-print')
  navbar?.setAttribute('style', 'margin: 0 0 0 24px')
  const navbarHeight = navbar?.getBoundingClientRect().height ?? 72

  setTimeout(() => {
    legacyRender(
      <DiscussionPageLayout navbarHeight={navbarHeight} />,
      document.getElementById('content'),
    )
  })

  const urlParams = new URLSearchParams(window.location.search)
  // @ts-expect-error TS2339 (typescriptify)
  if (ENV.SEQUENCE != null && !urlParams.get('embed')) {
    renderFooter()
  }
})
