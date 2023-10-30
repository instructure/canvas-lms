/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'

import {IconSearchLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('student_groups')

export default function Filter(props) {
  return (
    <View as="div" className="form-inline clearfix content-box" width="30%" minWidth="230px">
      <TextInput
        id="search_field"
        renderLabel={<ScreenReaderContent>{I18n.t('Search Groups')}</ScreenReaderContent>}
        placeholder={I18n.t('Search Groups or People')}
        type="search"
        onChange={props.onChange}
        renderBeforeInput={<IconSearchLine />}
        aria-label={I18n.t(
          'As you type in this field, the list of groups will be automatically filtered to only include those whose names match your input.'
        )}
        data-testid="group-search-input"
      />
    </View>
  )
}
