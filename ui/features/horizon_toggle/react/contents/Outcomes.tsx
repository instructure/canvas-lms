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

export const Outcomes = () => {
  const data = useContext(HorizonToggleContext)
  if (!data?.errors?.outcomes) {
    return null
  }
  return (
    <ContentItems
      label={I18n.t(
        {one: 'Outcomes (%{count} item)', other: 'Outcomes (%{count} items)'},
        {count: data.errors.outcomes.length},
      )}
      screenReaderLabel={I18n.t('Outcomes')}
      contents={data.errors.outcomes}
    />
  )
}
