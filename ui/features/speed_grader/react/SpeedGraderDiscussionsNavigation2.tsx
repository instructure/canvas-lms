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

import React, {useEffect, useState, useCallback} from 'react'
import {Flex} from '@instructure/ui-flex'
import {IconButton} from '@instructure/ui-buttons'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import { IconArrowOpenStartSolid, IconArrowDoubleStartSolid, IconArrowOpenEndSolid, IconArrowDoubleEndSolid } from '@instructure/ui-icons'

const I18n = createI18nScope('SpeedGraderDiscussionsNavigation')

type Props = {
  studentId: string | null
}

export const SpeedGraderDiscussionsNavigation2 = ({studentId}: Props) => {
  let studentEntryIds = window?.jsonData?.student_entries[`${studentId}`]
  if (studentEntryIds) {
    studentEntryIds = [...studentEntryIds]
    // sortOrder should always be asc, that way first entry is always oldest.
    studentEntryIds.sort((a: string, b: string) => {
      return parseInt(a, 10) - parseInt(b, 10);
    })
  }

  const totalEntries = studentEntryIds?.length

  function getStartingEntry() {
    const currentUrl = new URL(window.location.href)
    const params = new URLSearchParams(currentUrl.search)
    // default entry if none give is always the oldest, regardless of sort. The oldest entry will have the smallest id.
    // Math.min defaults if no entry_id param given
    const entry_id = parseInt(params.get('entry_id') || `${Math.min(...studentEntryIds)}`, 10)
    const index = studentEntryIds.indexOf(entry_id)
    // Math.min defaults if entry_id is invalid
    return index >= 0 ? index + 1 : studentEntryIds.indexOf(Math.min(...studentEntryIds)) + 1;
  }

  const [currentEntryIndex, setCurrentEntryIndex] = useState<number>(getStartingEntry())
  const [nextEnabled, setNextEnabled] = useState<boolean>(!(currentEntryIndex == totalEntries))
  const [prevEnabled, setPrevEnabled] = useState<boolean>(!(currentEntryIndex  == 1))

  const onMessage = useCallback((e: MessageEvent) => {
    const message = e.data
    switch (message.subject) {
      case 'DT.previousStudentReplyTab': {
        setNextEnabled(true)
        if(currentEntryIndex-1 <= 1){
          setPrevEnabled(false)
        }
        if( currentEntryIndex-1 >= 1){
          setCurrentEntryIndex(currentEntryIndex-1)
        }
        break
      }
      case 'DT.nextStudentReplyTab': {
        setPrevEnabled(true)
        if(currentEntryIndex+1 >= totalEntries){
          setNextEnabled(false)
        }
        if( currentEntryIndex+1 <= totalEntries){
          setCurrentEntryIndex(currentEntryIndex+1)
        }
        break
      }
    }
  }, [currentEntryIndex, totalEntries])

  useEffect(() => {
    window.addEventListener('message', onMessage)
    return () => {
      window.removeEventListener('message', onMessage)
    }
  }, [onMessage])

  function sendPostMessage(message: object) {
    const iframe = document.getElementById('speedgrader_iframe')
    // @ts-expect-error
    const iframeDoc = iframe?.contentDocument || iframe?.contentWindow.document
    const discussion_iframe = iframeDoc?.getElementById('discussion_preview_iframe')
    const contentWindow = discussion_iframe?.contentWindow
    if (contentWindow) {
      contentWindow.postMessage(message, '*')
    }
  }

  function firstStudentReply() {
    const message = {subject: 'DT.firstStudentReply'}
    sendPostMessage(message)
    setNextEnabled(true)
    setPrevEnabled(false)
    setCurrentEntryIndex(1)
  }

  function lastStudentReply() {
    const message = {subject: 'DT.lastStudentReply'}
    sendPostMessage(message)
    setNextEnabled(false)
    setPrevEnabled(true)
    setCurrentEntryIndex(totalEntries)
  }

  function previousStudentReply() {
    const message = {subject: 'DT.previousStudentReply'}
    sendPostMessage(message)
    setNextEnabled(true)
    if(currentEntryIndex-1 <= 1){
      setPrevEnabled(false)
    }
    setCurrentEntryIndex(currentEntryIndex-1)
  }

  function nextStudentReply() {
    const message = {subject: 'DT.nextStudentReply'}
    sendPostMessage(message)
    setPrevEnabled(true)
    if(currentEntryIndex+1 >= totalEntries){
      setNextEnabled(false)
    }
    setCurrentEntryIndex(currentEntryIndex+1)
  }

  return (
    <Flex justifyItems="start" margin="x-small x-small x-small none">
      <Flex.Item margin="medium none medium none" shouldShrink={true}>
        <IconButton data-testid="discussions-first-reply-button" screenReaderLabel={I18n.t('first student reply')} onClick={firstStudentReply} interaction={prevEnabled ? "enabled" : "disabled"}>
          <IconArrowDoubleStartSolid inline={true} />
        </IconButton>
      </Flex.Item>
      <Flex.Item margin="medium" shouldShrink={true}>
        <IconButton data-testid="discussions-previous-reply-button" screenReaderLabel={I18n.t('previous student reply')} onClick={previousStudentReply} interaction={prevEnabled ? "enabled" : "disabled"}>
          <IconArrowOpenStartSolid inline={true} />
        </IconButton>
      </Flex.Item>
      <Flex.Item margin="medium none medium none" shouldShrink={true}>
        <Text size="medium">
          {I18n.t('Reply %{currentEntryIndex} of %{totalEntries}', {
            currentEntryIndex,
            totalEntries,
          })}
        </Text>
      </Flex.Item>
      <Flex.Item margin="medium" shouldShrink={true}>
        <IconButton data-testid="discussions-next-reply-button" screenReaderLabel={I18n.t('next student reply')} onClick={nextStudentReply} interaction={nextEnabled ? "enabled" : "disabled"}>
          <IconArrowOpenEndSolid inline={true} />
        </IconButton>
      </Flex.Item>
      <Flex.Item margin="medium none medium none" shouldShrink={true}>
        <IconButton data-testid="discussions-last-reply-button" screenReaderLabel={I18n.t('last student reply')} onClick={lastStudentReply} interaction={nextEnabled ? "enabled" : "disabled"}>
          <IconArrowDoubleEndSolid inline={true} />
        </IconButton>
      </Flex.Item>
    </Flex>
  )
}
