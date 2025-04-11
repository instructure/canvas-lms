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

import React, {useState, useRef} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {LanguageSelector} from './LanguageSelector'
import {Button, IconButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {IconTrashLine} from '@instructure/ui-icons'
import {Flex} from '@instructure/ui-flex'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {FormField} from '@instructure/ui-form-field'
import {View} from '@instructure/ui-view'
import {colors} from '@instructure/canvas-theme'
import {useUploadTracks} from './useUploadTracks'
import {FileInputButton} from './FileInputButton'
import {Select} from '@instructure/ui-select'

type NodeFile = globalThis.File
const I18n = createI18nScope('files_v2')

export interface UploadMediaTrackFormProps {
  attachmentId: string
  closeForm: () => void
  existingLocales?: string[]
}

export const UploadMediaTrackForm = ({
  attachmentId,
  closeForm,
  existingLocales = [],
}: UploadMediaTrackFormProps) => {
  const [locale, setLocale] = useState<string | null>(null)
  const [file, setFile] = useState<NodeFile | null>(null)
  const [localeError, setLocaleError] = useState('')
  const [fileError, setFileError] = useState('')
  const localeInputRef = useRef<Select>(null)
  const fileButtonRef = useRef<Button>(null)
  const uploadMutation = useUploadTracks({attachmentId})

  const handleLocaleChange = (locale: string | null) => {
    if (locale) setLocaleError('')
    setLocale(locale)
  }

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files
    if (files && files.length > 0) {
      setFile(files[0])
      setFileError('')
    } else {
      setFile(null)
    }
  }

  const handleSubmit = async () => {
    if (!file) {
      setFileError(I18n.t('Please upload a file.'))
      fileButtonRef.current?.focus()
    }

    if (!locale) {
      setLocaleError(I18n.t('Please choose a language for the caption.'))
      localeInputRef.current?.focus()
    }

    if (!locale || !file) return

    try {
      await uploadMutation.mutateAsync({locale, file})
      closeForm()
    } catch (_e) {
      showFlashError(I18n.t('There was an error uploading your caption. Please try again.'))()
    }
  }

  return (
    <div>
      <LanguageSelector
        locale={locale}
        handleLocaleChange={handleLocaleChange}
        existingLocales={existingLocales}
        localeError={localeError}
        ref={localeInputRef}
      />

      <View as="div" padding="medium 0 0 0">
        <FormField
          id="content"
          label={
            <>
              <Text color="primary-inverse">{I18n.t('File')}</Text>
              <span style={{color: fileError ? colors.ui.textError : colors.primitives.white}}>
                *
              </span>
            </>
          }
          messages={fileError ? [{text: fileError, type: 'newError'}] : []}
          required
        >
          {file ? (
            <Flex justifyItems="space-between">
              <Text color="primary-inverse">{file.name}</Text>
              <IconButton
                color="primary-inverse"
                screenReaderLabel={I18n.t('Remove file')}
                onClick={() => {
                  setFile(null)
                }}
                withBorder={false}
                withBackground={false}
              >
                <IconTrashLine />
              </IconButton>
            </Flex>
          ) : (
            <FileInputButton onFileChange={handleFileChange} ref={fileButtonRef} />
          )}
        </FormField>
      </View>
      <p>{I18n.t('Supported file types: SRT or WebVTT')}</p>
      <div>
        <Button
          onClick={closeForm}
          withBackground={false}
          color="primary-inverse"
          disabled={uploadMutation.isLoading}
        >
          {I18n.t('Cancel')}
        </Button>
        <Button
          color="primary-inverse"
          margin="small"
          disabled={uploadMutation.isLoading}
          data-testid="save-button"
          onClick={handleSubmit}
        >
          {I18n.t('Save')}
        </Button>
      </div>
    </div>
  )
}
