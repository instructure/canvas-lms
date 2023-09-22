/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {useScope as useI18nScope} from '@canvas/i18n'
import userSettings from '@canvas/user-settings'
import {HandleCheckboxChange} from '../../../types'
import {View} from '@instructure/ui-view'
import {ApplyTheme} from '@instructure/ui-themeable'
// @ts-expect-error TODO: fix in instui 8
import {Checkbox, CheckboxFacade} from '@instructure/ui-checkbox'

const I18n = useI18nScope('enhanced_individual_gradebook')

type Props = {
  handleCheckboxChange: HandleCheckboxChange
  hideStudentNames: boolean
}
export default function HideStudentNamesCheckbox({handleCheckboxChange, hideStudentNames}: Props) {
  const handleHideStudentNamesChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const checked = event.target.checked
    userSettings.contextSet('hide_student_names', checked)
    handleCheckboxChange('hideStudentNames', checked)
  }

  return (
    <ApplyTheme
      theme={{
        [CheckboxFacade.theme]: {
          checkedBackground: '#0375ff',
          borderColor: '#777777',
          labelFontSizeSmall: '1rem',
        },
        [View.theme]: {
          paddingMedium: '16px',
        },
      }}
    >
      <View
        as="div"
        className="checkbox"
        margin="x-small 0"
        borderRadius="medium"
        background="primary"
        padding="medium"
        theme={{backgroundPrimary: '#eee'}}
      >
        <Checkbox
          data-testid="hide-student-names-checkbox"
          size="small"
          label={I18n.t('Hide Student Names')}
          checked={hideStudentNames}
          onChange={handleHideStudentNamesChange}
        />
      </View>
    </ApplyTheme>
  )
}
