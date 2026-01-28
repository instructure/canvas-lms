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

import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Alert} from '@instructure/ui-alerts'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {FormField} from '@instructure/ui-form-field'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {TruncateText} from '@instructure/ui-truncate-text'
import {View} from '@instructure/ui-view'
import formatMessage from 'format-message'
import {useRef, useState} from 'react'
import CanvasSelect from '../shared/CanvasSelect'
import {validateCaptionFile} from './utils/validation'

interface ManualCaptionCreatorProps {
  languages: {id: string; label: string}[]
  onPrimary: (languageId: string, file: File) => void
  onCancel: () => void
  liveRegion: () => HTMLElement | null
}

export function ManualCaptionCreator({
  languages,
  onPrimary,
  onCancel,
  liveRegion,
}: ManualCaptionCreatorProps) {
  const [selectedLanguageId, setSelectedLanguageId] = useState<string>('')
  const [selectedFile, setSelectedFile] = useState<File | null>(null)
  const [showLanguageError, setShowLanguageError] = useState(false)
  const [fileValidationError, setFileValidationError] = useState<string>('')
  const fileInputRef = useRef<HTMLInputElement>(null)

  const handleLanguageChange = (_event: React.SyntheticEvent, data: string) => {
    if (data) {
      setSelectedLanguageId(String(data))
      setShowLanguageError(false)
    }
  }

  const handleFileUpload = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (!file) return

    const validation = validateCaptionFile(file)
    if (!validation.valid) {
      setFileValidationError(validation.error || '')
      setSelectedFile(null)
    } else {
      setFileValidationError('')
      setSelectedFile(file)
    }
  }

  const handleUploadClick = () => {
    if (!selectedLanguageId) {
      setShowLanguageError(true)
    }

    if (!selectedFile) {
      setFileValidationError(`Please select a file before uploading.`)
    }

    // Only proceed if both are selected
    if (selectedLanguageId && selectedFile) {
      onPrimary(selectedLanguageId, selectedFile)
    }
  }

  return (
    <Flex as="div" direction="column" gap="medium">
      <Flex.Item overflowY="hidden" overflowX="hidden">
        <Heading variant="titleCardMini">{formatMessage('Add New Caption')}</Heading>
        <Text variant="contentSmall">
          {formatMessage('Upload a subtitle track in either the SRT or WebVTT format.')}
        </Text>
      </Flex.Item>
      <FormField
        id="cc-language-select"
        layout="inline"
        width="100%"
        label={formatMessage('Language*')}
        messages={
          showLanguageError
            ? [
                {
                  type: 'newError',
                  text: formatMessage('Please select a language'),
                },
              ]
            : []
        }
      >
        <CanvasSelect
          label={<ScreenReaderContent>{formatMessage('Select Language')}</ScreenReaderContent>}
          placeholder={formatMessage('Select Language')}
          value={selectedLanguageId}
          translatedStrings={{
            USE_ARROWS: 'Use arrow keys to navigate options.',
            LIST_COLLAPSED: 'List collapsed.',
            LIST_EXPANDED: 'List expanded.',
            OPTION_SELECTED: '{option} selected.',
          }}
          onChange={handleLanguageChange}
        >
          {languages.map(option => (
            // @ts-expect-error - CanvasSelect.Option is a JS component without TS definitions
            <CanvasSelect.Option key={option.id} id={option.id} value={option.id}>
              {option.label}
            </CanvasSelect.Option>
          ))}
        </CanvasSelect>
        {showLanguageError && (
          <Alert
            variant="error"
            screenReaderOnly={true}
            isLiveRegionAtomic={true}
            liveRegion={liveRegion}
          >
            {formatMessage('Please select a language')}
          </Alert>
        )}
      </FormField>

      <FormField
        id="cc-file-upload"
        layout="inline"
        width="100%"
        label={formatMessage('File*')}
        inputContainerRef={el => el?.style.setProperty('min-width', '0')} // to allow truncation
        messages={
          fileValidationError
            ? [
                {
                  type: 'newError',
                  text: fileValidationError,
                },
              ]
            : []
        }
      >
        <Flex gap="space8" alignItems="center">
          <input
            ref={fileInputRef}
            type="file"
            accept=".vtt, .srt"
            onChange={handleFileUpload}
            style={{display: 'none'}}
          />
          <Flex.Item shouldShrink={false}>
            <Button
              onClick={() => fileInputRef.current?.click()}
              aria-label={
                selectedFile
                  ? formatMessage('Selected file: {name}', {name: selectedFile.name})
                  : formatMessage('Choose File')
              }
            >
              {formatMessage('Choose File')}
            </Button>
          </Flex.Item>
          {!selectedFile && <Text variant="contentSmall">{formatMessage('No file chosen')}</Text>}
          {selectedFile && (
            <View minWidth={0}>
              <Text variant="contentSmall">
                <TruncateText>{selectedFile.name}</TruncateText>
              </Text>
            </View>
          )}
        </Flex>
        {fileValidationError && (
          <Alert
            variant="error"
            screenReaderOnly={true}
            isLiveRegionAtomic={true}
            liveRegion={liveRegion}
          >
            {fileValidationError}
          </Alert>
        )}
      </FormField>

      <Flex gap="small">
        <Button color="secondary" onClick={onCancel} textAlign="center" width="auto">
          {formatMessage('Cancel')}
        </Button>

        <Button color="primary" onClick={handleUploadClick} textAlign="center" width="auto">
          {formatMessage('Upload')}
        </Button>
      </Flex>
    </Flex>
  )
}
