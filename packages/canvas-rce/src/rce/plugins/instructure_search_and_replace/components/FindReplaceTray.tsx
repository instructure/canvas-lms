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
import {Heading} from '@instructure/ui-heading'
import {getTrayHeight} from '../../shared/trayUtils'
import {View} from '@instructure/ui-view'
import {instuiPopupMountNode} from '../../../../util/fullscreenHelpers'
import formatMessage from '../../../../format-message'
import {Tray} from '@instructure/ui-tray'
import {TextInput, TextInputProps} from '@instructure/ui-text-input'
import {Text} from '@instructure/ui-text'
import {FormMessage} from '@instructure/ui-form-field'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Alert} from '@instructure/ui-alerts'

type FindReplaceTrayProps = {
  onNext: () => void
  onPrevious: () => void
  onFind: (text: string) => void
  onRequestClose: () => void
  onReplace: (newText: string, forward?: boolean, all?: boolean) => void
  index: number
  max: number
  initialText?: string
  selectionContext?: string[]
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
  selectionContext = ['', ''],
}: FindReplaceTrayProps) {
  const [findText, setFindText] = useState(initialText)
  const [replaceText, setReplaceText] = useState('')
  const [hasOpened, setHasOpened] = useState(false)
  const [showReplaceAlert, setShowReplaceAlert] = useState<'' | 'replace' | 'replaceAll'>('')
  const [alertFindText, setAlertFindText] = useState('')
  const [alertReplaceText, setAlertReplaceText] = useState('')
  const trayRef = useRef<any>(null)
  const liveRegionKey = useRef(0)
  const srDupKey = useRef(0)
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

  function usePrevious(value: any) {
    const ref = useRef()
    useEffect(() => {
      ref.current = value
    }, [value])
    return ref.current
  }
  const prepend = selectionContext[0]
  const append = selectionContext[1]
  const srContextMsg = formatMessage('{prepend}{findText}{append}', {prepend, findText, append})
  const previousSrMsg = usePrevious(srContextMsg)
  const previousFindText = usePrevious(findText)

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
    replace(replaceText, forward, false)
  }

  const replace = (newText: string, forward?: boolean, all?: boolean) => {
    onReplace(newText, forward, all)
    if (all) {
      setShowReplaceAlert('replaceAll')
    } else {
      setShowReplaceAlert('replace')
    }
    setAlertFindText(findText)
    setAlertReplaceText(newText)
    liveRegionKey.current++
  }

  const alertText =
    showReplaceAlert === ''
      ? ''
      : showReplaceAlert === 'replace'
      ? formatMessage('Replaced {alertFindText} with {alertReplaceText}', {
          alertFindText,
          alertReplaceText,
        })
      : formatMessage('Replaced all {alertFindText} with {alertReplaceText}', {
          alertFindText,
          alertReplaceText,
        })

  const renderReplaceAlert = () => {
    if (!showReplaceAlert) {
      liveRegionKey.current = 0
      return <></>
    }
    return (
      <Alert
        variant="success"
        renderCloseButtonLabel="Close Alert"
        margin="small"
        transition="fade"
        onDismiss={() => setShowReplaceAlert('')}
        timeout={3000}
      >
        {alertText}
      </Alert>
    )
  }

  const renderScreenReaderAlert = () => {
    return <ScreenReaderContent>{alertText}</ScreenReaderContent>
  }

  const errMsg = formatMessage('No results found')
  const messages = findText && max === 0 ? ([{text: errMsg, type: 'error'}] as FormMessage[]) : []

  const resultText = () => {
    const srErrMsg = messages.length === 0 ? '' : errMsg
    // resolves issue where focus is lost when this (dis)appears
    if (max === 0) {
      return (
        <>
          <ScreenReaderContent aria-live="polite">{srErrMsg}</ScreenReaderContent>
          <Text />
        </>
      )
    }
    const msg = formatMessage('{index} of {max}', {index, max})
    const srResultMsg = formatMessage('Result {index} of {max}.', {index, max})

    // necessary to force screen reader to read the same message while typing
    if (srContextMsg === previousSrMsg && previousFindText != findText) {
      srDupKey.current++
    } else srDupKey.current = 0
    return (
      <>
        <View as="span" key={srDupKey.current} aria-live="polite" aria-atomic="true" role="alert">
          <ScreenReaderContent>
            {srResultMsg} {srContextMsg}
          </ScreenReaderContent>
        </View>
        <Text aria-hidden="true">{msg}</Text>
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
    >
      <View as="div" margin="none none medium none" key={liveRegionKey.current}>
        {renderReplaceAlert()}
        <View as="div" role="alert" aria-live="polite">
          {renderScreenReaderAlert()}
        </View>
      </View>
      <Flex direction="column" height={getTrayHeight()}>
        <Flex.Item padding="medium medium small">
          <Flex direction="row">
            <Flex.Item shouldGrow={true} shouldShrink={true}>
              <Heading as="h2">{formatMessage('Find and Replace')}</Heading>
            </Flex.Item>
            <Flex.Item>
              <CloseButton
                placement="static"
                color="primary"
                data-testid="close-button"
                screenReaderLabel={formatMessage('Close')}
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
          <View as="div">
            <Flex>
              <Flex.Item size="6.125rem">
                <Button
                  color="secondary"
                  margin="0 medium 0 0"
                  onClick={onPrevious}
                  disabled={isButtonDisabled('previous')}
                  data-testid="previous-button"
                  aria-label={formatMessage('Previous {findText}', {findText})}
                >
                  <span aria-hidden="true">{formatMessage('Previous')}</span>
                </Button>
              </Flex.Item>
              <Flex.Item>
                <Button
                  color="secondary"
                  margin="0 small 0 0"
                  onClick={onNext}
                  disabled={isButtonDisabled('next')}
                  data-testid="next-button"
                  aria-label={formatMessage('Next {findText}', {findText})}
                >
                  <span aria-hidden="true">{formatMessage('Next')}</span>
                </Button>
              </Flex.Item>
            </Flex>
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
            <Flex>
              <Flex.Item>
                <Button
                  color="secondary"
                  margin="0 small 0 0"
                  onClick={() => replace(replaceText, true, true)}
                  disabled={isButtonDisabled('replaceAll')}
                  data-testid="replace-all-button"
                  aria-label={formatMessage('Replace all {findText} with {replaceText}', {
                    findText,
                    replaceText,
                  })}
                >
                  <span aria-hidden="true">{formatMessage('Replace All')}</span>
                </Button>
              </Flex.Item>
              <Flex.Item>
                <Button
                  color="secondary"
                  margin="0 small 0 0"
                  onClick={() => {
                    replace(replaceText, true, false)
                  }}
                  disabled={isButtonDisabled('replace')}
                  data-testid="replace-button"
                  aria-label={formatMessage('Replace {findText} with {replaceText}', {
                    findText,
                    replaceText,
                  })}
                >
                  <span aria-hidden="true">{formatMessage('Replace')}</span>
                </Button>
              </Flex.Item>
            </Flex>
          </View>
        </Flex.Item>
      </Flex>
    </Tray>
  )
}
