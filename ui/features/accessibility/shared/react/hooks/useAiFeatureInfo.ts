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

import {useShallow} from 'zustand/react/shallow'
import {AiInfo, FeatureInfo} from '@instructure.ai/aiinfo'
import {useAccessibilityScansStore} from '../stores/AccessibilityScansStore'

const ALT_TEXT_RULE_IDS = ['img-alt', 'img-alt-length', 'img-alt-filename']

const tableCaption = AiInfo.canvasa11ycheckertablecaptions
const altText = AiInfo.canvasa11ycheckeralttextgenerator

export function useAiFeatureInfo(): FeatureInfo | null {
  const [isAiAltTextGenerationEnabled, isAiTableCaptionGenerationEnabled, selectedIssue] =
    useAccessibilityScansStore(
      useShallow(state => [
        state.isAiAltTextGenerationEnabled,
        state.isAiTableCaptionGenerationEnabled,
        state.selectedIssue,
      ]),
    )

  const ruleId = selectedIssue?.ruleId
  if (isAiAltTextGenerationEnabled && ruleId && ALT_TEXT_RULE_IDS.includes(ruleId)) {
    return altText
  }
  if (isAiTableCaptionGenerationEnabled && ruleId === 'table-caption') {
    return tableCaption
  }
  return null
}
