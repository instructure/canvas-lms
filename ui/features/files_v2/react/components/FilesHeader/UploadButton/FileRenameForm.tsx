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

import {useCallback, useEffect, useRef, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'
import {type ResolvedName, type FileOptions} from './FileOptions'

type FileRenameFormProps = {
  open: boolean
  onClose: () => void
  fileOptions: FileOptions
  onNameConflictResolved: (resolvedName: ResolvedName) => void
}

const I18n = createI18nScope('files_v2')

const FileRenameForm = ({
  open,
  onClose,
  fileOptions,
  onNameConflictResolved,
}: FileRenameFormProps) => {
  const closeButtonRef = useRef<HTMLButtonElement | null>(null)
  const [isEditing, setIsEditing] = useState<boolean>(false)
  const [renameFileInput, setRenameFileInput] = useState<string>('')

  const handleRenameClick = useCallback(() => {
    setIsEditing(true)
    closeButtonRef.current?.focus()
  }, [closeButtonRef])
  const handleBackClick = useCallback(() => setIsEditing(false), [])

  const handleSkipClick = useCallback(
    () =>
      onNameConflictResolved({
        file: fileOptions.file,
        dup: 'skip',
        name: fileOptions.name,
        expandZip: fileOptions.expandZip,
      }),
    [fileOptions, onNameConflictResolved],
  )

  // pass back expandZip to preserve options that was possibly already made
  // in a previous modal
  const handleReplaceClick = useCallback(
    () =>
      onNameConflictResolved({
        file: fileOptions.file,
        dup: 'overwrite',
        name: fileOptions.name,
        expandZip: fileOptions.expandZip,
      }),
    [fileOptions, onNameConflictResolved],
  )

  // pass back expandZip to preserve options that was possibly already made
  // in a previous modal
  const handleChangeClick = useCallback(
    () =>
      onNameConflictResolved({
        file: fileOptions.file,
        dup: 'error', // throw an error if the new name also already exists
        name: renameFileInput,
        expandZip: fileOptions.expandZip,
      }),
    [fileOptions, onNameConflictResolved, renameFileInput],
  )

  const renderHeader = useCallback(
    () => (
      <>
        <CloseButton
          elementRef={el => (closeButtonRef.current = el as HTMLButtonElement)}
          placement="end"
          offset="small"
          onClick={onClose}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{I18n.t('Copy')}</Heading>
      </>
    ),
    [onClose],
  )

  const renderBody = useCallback(() => {
    const fileName = fileOptions.name || fileOptions.file.name

    if (!isEditing && !fileOptions.cannotOverwrite) {
      return (
        <Text>
          {I18n.t(
            'A file named "%{fileName}" already exists in this location. Do you want to replace the existing file?',
            {fileName},
          )}
        </Text>
      )
    } else {
      return (
        <>
          <Text>{I18n.t('Change "%{fileName}" to:', {fileName})}</Text>
          <View display="block" margin="small 0 0 0">
            <TextInput
              data-testid="rename-change-input"
              renderLabel={I18n.t('Name')}
              value={renameFileInput}
              onChange={(_e, value) => setRenameFileInput(value)}
            />
          </View>
        </>
      )
    }
  }, [fileOptions, isEditing, renameFileInput])

  const renderFooter = useCallback(() => {
    if (fileOptions.cannotOverwrite) {
      return (
        <Button data-testid="rename-change-button" color="primary" onClick={handleChangeClick}>
          {I18n.t('Change')}
        </Button>
      )
    } else if (!isEditing) {
      return (
        <>
          <Button data-testid="rename-skip-button" margin="0 x-small 0 0" onClick={handleSkipClick}>
            {I18n.t('Skip')}
          </Button>
          <Button
            data-testid="rename-change-button"
            margin="0 x-small 0 0"
            onClick={handleRenameClick}
          >
            {I18n.t('Change Name')}
          </Button>
          <Button data-testid="rename-replace-button" color="primary" onClick={handleReplaceClick}>
            {I18n.t('Replace')}
          </Button>
        </>
      )
    } else {
      return (
        <>
          <Button data-testid="rename-back-button" margin="0 x-small 0 0" onClick={handleBackClick}>
            {I18n.t('Back')}
          </Button>
          <Button data-testid="rename-change-button" color="primary" onClick={handleChangeClick}>
            {I18n.t('Change')}
          </Button>
        </>
      )
    }
  }, [
    fileOptions,
    handleBackClick,
    handleChangeClick,
    handleRenameClick,
    handleReplaceClick,
    handleSkipClick,
    isEditing,
  ])

  useEffect(() => setIsEditing(false), [fileOptions])

  useEffect(() => {
    if (isEditing && fileOptions) {
      setRenameFileInput(fileOptions.name || fileOptions.file.name)
    }
    // eslint-disable-next-line react-compiler/react-compiler
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isEditing])

  return (
    <Modal
      open={open}
      onDismiss={onClose}
      size="small"
      label={I18n.t('Copy')}
      shouldCloseOnDocumentClick={false}
    >
      <Modal.Header>{renderHeader()}</Modal.Header>
      <Modal.Body>{renderBody()}</Modal.Body>
      <Modal.Footer>{renderFooter()}</Modal.Footer>
    </Modal>
  )
}

export default FileRenameForm
