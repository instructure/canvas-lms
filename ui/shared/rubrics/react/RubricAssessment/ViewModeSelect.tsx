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

import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('rubrics-assessment-tray')

export type ViewMode = 'horizontal' | 'vertical' | 'traditional'

type ViewModeSelectProps = {
  isFreeFormCriterionComments: boolean
  selectedViewMode: ViewMode
  onViewModeChange: (viewMode: ViewMode) => void
}
export const ViewModeSelect = ({
  isFreeFormCriterionComments,
  selectedViewMode,
  onViewModeChange,
}: ViewModeSelectProps) => {
  const handleSelect = (viewMode: string) => {
    onViewModeChange(viewMode as ViewMode)
  }

  return (
    <SimpleSelect
      renderLabel={
        <ScreenReaderContent>{I18n.t('Rubric Assessment View Mode')}</ScreenReaderContent>
      }
      width="10rem"
      height="2.375rem"
      value={selectedViewMode}
      data-testid="rubric-assessment-view-mode-select"
      onChange={(_e, {value}) => handleSelect(value as string)}
    >
      <SimpleSelect.Option
        id="traditional"
        value="traditional"
        data-testid="traditional-view-option"
      >
        {I18n.t('Traditional')}
      </SimpleSelect.Option>
      <SimpleSelect.Option id="horizontal" value="horizontal" data-testid="horizontal-view-option">
        {I18n.t('Horizontal')}
      </SimpleSelect.Option>
      {!isFreeFormCriterionComments && (
        <SimpleSelect.Option id="vertical" value="vertical" data-testid="vertical-view-option">
          {I18n.t('Vertical')}
        </SimpleSelect.Option>
      )}
    </SimpleSelect>
  )
}
