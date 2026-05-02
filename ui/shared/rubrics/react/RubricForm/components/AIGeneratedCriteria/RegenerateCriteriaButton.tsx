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

import {useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {IconAiColoredSolid, IconAiSolid} from '@instructure/ui-icons'
import {Button} from '@instructure/ui-buttons'
import {Tooltip} from '@instructure/ui-tooltip'
import RegenerateCriteriaModal from './RegenerateCriteriaModal'

const I18n = createI18nScope('rubrics-criteria-row')

type RegenerateCriteriaButtonProps = {
  buttonColor: 'ai-primary' | 'ai-secondary'
  disabled?: boolean
  isCriterion?: boolean
  toolTipText?: string
  onRegenerate: (additionalPrompt: string) => void
}

const RegenerateCriteriaButton = ({
  buttonColor,
  disabled = false,
  isCriterion = false,
  toolTipText = '',
  onRegenerate,
}: RegenerateCriteriaButtonProps) => {
  const [isOpen, setIsOpen] = useState(false)
  const [additionalPrompt, setAdditionalPrompt] = useState('')

  const onClose = () => {
    setIsOpen(false)
    setAdditionalPrompt('')
  }

  const handleRegenerate = () => {
    onRegenerate(additionalPrompt)
    onClose()
  }

  return (
    <>
      <RegenerateCriteriaModal
        open={isOpen}
        isCriterion={isCriterion}
        additionalPrompt={additionalPrompt}
        onClose={onClose}
        onRegenerate={handleRegenerate}
        onAdditionalPromptChange={setAdditionalPrompt}
      />
      <Tooltip
        renderTip={toolTipText}
        data-testid="regenerate-criteria-tooltip"
        preventTooltip={!disabled || toolTipText === ''}
      >
        <Button
          onClick={() => setIsOpen(true)}
          data-testid="regenerate-criteria-button"
          color={buttonColor}
          renderIcon={buttonColor === 'ai-primary' ? <IconAiSolid /> : <IconAiColoredSolid />}
          disabled={disabled}
        >
          {I18n.t('Regenerate')}
        </Button>
      </Tooltip>
    </>
  )
}

export default RegenerateCriteriaButton
