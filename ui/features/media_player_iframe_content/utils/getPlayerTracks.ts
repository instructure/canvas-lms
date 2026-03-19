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

import {useScope as createI18nScope} from '@canvas/i18n'
import type {MediaTrack} from '@canvas/canvas-studio-player/react/types'

const I18n = createI18nScope('CanvasMediaPlayer')

export type EnrichedMediaTrack = MediaTrack & {
  src: string
  label: string
  type: string
  language: string
}

/**
 * Filters out tracks that are still processing or have failed,
 * and appends "(Automatic)" to the label of ASR tracks.
 */
export const getPlayerTracks = (
  mediaTracks: EnrichedMediaTrack[] | undefined,
): EnrichedMediaTrack[] | undefined => {
  return mediaTracks
    ?.filter(t => t.workflow_state !== 'processing' && t.workflow_state !== 'failed')
    .map(t => (t.asr ? {...t, label: I18n.t('%{language} (Automatic)', {language: t.label})} : t))
}
