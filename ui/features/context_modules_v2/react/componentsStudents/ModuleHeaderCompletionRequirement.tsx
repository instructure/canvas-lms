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
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Pill} from '@instructure/ui-pill'

const I18n = createI18nScope('context_modules_v2')

type Props = {
  requirementCount?: number
}

export const ModuleHeaderCompletionRequirement = ({requirementCount}: Props) => {
  return (
    <Pill color="primary">
      <Text size="x-small">
        {requirementCount ? I18n.t('Complete One Item') : I18n.t('Complete All Items')}
      </Text>
    </Pill>
  )
}
