/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import React, {useCallback, useState} from 'react'
import {IconCheckDarkSolid, IconCopyLine, IconXSolid} from '@instructure/ui-icons'
import {IconButton} from '@instructure/ui-buttons'
import {useTranslation} from '@canvas/i18next'
import {Tooltip} from '@instructure/ui-tooltip'

export type CopyToClipboardButtonProps = {
  value: string
  screenReaderLabel?: string
  tooltipText?: string
  buttonProps?: Partial<unknown>
  tooltip?: boolean
}

export default function CopyToClipboardButton({
  value,
  screenReaderLabel,
  tooltipText,
  buttonProps,
  tooltip,
}: CopyToClipboardButtonProps) {
  const {t} = useTranslation('copy-to-clipboard-button')
  const resolvedScreenReaderLabel = screenReaderLabel ?? t('Copy')
  const resolvedTooltipText = tooltipText ?? t('Copy')
  const [feedback, setFeedback] = useState<boolean | null>(null)

  const temporarilySetFeedback = useCallback(
    (success: boolean) => {
      setFeedback(success)
      setTimeout(() => setFeedback(null), 1000)
    },
    [setFeedback],
  )

  const copyToClipboardAction = useCallback(() => {
    return navigator.clipboard.writeText(value).then(
      () => temporarilySetFeedback(true),
      () => temporarilySetFeedback(false),
    )
  }, [temporarilySetFeedback, value])

  const renderFeedbackIcon = useCallback(() => {
    if (feedback === true) return <IconCheckDarkSolid color="success" />
    else if (feedback === false) return <IconXSolid color="error" />
    else return <IconCopyLine />
  }, [feedback])

  // Clipboard API is not available at insecure origins, so just render nothing
  if (!navigator.clipboard) return null

  const button = (
    <IconButton
      size="small"
      screenReaderLabel={resolvedScreenReaderLabel}
      {...buttonProps}
      onClick={copyToClipboardAction}
    >
      {renderFeedbackIcon()}
    </IconButton>
  )

  return tooltip && resolvedTooltipText ? (
    <Tooltip renderTip={resolvedTooltipText} on={['hover', 'focus']}>
      {button}
    </Tooltip>
  ) : (
    button
  )
}
