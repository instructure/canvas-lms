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

import type {MediaTrack} from '@canvas/canvas-studio-player/react/types'
import {isAsrGenerating} from '../utils/isAsrGenerating'

const track = (overrides: Partial<MediaTrack>): MediaTrack => ({
  asr: false,
  created_at: '',
  id: '1',
  inherited: false,
  kind: 'subtitles',
  locale: 'en',
  updated_at: '',
  url: '',
  workflow_state: 'ready',
  ...overrides,
})

describe('isAsrGenerating', () => {
  it('returns true for a single processing ASR track', () => {
    expect(isAsrGenerating([track({asr: true, workflow_state: 'processing'})])).toBe(true)
  })

  it('returns false for empty tracks', () => {
    expect(isAsrGenerating([])).toBe(false)
  })

  it('returns false for a single ready ASR track', () => {
    expect(isAsrGenerating([track({asr: true, workflow_state: 'ready'})])).toBe(false)
  })

  it('returns false when there are multiple tracks even if one is processing ASR', () => {
    expect(
      isAsrGenerating([track({asr: true, workflow_state: 'processing'}), track({asr: false})]),
    ).toBe(false)
  })

  it('returns false when tracks is undefined', () => {
    expect(isAsrGenerating(undefined)).toBe(false)
  })

  it('returns false for a single non-ASR processing track', () => {
    expect(isAsrGenerating([track({asr: false, workflow_state: 'processing'})])).toBe(false)
  })
})
