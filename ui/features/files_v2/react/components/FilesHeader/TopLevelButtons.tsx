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
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import {IconUploadLine} from '@instructure/ui-icons'
import CreateFolderButton from './CreateFolderButton'

const I18n = createI18nScope('files_v2')
interface TopLevelButtonsProps {
  isUserContext: boolean
  size: string
  isDisabled: boolean
  onCreateFolderButtonClick: () => void
}

const TopLevelButtons = ({
  isUserContext,
  size,
  isDisabled,
  onCreateFolderButtonClick,
}: TopLevelButtonsProps) => {
  const buttonDisplay = size === 'small' ? 'block' : 'inline-block'

  const uploadButton = () => {
    return (
      <Button
        color="primary"
        margin="none none small none"
        renderIcon={<IconUploadLine />}
        display={buttonDisplay}
        disabled={isDisabled}
      >
        {I18n.t('Upload')}
      </Button>
    )
  }

  const allMyFilesButton = () => {
    if (isUserContext) return null
    return (
      <a href="/files" tabIndex={-1}>
        <Button
          color="secondary"
          margin="none x-small small none"
          display={buttonDisplay}
          disabled={isDisabled}
        >
          {I18n.t('All My Files')}
        </Button>
      </a>
    )
  }

  if (size === 'small') {
    return (
      <>
        {uploadButton()}
        <CreateFolderButton
          buttonDisplay={buttonDisplay}
          isDisabled={isDisabled}
          onClick={onCreateFolderButtonClick}
        />
        {allMyFilesButton()}
      </>
    )
  }

  return (
    <>
      {allMyFilesButton()}
      <CreateFolderButton
        buttonDisplay={buttonDisplay}
        isDisabled={isDisabled}
        onClick={onCreateFolderButtonClick}
      />
      {uploadButton()}
    </>
  )
}

export default TopLevelButtons
