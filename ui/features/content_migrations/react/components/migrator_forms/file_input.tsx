/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {useCallback, useEffect, useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {IconUploadSolid} from '@instructure/ui-icons'
import {humanReadableSize} from '../utils'
import {ProgressBar} from '@instructure/ui-progress'
import type {FormMessage} from '@instructure/ui-form-field'
import {FileDrop} from '@instructure/ui-file-drop'

const I18n = useI18nScope('content_migrations_redesign')

type MigrationFileInputProps = {
  onChange: (file: File | null) => void
  accepts?: string | undefined
  fileUploadProgress: number | null
  isSubmitting?: boolean
  externalFormMessage?: FormMessage
}

const getHintMessage = (text: string): FormMessage => ({text, type: 'hint'})
const getErrorMessage = (text: string): FormMessage => ({text, type: 'error'})

const MigrationFileInput = ({
  onChange,
  accepts,
  fileUploadProgress,
  isSubmitting,
  externalFormMessage,
}: MigrationFileInputProps) => {
  const [formMessage, setFormMessage] = useState<FormMessage>(
    externalFormMessage || {text: I18n.t('No file chosen'), type: 'hint'}
  )

  useEffect(() => {
    externalFormMessage && setFormMessage(externalFormMessage)
  }, [externalFormMessage])

  const handleDropAccepted = useCallback(
    (files: ArrayLike<DataTransferItem | File>) => {
      if (!Array.isArray(files) || !files.every(singleFile => singleFile instanceof File)) {
        return onChange(null)
      }
      const selectedFile = files[0]

      if (!selectedFile) {
        return onChange(null)
      }
      if (ENV.UPLOAD_LIMIT && selectedFile.size > ENV.UPLOAD_LIMIT) {
        onChange(null)
        return setFormMessage(
          getErrorMessage(
            I18n.t('Your migration can not exceed %{upload_limit}', {
              upload_limit: humanReadableSize(ENV.UPLOAD_LIMIT),
            })
          )
        )
      }
      if (selectedFile.name) {
        setFormMessage(getHintMessage(selectedFile.name))
      }
      onChange(selectedFile)
    },
    [onChange, setFormMessage]
  )

  const handleDropRejected = useCallback(() => {
    onChange(null)
    setFormMessage(getErrorMessage(I18n.t('Invalid file type')))
  }, [onChange, setFormMessage])

  return (
    <>
      <View margin="none none x-small none" style={{display: 'block'}}>
        <label htmlFor="migrationFileUpload">
          <Text weight="bold">{I18n.t('Source')}</Text>
        </label>
      </View>
      <FileDrop
        accept={accepts || '.zip,.imscc,.mbz,.xml'}
        onDropAccepted={handleDropAccepted}
        interaction={isSubmitting ? 'disabled' : 'enabled'}
        data-testid="migrationFileUpload"
        onDropRejected={handleDropRejected}
        messages={[formMessage]}
        renderLabel={
          <View as="div" textAlign="center" padding="x-large large">
            <IconUploadSolid />
            <Text as="div" weight="bold">
              {I18n.t('Choose File')}
            </Text>
            <Text>
              {I18n.t('Drag and drop or')} <Text color="brand">{I18n.t('browse your files')}</Text>
            </Text>
          </View>
        }
        maxWidth="22.5rem"
      />
      {isSubmitting && (
        <View as="div" margin="small 0 0" style={{position: 'relative'}}>
          {I18n.t('Uploading File')}
          <ProgressBar
            size="small"
            meterColor="info"
            screenReaderLabel={I18n.t('Loading completion')}
            valueNow={fileUploadProgress || 0}
            valueMax={100}
            // @ts-ignore
            shouldAnimate={true}
          />
          <span style={{top: '25px', right: '-45px', position: 'absolute'}}>
            {fileUploadProgress}%
          </span>
        </View>
      )}
    </>
  )
}

export default MigrationFileInput
