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

import {renderHook} from '@testing-library/react-hooks'
import {useAiFeatureInfo} from '../useAiFeatureInfo'
import {useAccessibilityScansStore} from '../../stores/AccessibilityScansStore'

vi.mock('../../stores/AccessibilityScansStore')
vi.mock('@instructure.ai/aiinfo', () => ({
  AiInfo: {
    canvasa11ycheckertablecaptions: {id: 'tableCaption'},
    canvasa11ycheckeralttextgenerator: {id: 'altText'},
  },
}))

const mockUseAccessibilityScansStore = vi.mocked(useAccessibilityScansStore)

function setupStore({
  isAiAltTextGenerationEnabled = false,
  isAiTableCaptionGenerationEnabled = false,
  ruleId = undefined as string | undefined,
} = {}) {
  mockUseAccessibilityScansStore.mockImplementation((selector: any) =>
    selector({
      isAiAltTextGenerationEnabled,
      isAiTableCaptionGenerationEnabled,
      selectedIssue: ruleId ? {ruleId} : null,
    }),
  )
}

describe('useAiFeatureInfo', () => {
  it('returns null when no flags are enabled', () => {
    setupStore({ruleId: 'img-alt'})
    const {result} = renderHook(() => useAiFeatureInfo())
    expect(result.current).toBeNull()
  })

  it('returns null when selectedIssue is null', () => {
    setupStore({isAiAltTextGenerationEnabled: true, isAiTableCaptionGenerationEnabled: true})
    const {result} = renderHook(() => useAiFeatureInfo())
    expect(result.current).toBeNull()
  })

  it('returns alt text feature info for img-alt rule with alt text flag enabled', () => {
    setupStore({isAiAltTextGenerationEnabled: true, ruleId: 'img-alt'})
    const {result} = renderHook(() => useAiFeatureInfo())
    expect(result.current).toEqual({id: 'altText'})
  })

  it('returns alt text feature info for img-alt-length rule with alt text flag enabled', () => {
    setupStore({isAiAltTextGenerationEnabled: true, ruleId: 'img-alt-length'})
    const {result} = renderHook(() => useAiFeatureInfo())
    expect(result.current).toEqual({id: 'altText'})
  })

  it('returns alt text feature info for img-alt-filename rule with alt text flag enabled', () => {
    setupStore({isAiAltTextGenerationEnabled: true, ruleId: 'img-alt-filename'})
    const {result} = renderHook(() => useAiFeatureInfo())
    expect(result.current).toEqual({id: 'altText'})
  })

  it('returns table caption feature info for table-caption rule with caption flag enabled', () => {
    setupStore({isAiTableCaptionGenerationEnabled: true, ruleId: 'table-caption'})
    const {result} = renderHook(() => useAiFeatureInfo())
    expect(result.current).toEqual({id: 'tableCaption'})
  })

  it('returns null for other rule even with both flags enabled', () => {
    setupStore({
      isAiAltTextGenerationEnabled: true,
      isAiTableCaptionGenerationEnabled: true,
      ruleId: 'color-contrast',
    })
    const {result} = renderHook(() => useAiFeatureInfo())
    expect(result.current).toBeNull()
  })
})
