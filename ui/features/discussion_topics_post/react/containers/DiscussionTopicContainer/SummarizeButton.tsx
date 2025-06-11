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

import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import {IconAiColoredSolid, IconXSolid} from '@instructure/ui-icons'

interface SummarizeButtonProps {
  onClick: () => Promise<void>
  isEnabled: boolean
  isLoading: boolean
  isMobile: boolean
}

const I18n = createI18nScope('discussions_posts')

export const SummarizeButton: React.FC<SummarizeButtonProps> = ({
  isEnabled,
  isLoading,
  isMobile,
  onClick,
}) => {
  const handleClick = () => {
    if (!isLoading) {
      onClick()
    }
  }

  return (
    <Button
      onClick={handleClick}
      color={isEnabled ? 'secondary' : 'ai-secondary'}
      renderIcon={isEnabled ? <IconXSolid /> : <IconAiColoredSolid />}
      data-testid="summarize-button"
      display={isMobile ? 'block' : 'inline-block'}
    >
      {isEnabled ? I18n.t('Close Summary') : I18n.t('Open Summary')}
    </Button>
  )
}
