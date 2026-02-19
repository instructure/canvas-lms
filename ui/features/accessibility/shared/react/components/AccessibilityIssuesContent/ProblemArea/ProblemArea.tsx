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

import {View} from '@instructure/ui-view'
import Preview, {PreviewHandle} from '../Preview'
import {useScope as createI18nScope} from '@canvas/i18n'
import {
  AccessibilityIssue,
  AccessibilityResourceScan,
  ColorContrastPreviewResponse,
  FormType,
  PreviewResponse,
} from '../../../types'
import {ColorPickerProblemArea} from './ColorPickerProblemArea'
import {useState} from 'react'
import {Flex} from '@instructure/ui-flex'

const I18n = createI18nScope('accessibility_checker')

export const ProblemArea = (props: {
  previewRef?: React.RefObject<PreviewHandle>
  item: AccessibilityResourceScan
  issue: AccessibilityIssue
}) => {
  const [previewResponse, setPreviewResponse] = useState<PreviewResponse | null>(null)
  return (
    <Flex as="section" direction="column" gap="mediumSmall" aria-label={I18n.t('Problem area')}>
      <Preview
        ref={props.previewRef}
        issue={props.issue}
        resourceId={props.item.resourceId}
        itemType={props.item.resourceType}
        onPreviewChange={setPreviewResponse}
      />
      {props.issue.form.type === FormType.ColorPicker && (
        <View>
          <ColorPickerProblemArea
            previewResponse={previewResponse as ColorContrastPreviewResponse}
            issue={props.issue}
          />
        </View>
      )}
    </Flex>
  )
}
