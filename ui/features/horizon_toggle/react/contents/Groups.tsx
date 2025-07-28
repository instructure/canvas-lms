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

import {useContext} from 'react'
import {HorizonToggleContext} from '../HorizonToggleContext'
import {ContentItems} from './ContentItems'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('horizon_toggle_page')

export const Groups = () => {
  const data = useContext(HorizonToggleContext)
  if (!data?.errors?.groups) {
    return null
  }
  return (
    <ContentItems
      label={I18n.t(
        {one: 'Groups (%{count} item)', other: 'Groups (%{count} items)'},
        {count: data.errors.groups.length},
      )}
      screenReaderLabel={I18n.t('Groups')}
      contents={data.errors.groups}
    />
  )
}
