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

import React, {useState} from 'react'
import {render} from '@canvas/react'
import ready from '@instructure/ready'
import {PlatformUiProvider} from '@instructure/platform-provider'
import {platformExecuteQuery} from '@canvas/graphql'
import type {AssistRequest, AssistResponse} from '@instructure/platform-study-assist'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {useScope as createI18nScope} from '@canvas/i18n'
import {IconButton} from '@instructure/ui-buttons'
import {IconAiSolid} from '@instructure/ui-icons'
import StudyAssistTray from './components/StudyAssistTray'

const I18n = createI18nScope('study_assist')

let jwtPromise: Promise<string> | null = null

function getJwt(): Promise<string> {
  if (!jwtPromise) {
    jwtPromise = doFetchApi<{token: string}>({
      path: '/api/v1/jwts?canvas_audience=false&workflows[]=journey',
      method: 'POST',
    }).then(({json}) => atob(json!.token))
  }
  return jwtPromise
}

const CHIP_LABEL_MAP: Array<[RegExp, string]> = [
  [/^Summarize/i, 'Summarize'],
  [/^Quiz me/i, 'Quiz me'],
  [/^Flash Cards$/i, 'Flashcards'],
]

function normalizeChipLabel(chip: string): string {
  for (const [pattern, label] of CHIP_LABEL_MAP) {
    if (pattern.test(chip)) return label
  }
  return chip
}

async function fetchAssistResponse(request: AssistRequest): Promise<AssistResponse> {
  const token = await getJwt()
  const journeyUrl = window.ENV.JOURNEY_URL
  if (!journeyUrl) throw new Error('JOURNEY_URL is not configured')
  const response = await fetch(`${journeyUrl}/api/v1/assist`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify(request),
  })
  if (!response.ok) throw new Error(`Assist request failed: ${response.status}`)
  const data = (await response.json()) as AssistResponse
  if (data.chips) {
    data.chips = data.chips.map(c => {
      const label = normalizeChipLabel(c.chip)
      return {...c, chip: label, prompt: label}
    })
  }
  return data
}

function StudyAssistApp() {
  const [open, setOpen] = useState(false)

  return (
    <>
      <IconButton
        screenReaderLabel={I18n.t('Study tools')}
        shape="circle"
        color="ai-primary"
        onClick={() => setOpen(true)}
      >
        <IconAiSolid />
      </IconButton>
      <StudyAssistTray
        open={open}
        onDismiss={() => setOpen(false)}
        fetchAssistResponse={fetchAssistResponse}
      />
    </>
  )
}

const MOUNT_IDS = ['study_assist_mount_point', 'study_assist_mobile_mount_point']

ready(() => {
  if (!window.ENV.FEATURES.study_assist) return

  MOUNT_IDS.forEach(id => {
    const mount = document.getElementById(id)
    if (!mount) return

    render(
      <PlatformUiProvider
        executeQuery={platformExecuteQuery}
        locale={window.ENV.LOCALE ?? 'en'}
        timezone={window.ENV.TIMEZONE ?? 'UTC'}
        currentUserId={window.ENV.current_user_id ?? undefined}
      >
        <StudyAssistApp />
      </PlatformUiProvider>,
      mount,
    )
  })
})
