/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {TextInput} from '@instructure/ui-text-input'
import React from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {IconSearchLine, IconTroubleLine} from '@instructure/ui-icons'
import {IconButton} from '@instructure/ui-buttons'

const I18n = useI18nScope('lti_registrations')

type AppsSearchBarProps = {
  value: string
  handleChange: (event: React.ChangeEvent<HTMLInputElement>, value: string) => void
  handleClear: () => void
}

const renderClearButton = (value: string, handleClear: () => void) =>
  value.length === 0 ? null : (
    <IconButton
      type="button"
      size="small"
      withBackground={false}
      withBorder={false}
      screenReaderLabel="Clear search"
      onClick={handleClear}
    >
      <IconTroubleLine />
    </IconButton>
  )

export const AppsSearchBar = (props: AppsSearchBarProps) => {
  const label = I18n.t('Search names & nicknames')
  return (
    <form name="appsSearch" autoComplete="off">
      <TextInput
        renderLabel={<ScreenReaderContent>{label}</ScreenReaderContent>}
        placeholder={label}
        value={props.value}
        onChange={props.handleChange}
        // inputRef={el => (this.inputRef = el)}
        renderBeforeInput={<IconSearchLine inline={false} />}
        renderAfterInput={renderClearButton(props.value, props.handleClear)}
        shouldNotWrap={true}
      />
    </form>
  )
}
