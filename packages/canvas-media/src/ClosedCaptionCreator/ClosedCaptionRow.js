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
import {Flex} from '@instructure/ui-layout'
import {IconDownloadLine, IconTrashLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y'
import {Text} from '@instructure/ui-elements'

export default function ClosedCaptionRow({closedCaption, trashButtonOnClick}) {
  const onRowDelete = () => {
    trashButtonOnClick(closedCaption)
  }
  return (
    <Flex justifyItems="space-between">
      <Flex.Item textAlign="start" size="200px">
        <Text>{closedCaption.language.inputValue}</Text>
      </Flex.Item>
      <Flex.Item textAlign="start">
        <Text>{closedCaption.file.name}</Text>
      </Flex.Item>
      <Flex.Item textAlign="end" shrink grow>
        {!closedCaption.isNew && (
          <Button variant="icon" icon={IconDownloadLine}>
            <ScreenReaderContent>Download {closedCaption.file.name}</ScreenReaderContent>
          </Button>
        )}
        <Button variant="icon" icon={IconTrashLine} onClick={onRowDelete}>
          <ScreenReaderContent>Delete {closedCaption.file.name}</ScreenReaderContent>
        </Button>
      </Flex.Item>
    </Flex>
  )
}
