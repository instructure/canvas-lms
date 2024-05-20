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

import {Checkbox} from '@instructure/ui-checkbox'
import {FormField} from '@instructure/ui-form-field'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv.d'

declare const ENV: GlobalEnv & {
  SIS_NAME: string
}

const I18n = useI18nScope('discussion_create')

type Props = {
  postToSis: boolean
  setPostToSis: (postToSis: boolean) => void
}

export const SyncToSisCheckbox = ({postToSis, setPostToSis}: Props) => {
  return (
    <FormField
      id="post_to_sis"
      label={I18n.t('Sync to %{sis_friendly_name}', {sis_friendly_name: ENV.SIS_NAME})}
    >
      <Checkbox
        label={I18n.t(
          "Include this assignment's grades when syncing to your school's Student Information System"
        )}
        value="post_to_sis"
        checked={postToSis}
        onChange={() => setPostToSis(!postToSis)}
      />
    </FormField>
  )
}
