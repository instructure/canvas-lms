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
import PropTypes from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('copy-to-clipboard-button')

export default function CopyToClipboardButton({value, screenReaderLabel}) {
  const [feedback, setFeedback] = useState(null)

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

  return (
    <IconButton size="small" onClick={copyToClipboardAction} screenReaderLabel={screenReaderLabel}>
      {renderFeedbackIcon()}
    </IconButton>
  )
}

CopyToClipboardButton.propTypes = {
  value: PropTypes.string,
  screenReaderLabel: PropTypes.string
}

CopyToClipboardButton.defaultProps = {
  screenReaderLabel: I18n.t('Copy')
}
