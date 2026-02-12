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

import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconAddLine} from '@instructure/ui-icons'
import formatMessage from '../format-message'
import type {CaptionCreationMode} from './types'

export interface CaptionCreationModePickerProps {
  onSelect: (mode: CaptionCreationMode) => void
}

/**
 * Component for choosing between manual upload or auto-captioning
 */
export function CaptionCreationModePicker({onSelect}: CaptionCreationModePickerProps) {
  return (
    <Flex gap="small">
      <Button
        color="secondary"
        onClick={() => onSelect('manual')}
        renderIcon={<IconAddLine />}
        textAlign="center"
      >
        {formatMessage('Add New')}
      </Button>

      <Button color="primary" onClick={() => onSelect('auto')} textAlign="center">
        {formatMessage('Request')}
      </Button>
    </Flex>
  )
}
