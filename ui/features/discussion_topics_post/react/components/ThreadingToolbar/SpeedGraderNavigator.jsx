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

import {useScope as useI18nScope} from '@canvas/i18n'
import React, {useState, useRef} from 'react'
import {Flex} from '@instructure/ui-flex'
import {Button} from '@instructure/ui-buttons'

const I18n = useI18nScope('speed_grader')

const visuallyHiddenStyles = {
  border: 0,
  height: '1px',
  margin: '-1px',
  overflow: 'hidden',
  padding: 0,
  width: '1px',
}

export const SpeedGraderNavigator = props => {
  const [isVisible, setIsVisible] = useState(false)
  const containerRef = useRef(null)

  const handlePrevious = () => {
    // Handle previous action
  }

  const handleNext = () => {
    // Handle next action
  }

  const handleJump = () => {
    // Handle jump action
  }

  const handleFocus = () => {
    setIsVisible(true)
  }

  const handleBlur = (event) => {
    if (!containerRef.current.contains(event.relatedTarget)) {
      setIsVisible(false)
    }
  }

  return (
    <div
      ref={containerRef}
      style={isVisible ? {} : visuallyHiddenStyles}
      aria-hidden={!isVisible}
      onFocus={handleFocus}
      onBlur={handleBlur}
    >
      <Flex as="nav" justifyItems="start">
        <Flex.Item padding="0 x-small 0 0">
          <Button
            data-testid="previous-in-speedgrader"
            onClick={handlePrevious}
          >
            {I18n.t('Previous in SpeedGrader')}
          </Button>
        </Flex.Item>
        <Flex.Item padding="0 x-small">
          <Button
            data-testid="next-in-speedgrader"
            onClick={handleNext}
          >
            {I18n.t('Next in SpeedGrader')}
          </Button>
        </Flex.Item>
        <Flex.Item padding="0 0 0 x-small">
          <Button
            data-testid="jump-to-speedgrader-navigation"
            onClick={handleJump}
          >
            {I18n.t('Jump to SpeedGrader Navigation')}
          </Button>
        </Flex.Item>
      </Flex>
    </div>
  )
}