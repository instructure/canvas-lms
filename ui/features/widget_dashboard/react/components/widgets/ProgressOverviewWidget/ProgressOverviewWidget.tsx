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

import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import TemplateWidget from '../TemplateWidget/TemplateWidget'
import type {BaseWidgetProps} from '../../../types'

const I18n = createI18nScope('widget_dashboard')

const ProgressOverviewWidget: React.FC<BaseWidgetProps> = ({widget, isEditMode = false}) => {
  return (
    <TemplateWidget widget={widget} isEditMode={isEditMode} showHeader={true}>
      <Text size="medium" data-testid="progress-overview-placeholder">
        {I18n.t('Progress overview widget coming soon...')}
      </Text>
    </TemplateWidget>
  )
}

export default ProgressOverviewWidget
