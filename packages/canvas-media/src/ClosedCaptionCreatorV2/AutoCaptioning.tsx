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
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import formatMessage from 'format-message'
import {useEffect, useState} from 'react'
import CanvasSelect from '../shared/CanvasSelect'

interface AutoCaptioningProps {
  onCancel: () => void
  onPrimary: (selectedLanguageId: string) => void
  liveRegion: () => HTMLElement | null
  languages: {id: string; label: string}[]
  mountNode?: HTMLElement | (() => HTMLElement | null)
  onDirtyStateChanged?: (isDirty: boolean) => void
}

export const AutoCaptioning = ({
  onCancel,
  onPrimary,
  liveRegion,
  languages,
  mountNode,
  onDirtyStateChanged,
}: AutoCaptioningProps) => {
  const [selectedLanguageId, setSelectedLanguageId] = useState<string>('')
  const [showLanguageError, setShowLanguageError] = useState(false)

  const handleLanguageChange = (_event: React.SyntheticEvent, languageId: string) => {
    if (languageId) {
      setSelectedLanguageId(languageId)
      setShowLanguageError(false)
    }
    onDirtyStateChanged?.(Boolean(languageId))
  }

  const handlePrimaryClick = () => {
    if (!selectedLanguageId) {
      setShowLanguageError(true)
      return
    }

    onPrimary(selectedLanguageId)
  }

  return (
    <Flex as="div" direction="column" gap="medium">
      <Flex.Item overflowY="hidden" overflowX="hidden">
        <Heading variant="titleCardMini">{formatMessage('Automatic captioning')}</Heading>
        <Text variant="contentSmall">
          {formatMessage('Our technology generates ~85% accurate captions.')}
        </Text>
      </Flex.Item>

      <Flex gap="small" direction="column">
        <Heading variant="titleCardMini">{formatMessage('Language Spoken in This Media*')}</Heading>
        <CanvasSelect
          label={<ScreenReaderContent>{formatMessage('Select Language')}</ScreenReaderContent>}
          placeholder={formatMessage('Select Language')}
          value={selectedLanguageId}
          mountNode={mountNode}
          translatedStrings={{
            USE_ARROWS: formatMessage('Use arrow keys to navigate options.'),
            LIST_COLLAPSED: formatMessage('List collapsed.'),
            LIST_EXPANDED: formatMessage('List expanded.'),
            OPTION_SELECTED: '{option} selected.',
          }}
          onChange={handleLanguageChange}
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
          liveRegion={liveRegion}
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
      </Flex>

      <Flex gap="small">
        <Button color="secondary" onClick={onCancel} textAlign="center" width="auto">
          {formatMessage('Cancel')}
        </Button>
        <Button color="primary" onClick={handlePrimaryClick} textAlign="center" width="auto">
          {formatMessage('Request')}
        </Button>
      </Flex>
    </Flex>
  )
}
