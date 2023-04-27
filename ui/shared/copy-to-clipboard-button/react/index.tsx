// @ts-nocheck
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
import {IconButton, IconButtonProps} from '@instructure/ui-buttons'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Tooltip} from '@instructure/ui-tooltip'

const I18n = useI18nScope('copy-to-clipboard-button')

export type CopyToClipboardButtonProps = {
  value: string
  screenReaderLabel: string
  tooltipText?: string
  buttonProps?: Partial<IconButtonProps>
  tooltip?: boolean
}

export default function CopyToClipboardButton({
  value,
  screenReaderLabel,
  tooltipText,
  buttonProps,
  tooltip,
}: CopyToClipboardButtonProps) {
  const [feedback, setFeedback] = useState<boolean | null>(null)

  const temporarilySetFeedback = useCallback(
    success => {
      setFeedback(success)
      setTimeout(() => setFeedback(null), 1000)
    },
    [setFeedback]
  )

  const copyToClipboardAction = useCallback(() => {
    return navigator.clipboard.writeText(value).then(
      () => temporarilySetFeedback(true),
      () => temporarilySetFeedback(false)
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
      screenReaderLabel={screenReaderLabel}
      {...buttonProps}
      onClick={copyToClipboardAction}
    >
      {renderFeedbackIcon()}
    </IconButton>
  )

  return tooltip && tooltipText ? (
    <Tooltip renderTip={tooltipText} on={['hover', 'focus']}>
      {button}
    </Tooltip>
  ) : (
    button
  )
}

CopyToClipboardButton.defaultProps = {
  screenReaderLabel: I18n.t('Copy'),
  tooltipText: I18n.t('Copy'),
}
