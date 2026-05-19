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

import type {EnrichedMediaTrack} from '../utils/getPlayerTracks'
import {getPlayerTracks} from '../utils/getPlayerTracks'

const track = (overrides: Partial<EnrichedMediaTrack> = {}): EnrichedMediaTrack => ({
  asr: false,
  created_at: '',
  id: '1',
  inherited: false,
  kind: 'subtitles',
  locale: 'en',
  updated_at: '',
  url: 'http://example.com/track',
  workflow_state: 'ready',
  src: 'http://example.com/track',
  label: 'English',
  type: 'subtitles',
  language: 'en',
  ...overrides,
})

describe('getPlayerTracks', () => {
  it('returns undefined when mediaTracks is undefined', () => {
    expect(getPlayerTracks(undefined)).toBeUndefined()
  })

  it('returns an empty array when mediaTracks is empty', () => {
    expect(getPlayerTracks([])).toEqual([])
  })

  it('ready workflow state tracks are kept', () => {
    const tracks = [track({id: '1'}), track({id: '2'})]
    const result = getPlayerTracks(tracks)
    expect(result).toHaveLength(2)
    expect(result![0].label).toBe('English')
    expect(result![1].label).toBe('English')
  })

  it('filters out tracks with processing or failed workflow_state', () => {
    const tracks = [
      track({id: '1', workflow_state: 'processing'}),
      track({id: '2', workflow_state: 'failed'}),
      track({id: '3', workflow_state: 'ready'}),
    ]
    const result = getPlayerTracks(tracks)
    expect(result).toHaveLength(1)
    expect(result![0].id).toBe('3')
  })

  it('keeps tracks without a workflow_state', () => {
    const tracks = [track({id: '1', workflow_state: undefined as any})]
    const result = getPlayerTracks(tracks)
    expect(result).toHaveLength(1)
    expect(result![0].id).toBe('1')
  })

  it('appends "(Automatic)" to ASR track labels', () => {
    const tracks = [track({asr: true, label: 'English', workflow_state: 'ready'})]
    const result = getPlayerTracks(tracks)
    expect(result![0].label).toBe('English (Automatic)')
  })

  it('does not modify non-ASR track labels', () => {
    const tracks = [track({asr: false, label: 'English'})]
    const result = getPlayerTracks(tracks)
    expect(result![0].label).toBe('English')
  })

  it('keeps ready ASR tracks and filters processing/failed ones', () => {
    const tracks = [
      track({id: '1', asr: true, workflow_state: 'ready', label: 'English'}),
      track({id: '2', asr: true, workflow_state: 'processing', label: 'Spanish'}),
      track({id: '3', asr: true, workflow_state: 'failed', label: 'French'}),
      track({id: '4', asr: false, label: 'German'}),
    ]
    const result = getPlayerTracks(tracks)
    expect(result).toHaveLength(2)
    expect(result![0].id).toBe('1')
    expect(result![0].label).toBe('English (Automatic)')
    expect(result![1].id).toBe('4')
    expect(result![1].label).toBe('German')
  })
})
