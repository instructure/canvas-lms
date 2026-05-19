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
import {getAccessToken, refreshToken, getUser, getRcsToken, refreshRcsToken} from './auth'
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
  gradingContext?: {
    assignmentId?: string
    studentId?: string
    studentUuid?: string
    submissionId?: string
    [key: string]: any
  }
  onSubmissionUpdate?: () => void
}

export function AmsLoader({
  containerId,
  gradingContext,
  onSubmissionUpdate,
}: AmsLoaderProps): JSX.Element | null {
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

    const customerAppVariant = ENV.FEATURES.ams_advanced_content_organization
      ? ['content-team']
      : []

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
              getRcsToken,
              refreshRcsToken,
            },
            rubrics: {
              createController: createRubricController,
            },
            customerAppVariant,
            rcsConfig: {
              RICH_CONTENT_APP_HOST: ENV.RICH_CONTENT_APP_HOST,
              RICH_CONTENT_CAN_UPLOAD_FILES: ENV.RICH_CONTENT_CAN_UPLOAD_FILES,
              RICH_CONTENT_INST_RECORD_TAB_DISABLED: ENV.RICH_CONTENT_INST_RECORD_TAB_DISABLED,
              RICH_CONTENT_FILES_TAB_DISABLED: ENV.RICH_CONTENT_FILES_TAB_DISABLED,
              RICH_CONTENT_CAN_EDIT_FILES: ENV.RICH_CONTENT_CAN_EDIT_FILES,
              K5_SUBJECT_COURSE: ENV.K5_SUBJECT_COURSE,
              K5_HOMEROOM_COURSE: ENV.K5_HOMEROOM_COURSE,
              context_asset_string: ENV.context_asset_string,
              DEEP_LINKING_POST_MESSAGE_ORIGIN: ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN,
              current_user_id: ENV.current_user_id,
              disable_keyboard_shortcuts: ENV.disable_keyboard_shortcuts,
              rce_auto_save_max_age_ms: ENV.rce_auto_save_max_age_ms,
              editorButtons: window.INST?.editorButtons ?? [],
              kalturaSettings: {
                hide_rte_button: window.INST?.kalturaSettings?.hide_rte_button || false,
              },
              LOCALES: ENV.LOCALES,
              LOCALE: ENV.LOCALE,
              active_brand_config_json_url: ENV.active_brand_config_json_url,
              url_for_high_contrast_tinymce_editor_css:
                ENV.url_for_high_contrast_tinymce_editor_css ?? [],
              url_to_what_gets_loaded_inside_the_tinymce_editor_css:
                ENV.url_to_what_gets_loaded_inside_the_tinymce_editor_css ?? [],
              FEATURES: ENV.FEATURES,
              LTI_LAUNCH_FRAME_ALLOWANCES: ENV.LTI_LAUNCH_FRAME_ALLOWANCES,
            },
            ...(gradingContext && {gradingContext}),
            ...(onSubmissionUpdate && {onSubmissionUpdate}),
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
  }, [containerId, gradingContext, onSubmissionUpdate])

  return null
}

async function loadAmsModule() {
  const moduleUrl = REMOTES?.ams?.launch_url

  if (!moduleUrl) {
    throw new Error('AMS module URL not found')
  }

  return import(/* webpackIgnore: true */ moduleUrl)
}
