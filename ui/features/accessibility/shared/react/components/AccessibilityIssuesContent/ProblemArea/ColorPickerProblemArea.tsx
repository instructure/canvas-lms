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

import {AccessibilityIssue, ColorContrastPreviewResponse} from '../../../types'
import {A11yColorContrast} from '../../A11yColorContrast'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('accessibility_checker')

export const ColorPickerProblemArea = (props: {
  previewResponse: ColorContrastPreviewResponse | null
  issue: AccessibilityIssue
}) => {
  const firstColor = props.previewResponse?.background ?? '#FFFFFF'
  const secondColor = props.previewResponse?.foreground ?? '#000000'
  return (
    <A11yColorContrast
      firstColor={firstColor}
      secondColor={secondColor}
      label={props.issue?.form?.titleLabel || I18n.t('Contrast Ratio')}
      validationLevel={'AA'}
      options={props.issue.form.options}
    />
  )
}
