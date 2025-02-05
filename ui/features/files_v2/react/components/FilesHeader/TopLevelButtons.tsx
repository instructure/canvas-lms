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
import UploadButton from './UploadButton'

const I18n = createI18nScope('files_v2')
interface TopLevelButtonsProps {
  isUserContext: boolean
  size: string
  onCreateFolderButtonClick: () => void
  shouldHideUploadButtons?: boolean
}

const TopLevelButtons = ({
  isUserContext,
  size,
  onCreateFolderButtonClick,
  shouldHideUploadButtons = false,
}: TopLevelButtonsProps) => {
  const buttonDisplay = size === 'small' ? 'block' : 'inline-block'

  const createFolderButton = () => {
    if (shouldHideUploadButtons) return null

    return <CreateFolderButton buttonDisplay={buttonDisplay} onClick={onCreateFolderButtonClick} />
  }

  const uploadButton = () => {
    if (shouldHideUploadButtons) return null

    return (
      <UploadButton
        color="primary"
        margin="none none small none"
        renderIcon={<IconUploadLine />}
        display={buttonDisplay}
      >
        {I18n.t('Upload')}
      </UploadButton>
    )
  }

  const allMyFilesButton = () => {
    if (isUserContext) return null
    return (
      <a href="/files" tabIndex={-1}>
        <Button color="secondary" margin="none x-small small none" display={buttonDisplay}>
          {I18n.t('All My Files')}
        </Button>
      </a>
    )
  }

  if (size === 'small') {
    return (
      <>
        {uploadButton()}
        {createFolderButton()}
        {allMyFilesButton()}
      </>
    )
  }

  return (
    <>
      {allMyFilesButton()}
      {createFolderButton()}
      {uploadButton()}
    </>
  )
}

export default TopLevelButtons
