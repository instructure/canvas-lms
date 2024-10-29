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
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconAddLine, IconUploadLine} from '@instructure/ui-icons'

interface TopLevelButtonsProps {
  isUserContext: boolean
  size: string
}

const TopLevelButtons = ({isUserContext, size}: TopLevelButtonsProps) => {
  const buttonDisplay = size === 'small' ? 'block' : 'inline-block'

  const uploadButton = () => {
    return (
      <Flex.Item padding="none">
        <Button
          color="primary"
          margin="none none small none"
          renderIcon={<IconUploadLine />}
          display={buttonDisplay}
        >
          Upload
        </Button>
      </Flex.Item>
    )
  }

  const addFolderButton = () => {
    return (
      <Flex.Item padding="small none small none">
        <Button
          color="secondary"
          margin="none x-small small none"
          renderIcon={<IconAddLine />}
          display={buttonDisplay}
        >
          Folder
        </Button>
      </Flex.Item>
    )
  }

  const allMyFilesButton = () => {
    if (isUserContext) return null
    return (
      <Flex.Item padding="small none small none">
        <a href="/files">
          <Button color="secondary" margin="none x-small small none" display={buttonDisplay}>
            All My Files
          </Button>
        </a>
      </Flex.Item>
    )
  }

  if (size === 'small') {
    return (
      <>
        {uploadButton()}
        {addFolderButton()}
        {allMyFilesButton()}
      </>
    )
  }

  return (
    <>
      {allMyFilesButton()}
      {addFolderButton()}
      {uploadButton()}
    </>
  )
}

export default TopLevelButtons
