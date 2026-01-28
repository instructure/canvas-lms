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
import {Text} from '@instructure/ui-text'
import formatMessage from 'format-message'

interface AutoCaptioningProps {
  handleCancel: () => void
}

/** NOTE: Right now this comp is to showcase where AutoCaptioning will be handled. TBD LATER */
export const AutoCaptioning = ({handleCancel}: AutoCaptioningProps) => {
  return (
    <>
      <Text>TBD</Text>
      <Button color="secondary" onClick={handleCancel} textAlign="center" width="auto">
        {formatMessage('Cancel')}
      </Button>
    </>
  )
}
