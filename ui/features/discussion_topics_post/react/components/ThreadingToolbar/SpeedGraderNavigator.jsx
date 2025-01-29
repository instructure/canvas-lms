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

import {useScope as createI18nScope} from '@canvas/i18n'
import React, {useState, useRef, useContext} from 'react'
import {Flex} from '@instructure/ui-flex'
import {Button} from '@instructure/ui-buttons'
import useSpeedGrader from '../../hooks/useSpeedGrader'
import {DiscussionManagerUtilityContext, SearchContext} from '../../utils/constants'

const I18n = createI18nScope('speed_grader')

const visuallyHiddenStyles = {
  border: 0,
  clip: 'rect(0 0 0 0)',
  height: '1px',
  margin: '-1px',
  overflow: 'hidden',
  padding: 0,
  width: '1px',
}

export const SpeedGraderNavigator = () => {
  const [isVisible, setIsVisible] = useState(false)
  const containerRef = useRef(null)

  const {
    highlightEntryId,
    setHighlightEntryId,
    setPageNumber,
    expandedThreads,
    setExpandedThreads,
    setFocusSelector,
  } = useContext(DiscussionManagerUtilityContext)

  const {sort, perPage, discussionID} = useContext(SearchContext)

  const {handlePreviousStudentReply, handleNextStudentReply, handleJumpFocusToSpeedGrader} =
    useSpeedGrader()

  const handleFocus = () => {
    setIsVisible(true)
  }

  const handleBlur = event => {
    if (!containerRef.current?.contains(event.relatedTarget)) {
      setIsVisible(false)
    }
  }

  const renderButton = (handler, testId, text) => {
    if (!handler) return null
    return (
      <Flex.Item padding="0 x-small">
        <Button data-testid={testId} id={testId} onClick={handler}>
          {text}
        </Button>
      </Flex.Item>
    )
  }

  return (
    <div
      ref={containerRef}
      id="speedgrader-navigator"
      style={isVisible ? {} : visuallyHiddenStyles}
      aria-hidden={!isVisible}
      onFocus={handleFocus}
      onBlur={handleBlur}
    >
      <Flex as="nav" justifyItems="start">
        {renderButton(
          handlePreviousStudentReply,
          'previous-in-speedgrader',
          I18n.t('Previous in SpeedGrader'),
        )}
        {renderButton(handleNextStudentReply, 'next-in-speedgrader', I18n.t('Next in SpeedGrader'))}
        {renderButton(
          handleJumpFocusToSpeedGrader,
          'jump-to-speedgrader-navigation',
          I18n.t('Jump to SpeedGrader Navigation'),
        )}
      </Flex>
    </div>
  )
}
