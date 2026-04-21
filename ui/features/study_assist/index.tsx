/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import React, {useCallback, useEffect, useState} from 'react'
import {render} from '@canvas/react'
import ready from '@instructure/ready'
import {PlatformUiProvider} from '@instructure/platform-provider'
import {platformExecuteQuery} from '@canvas/graphql'
import type {AssistRequest, AssistResponse} from '@instructure/platform-study-assist'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {useTranslation} from '@canvas/i18next'
import {IconButton} from '@instructure/ui-buttons'
import {IconAiSolid} from '@instructure/ui-icons'
import {registerPageContentWrapper} from '@canvas/page-content-wrapper'
import StudyAssistTray from './components/StudyAssistTray'

async function fetchAssistResponse(request: AssistRequest): Promise<AssistResponse> {
  const courseId = window.ENV.COURSE_ID ?? request.state?.courseID
  if (!courseId) throw new Error('COURSE_ID is not configured')
  const {json} = await doFetchApi<AssistResponse>({
    path: `/api/v1/courses/${courseId}/study_assist`,
    method: 'POST',
    body: request,
  })
  return json ?? {}
}

const ICON_MOUNT_IDS = ['study_assist_mount_point', 'study_assist_mobile_mount_point']
const DRAWER_MOUNT_ID = 'study_assist_drawer_layout_mount_point'
const OPEN_EVENT = 'study-assist:open'

function dispatchOpen() {
  window.dispatchEvent(new CustomEvent(OPEN_EVENT))
}

function StudyAssistTrigger() {
  const {t} = useTranslation('study_assist')
  return (
    <IconButton
      screenReaderLabel={t('Study tools')}
      shape="circle"
      color="ai-primary"
      onClick={dispatchOpen}
    >
      <IconAiSolid />
    </IconButton>
  )
}

// Wraps a page-content host (a div the caller supplies) in our DrawerLayout.
// Used both as the wrapper registered with @canvas/page-content-wrapper (when
// top_navigation_placement is on) and as the root component for the standalone
// path (when it is off).
export function StudyAssistDrawer({pageContent}: {pageContent: HTMLElement}) {
  const [open, setOpen] = useState(false)

  useEffect(() => {
    const handler = () => setOpen(true)
    window.addEventListener(OPEN_EVENT, handler)
    return () => window.removeEventListener(OPEN_EVENT, handler)
  }, [])

  // Callback ref so a remount of the host div re-attaches pageContent.
  const handleHostRef = useCallback(
    (el: HTMLDivElement | null) => {
      if (el && pageContent && !el.contains(pageContent)) {
        el.appendChild(pageContent)
      }
    },
    [pageContent],
  )

  return (
    <PlatformUiProvider
      executeQuery={platformExecuteQuery}
      locale={window.ENV.LOCALE ?? 'en'}
      timezone={window.ENV.TIMEZONE ?? 'UTC'}
      currentUserId={window.ENV.current_user_id ?? undefined}
    >
      <StudyAssistTray
        open={open}
        onDismiss={() => setOpen(false)}
        fetchAssistResponse={fetchAssistResponse}
      >
        <div ref={handleHostRef} />
      </StudyAssistTray>
    </PlatformUiProvider>
  )
}

function wrapTrigger(node: React.ReactNode) {
  return (
    <PlatformUiProvider
      executeQuery={platformExecuteQuery}
      locale={window.ENV.LOCALE ?? 'en'}
      timezone={window.ENV.TIMEZONE ?? 'UTC'}
      currentUserId={window.ENV.current_user_id ?? undefined}
    >
      {node}
    </PlatformUiProvider>
  )
}

// Register at module load so the wrapper is in place before
// ContentTypeExternalToolDrawer renders. When top_navigation_placement is
// enabled, top_nav uses this wrapper to nest our drawer inside its DrawerContent
// instead of fighting over #application.
registerPageContentWrapper(StudyAssistDrawer)

ready(() => {
  if (!window.ENV.FEATURES.study_assist) return

  ICON_MOUNT_IDS.forEach(id => {
    const mount = document.getElementById(id)
    if (mount) render(wrapTrigger(<StudyAssistTrigger />), mount)
  })

  // Standalone path: when top_navigation_placement is off, top_nav doesn't
  // render a DrawerLayout, so our wrapper is never invoked. Mount the drawer
  // ourselves at the layout-provided slot.
  if (!window.ENV.INIT_DRAWER_LAYOUT_MUTEX) {
    const applicationEl = document.getElementById('application')
    const mount = document.getElementById(DRAWER_MOUNT_ID)
    if (applicationEl && mount) {
      render(<StudyAssistDrawer pageContent={applicationEl} />, mount)
    }
  }
})
