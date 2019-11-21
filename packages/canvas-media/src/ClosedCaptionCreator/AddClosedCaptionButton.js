/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {Button} from '@instructure/ui-buttons'
import {IconPlusSolid} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y'

export default function AddClosedCaptionButton({
  CLOSED_CAPTIONS_ADD_SUBTITLE_SCREENREADER,
  disabled,
  newButtonClick
}) {
  return (
    <div style={{display: 'flex', justifyContent: 'center', alignItems: 'center'}}>
      <hr aria-hidden style={{flex: '1'}} />
      <Button
        onClick={newButtonClick}
        disabled={disabled}
        variant="circle-default"
        icon={IconPlusSolid}
      >
        <ScreenReaderContent>{CLOSED_CAPTIONS_ADD_SUBTITLE_SCREENREADER}</ScreenReaderContent>
      </Button>
      <hr aria-hidden style={{flex: '1'}} />
    </div>
  )
}
