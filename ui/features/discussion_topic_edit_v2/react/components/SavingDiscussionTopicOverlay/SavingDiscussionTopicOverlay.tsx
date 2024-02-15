// @ts-nocheck
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

import React from 'react'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Mask, Overlay} from '@instructure/ui-overlays'

const I18n = useI18nScope('discussion_create')

type Props = {
  open: boolean
}

export const SavingDiscussionTopicOverlay = ({open}: Props) => {
  const label = I18n.t('Loading')
  const message = I18n.t('Saving Discussion Topic')

  return (
    <Overlay open={open} transition="fade" label={message}>
      <Mask themeOverride={{zIndex: 10001}} fullscreen={true}>
        <Spinner renderTitle={label} size="large" margin="0 0 0 medium" />
      </Mask>
    </Overlay>
  )
}
