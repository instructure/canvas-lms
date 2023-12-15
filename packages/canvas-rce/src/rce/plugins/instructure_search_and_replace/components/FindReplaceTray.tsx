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

import React, {useEffect, useRef, useState} from 'react'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Grid, GridRow, GridCol} from '@instructure/ui-grid'
import {Heading} from '@instructure/ui-heading'
import {getTrayHeight} from '../../shared/trayUtils'
import {View} from '@instructure/ui-view'
import {instuiPopupMountNode} from '../../../../util/fullscreenHelpers'
import formatMessage from 'format-message'
import {Tray} from '@instructure/ui-tray'
import {TextInput, TextInputProps} from '@instructure/ui-text-input'
import {Text} from '@instructure/ui-text'
import {FormMessage} from '@instructure/ui-form-field'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

type FindReplaceTrayProps = {
  onNext: () => void
  onPrevious: () => void
  onFind: (text: string) => void
  onRequestClose: () => void
  onReplace: (newText: string, forward?: boolean, all?: boolean) => void
  index: number
  max: number
  initialText?: string
}

export default function FindReplaceTray({
  onNext,
  onPrevious,
  onFind,
  onRequestClose,
  onReplace,
  index,
  max,
  initialText = '',
}: FindReplaceTrayProps) {
  const [findText, setFindText] = useState(initialText)
  const [replaceText, setReplaceText] = useState('')
  const [hasOpened, setHasOpened] = useState(false)
  const trayRef = useRef<any>(null)

  // moves RCE when tray opens/closes, copied from CanvasContentTray
  useEffect(() => {
    if (!hasOpened) return

    let c = document.querySelector('[role="main"]') as any
    let target_w = 0
    if (!c) return

    const margin =
      window.getComputedStyle(c).direction === 'ltr'
        ? document.body.getBoundingClientRect().right - c.getBoundingClientRect().right
        : c.getBoundingClientRect().left

    target_w = c.offsetWidth - trayRef.current?.offsetWidth + margin

    if (target_w >= 320 && target_w < c.offsetWidth) {
      c.style.boxSizing = 'border-box'
      c.style.width = `${target_w}px`
    }

    return () => {
      c = document.querySelector('[role="main"]')
      if (!c) return
      c.style.width = ''
    }
  }, [hasOpened])

  useEffect(() => {
    if (initialText) {
      onFind(initialText)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const handleTextChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setFindText(e.target.value)
    onFind(e.target.value)
  }

  const handleFindKeyDown = (e: React.KeyboardEvent<TextInputProps>) => {
    if (e.key !== 'Enter') return
    if (e.shiftKey) {
      if (isButtonDisabled('previous')) return
      onPrevious()
    } else {
      // try to search when there are currently no results and user presses enter
      if (index === 0 && max === 0 && findText) {
        onFind(findText)
        return
      }
      if (isButtonDisabled('next')) return
      onNext()
    }
  }

  const handleReplaceKeyDown = (e: React.KeyboardEvent<any>) => {
    if (e.key !== 'Enter') return
    if (isButtonDisabled('replace')) return
    const forward = !e.shiftKey
    onReplace(replaceText, forward, false)
  }

  const resultText = () => {
    // resolves issue where focus is lost when this (dis)appears
    if (max === 0) {
      return <Text />
    }
    const msg = formatMessage('{index} of {max}', {index, max})
    return (
      <>
        <ScreenReaderContent aria-live="assertive" aria-relevant="text additions">
          {msg}
        </ScreenReaderContent>
        <Text>{msg}</Text>
      </>
    )
  }

  const isButtonDisabled = (button: 'next' | 'previous' | 'replace' | 'replaceAll') => {
    switch (button) {
      case 'next':
      case 'previous':
        return max < 2
      case 'replace':
        return !replaceText || index === 0
      case 'replaceAll':
        return !replaceText || max < 2 || index === 0
      default:
        return false
    }
  }

  const errMsg = formatMessage('No results found')
  const messages =
    findText && max === 0
      ? ([
          {text: errMsg, type: 'error'},
          {text: errMsg, type: 'screenreader-only'},
        ] as FormMessage[])
      : []

  return (
    <Tray
      data-mce-component={true}
      label={formatMessage('Find and Replace')}
      mountNode={instuiPopupMountNode}
      onDismiss={onRequestClose}
      open={true}
      placement="end"
      size="regular"
      shouldContainFocus={true}
      shouldReturnFocus={true}
      shouldCloseOnDocumentClick={true}
      onOpen={() => setHasOpened(true)}
      contentRef={el => (trayRef.current = el)}
    >
      <Flex direction="column" height={getTrayHeight()}>
        <Flex.Item as="header" padding="medium medium small">
          <Flex direction="row">
            <Flex.Item shouldGrow={true} shouldShrink={true}>
              <Heading as="h2">{formatMessage('Find and Replace')}</Heading>
            </Flex.Item>
            <Flex.Item>
              <CloseButton
                screenReaderLabel={formatMessage('Close')}
                placement="end"
                onClick={onRequestClose}
              />
            </Flex.Item>
          </Flex>
        </Flex.Item>
        <Flex.Item as="div" padding="0 large large">
          <View as="div" margin="large 0 medium 0">
            <TextInput
              renderLabel={formatMessage('Find')}
              name="findtext"
              onChange={e => handleTextChange(e)}
              onKeyDown={e => handleFindKeyDown(e)}
              value={findText}
              placeholder={formatMessage('enter search text')}
              renderAfterInput={resultText()}
              messages={messages}
              data-testid="find-text-input"
            />
          </View>
          <View as="div" margin="large 0 medium 0">
            <TextInput
              renderLabel={formatMessage('Replace with')}
              name="replacetext"
              onChange={e => setReplaceText(e.target.value)}
              onKeyDown={e => handleReplaceKeyDown(e)}
              value={replaceText}
              placeholder={formatMessage('enter replacement text')}
              data-testid="replace-text-input"
            />
          </View>
          <View as="div">
            <Grid vAlign="middle" hAlign="space-between" colSpacing="none">
              <GridRow>
                <GridCol width="auto">
                  <Button
                    color="secondary"
                    margin="0 small 0 0"
                    onClick={() => onReplace(replaceText, true, true)}
                    disabled={isButtonDisabled('replaceAll')}
                  >
                    {formatMessage('Replace All')}
                  </Button>
                  <Button
                    color="secondary"
                    margin="0 small 0 0"
                    onClick={() => {
                      onReplace(replaceText, true, false)
                    }}
                    disabled={isButtonDisabled('replace')}
                    data-testid="replace-button"
                  >
                    {formatMessage('Replace')}
                  </Button>
                </GridCol>
                <GridCol>
                  <Button
                    color="primary"
                    onClick={onPrevious}
                    disabled={isButtonDisabled('previous')}
                  >
                    {formatMessage('Previous')}
                  </Button>
                </GridCol>
                <GridCol>
                  <Button color="primary" onClick={onNext} disabled={isButtonDisabled('next')}>
                    {formatMessage('Next')}
                  </Button>
                </GridCol>
              </GridRow>
            </Grid>
          </View>
        </Flex.Item>
      </Flex>
    </Tray>
  )
}
