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

import {useCallback, useRef} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {type FileOptions} from './FileOptions'

type ZipFileOptionsFormProps = {
  open: boolean
  onClose: () => void
  fileOptions: FileOptions
  onZipOptionsResolved: ({
    file,
    expandZip,
  }: {
    file: File
    expandZip: boolean
  }) => void
}

const I18n = createI18nScope('files_v2')

const ZipFileOptionsForm = ({
  open,
  onClose,
  fileOptions,
  onZipOptionsResolved,
}: ZipFileOptionsFormProps) => {
  const defaultFocusElement = useRef<Element | null>(null)

  const handleExpandClick = useCallback(
    () => onZipOptionsResolved({file: fileOptions.file, expandZip: true}),
    [fileOptions, onZipOptionsResolved],
  )

  const handleUploadClick = useCallback(
    () => onZipOptionsResolved({file: fileOptions.file, expandZip: false}),
    [fileOptions, onZipOptionsResolved],
  )

  const renderHeader = useCallback(
    () => (
      <>
        <CloseButton
          placement="end"
          offset="small"
          onClick={onClose}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{I18n.t('Zip file options')}</Heading>
      </>
    ),
    [onClose],
  )

  const renderBody = useCallback(() => {
    const fileName = fileOptions.file.name
    return (
      <Text>
        {I18n.t(
          'Would you like to expand the contents of "%{fileName}" into the current folder, or upload the zip file as is?',
          {fileName},
        )}
      </Text>
    )
  }, [fileOptions])

  const renderFooter = useCallback(() => {
    return (
      <>
        <Button data-testid="zip-expand-button" margin="0 x-small 0 0" onClick={handleExpandClick}>
          {I18n.t('Expand it')}
        </Button>
        <Button
          data-testid="zip-upload-button"
          color="primary"
          onClick={handleUploadClick}
          elementRef={element => (defaultFocusElement.current = element)}
        >
          {I18n.t('Upload it')}
        </Button>
      </>
    )
  }, [handleExpandClick, handleUploadClick])

  return (
    <Modal
      open={open}
      onDismiss={onClose}
      size="small"
      label={I18n.t('Zip file options')}
      shouldCloseOnDocumentClick={false}
      defaultFocusElement={() => defaultFocusElement.current}
    >
      <Modal.Header>{renderHeader()}</Modal.Header>
      <Modal.Body>{renderBody()}</Modal.Body>
      <Modal.Footer>{renderFooter()}</Modal.Footer>
    </Modal>
  )
}

export default ZipFileOptionsForm
