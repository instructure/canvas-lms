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
import {Text} from '@instructure/ui-text'
import {IconQuestionLine} from '@instructure/ui-icons'
import {Tooltip} from '@instructure/ui-tooltip'

const I18n = useI18nScope('mepfeaturetracksinstructure_tooltip')

export default function InheritedCaptionTooltip() {
  return (
    <Tooltip
      renderTip={
        <Text size="x-small">
          {I18n.t('Captions inherited from a parent course cannot be removed.')}
          <br />
          {I18n.t('You can replace by uploading a new caption file.')}
        </Text>
      }
    >
      <IconQuestionLine />
    </Tooltip>
  )
}
