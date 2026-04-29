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

import React, {useRef, useEffect} from 'react'
import {IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconArrowOpenStartLine, IconArrowOpenEndLine} from '@instructure/ui-icons'

export interface NavigatorProps {
  hasPrevious: boolean
  hasNext: boolean
  onPrevious: () => void
  onNext: () => void
}

export interface NavigatorComponentProps extends NavigatorProps {
  disabled?: boolean
  previousLabel: string
  nextLabel: string
  children: React.ReactNode
  'data-testid'?: string
}

export const Navigator: React.FC<NavigatorComponentProps> = ({
  disabled = false,
  hasPrevious,
  hasNext,
  previousLabel,
  nextLabel,
  onPrevious,
  onNext,
  children,
  'data-testid': testId,
}) => {
  const previousButtonRef = useRef<HTMLButtonElement | null>(null)
  const nextButtonRef = useRef<HTMLButtonElement | null>(null)
  const prevHasPrevious = useRef(hasPrevious)
  const prevHasNext = useRef(hasNext)

  useEffect(() => {
    const reachedFirst = prevHasPrevious.current && !hasPrevious
    const reachedLast = prevHasNext.current && !hasNext

    if (reachedFirst && nextButtonRef.current) {
      nextButtonRef.current.focus()
    } else if (reachedLast && previousButtonRef.current) {
      previousButtonRef.current.focus()
    }

    prevHasPrevious.current = hasPrevious
    prevHasNext.current = hasNext
  }, [hasPrevious, hasNext])

  const handlePreviousClick = () => {
    onPrevious()
    setTimeout(() => previousButtonRef.current?.focus(), 0)
  }

  const handleNextClick = () => {
    onNext()
    setTimeout(() => nextButtonRef.current?.focus(), 0)
  }

  return (
    <Flex
      alignItems="center"
      justifyItems="space-between"
      gap="small"
      data-testid={testId}
      width="100%"
    >
      <IconButton
        elementRef={(el: Element | null) => {
          previousButtonRef.current = el as HTMLButtonElement | null
        }}
        disabled={!hasPrevious || disabled}
        color="secondary"
        onClick={handlePreviousClick}
        size="small"
        renderIcon={<IconArrowOpenStartLine />}
        screenReaderLabel={previousLabel}
        data-testid="previous-button"
        withBackground={false}
      />
      <Flex.Item shouldGrow={true} shouldShrink={true} textAlign="center">
        {children}
      </Flex.Item>
      <IconButton
        elementRef={(el: Element | null) => {
          nextButtonRef.current = el as HTMLButtonElement | null
        }}
        disabled={!hasNext || disabled}
        color="secondary"
        onClick={handleNextClick}
        size="small"
        renderIcon={<IconArrowOpenEndLine />}
        screenReaderLabel={nextLabel}
        data-testid="next-button"
        withBackground={false}
      />
    </Flex>
  )
}
