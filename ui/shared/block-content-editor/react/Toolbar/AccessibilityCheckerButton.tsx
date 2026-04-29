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

import React, {useState} from 'react'
import {ToolbarButton} from './ToolbarButton'
import {AccessibleContent} from '@instructure/ui-a11y-content'
import {IconA11yLine} from '@instructure/ui-icons'
import {Badge} from '@instructure/ui-badge'
import {useScope as createI18nScope} from '@canvas/i18n'
import {AccessibilityCheckerPopover} from '../accessibilityChecker/AccessibilityCheckerPopover'
import type {AccessibilityIssue} from '../accessibilityChecker/types'

const I18n = createI18nScope('block_content_editor')

interface AccessibilityButtonProps {
  count?: number
  issues?: AccessibilityIssue[]
}

export const AccessibilityCheckerButton = ({count = 0, issues = []}: AccessibilityButtonProps) => {
  const [isPopoverOpen, setIsPopoverOpen] = useState(false)

  const screenReaderLabel = I18n.t('Accessibility Checker')

  const handleButtonClick = () => {
    setIsPopoverOpen(true)
  }
  const handleShowContent = () => {
    setIsPopoverOpen(true)
  }
  const handleHideContent = () => {
    setIsPopoverOpen(false)
  }

  return (
    <AccessibilityCheckerPopover
      isShowingContent={isPopoverOpen}
      onShowContent={handleShowContent}
      onHideContent={handleHideContent}
      issues={issues}
      renderTrigger={() => (
        // div wrapper is needed to pass aria-expanded
        <div>
          <Badge
            elementRef={el => {
              if (!el) {
                return
              }

              // Ensure not hidden behind focus outline
              const parentSpan = el as HTMLSpanElement
              const innerSpan = parentSpan.querySelector(':scope > span') as HTMLSpanElement
              innerSpan.style.zIndex = '11'
            }}
            count={count}
            countUntil={99}
            formatOutput={function (formattedCount) {
              return (
                <AccessibleContent
                  alt={I18n.t(
                    {
                      one: 'There is %{count} accessibility issue',
                      other: 'There are %{count} accessibility issues',
                      zero: '',
                    },
                    {count},
                  )}
                >
                  {formattedCount}
                </AccessibleContent>
              )
            }}
          >
            <ToolbarButton
              color={isPopoverOpen ? 'primary' : 'secondary'}
              screenReaderLabel={screenReaderLabel}
              renderIcon={<IconA11yLine />}
              onClick={handleButtonClick}
              data-testid="accessibility-button"
            />
          </Badge>
        </div>
      )}
    />
  )
}
