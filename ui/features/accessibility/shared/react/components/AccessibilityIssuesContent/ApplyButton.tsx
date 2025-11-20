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

import React, {useCallback, useEffect, useRef} from 'react'

import {Button, CondensedButton} from '@instructure/ui-buttons'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {PresentationContent} from '@instructure/ui-a11y-content'
import {IconPublishSolid} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {Spinner} from '@instructure/ui-spinner'

interface ApplyButtonProps {
  children: string
  undoMessage?: string
  onApply: () => void
  onUndo: () => void
  isApplied: boolean
  isLoading: boolean
}

const I18n = createI18nScope('accessibility_checker')

const ApplyButton: React.FC<ApplyButtonProps> = ({
  children,
  onApply,
  onUndo,
  undoMessage,
  isApplied,
  isLoading,
}: ApplyButtonProps) => {
  const undoButtonRef = useRef<HTMLButtonElement | null>(null)
  const applyButtonRef = useRef<HTMLButtonElement | null>(null)
  const actionPerformedRef = useRef<boolean>(false)

  const handleApply = useCallback(() => {
    actionPerformedRef.current = true
    onApply()
  }, [onApply])

  const handleUndo = useCallback(() => {
    actionPerformedRef.current = true
    onUndo()
  }, [onUndo])

  useEffect(() => {
    if (!actionPerformedRef.current) return

    if (isApplied) {
      undoButtonRef.current?.focus()
    } else {
      applyButtonRef.current?.focus()
    }
    actionPerformedRef.current = false
  }, [isApplied])

  if (isApplied) {
    return (
      <Flex gap="x-small">
        <Flex.Item>
          <PresentationContent>
            <IconPublishSolid color="success" />
          </PresentationContent>
        </Flex.Item>
        <Flex.Item>
          <Text>{undoMessage || I18n.t('Issue fixed')}</Text>
        </Flex.Item>
        <Flex.Item>
          <CondensedButton
            data-testid="undo-button"
            elementRef={e => (undoButtonRef.current = e as HTMLButtonElement)}
            interaction={isLoading ? 'disabled' : 'enabled'}
            onClick={handleUndo}
          >
            {isLoading ? (
              <>
                {I18n.t('Undo')} <Spinner size="x-small" renderTitle={I18n.t('Loading...')} />
              </>
            ) : (
              I18n.t('Undo')
            )}
          </CondensedButton>
        </Flex.Item>
      </Flex>
    )
  } else {
    return (
      <Button
        data-testid="apply-button"
        elementRef={e => (applyButtonRef.current = e as HTMLButtonElement)}
        color="primary"
        interaction={isLoading ? 'disabled' : 'enabled'}
        onClick={handleApply}
      >
        {isLoading ? (
          <>
            {children} <Spinner size="x-small" renderTitle={I18n.t('Loading...')} />
          </>
        ) : (
          children
        )}
      </Button>
    )
  }
}

export default ApplyButton
