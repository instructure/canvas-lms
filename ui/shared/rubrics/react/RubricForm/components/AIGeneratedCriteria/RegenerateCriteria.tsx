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
import {CanvasModal} from '@instructure/platform-instui-bindings'
import {canvasErrorComponent} from '@canvas/error-page-utils'
import {Text} from '@instructure/ui-text'
import {TextArea} from '@instructure/ui-text-area'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Tooltip} from '@instructure/ui-tooltip'

const I18n = createI18nScope('rubrics-criteria-row')

type RegenerateCriteriaProps = {
  buttonColor: 'ai-primary' | 'ai-secondary'
  disabled?: boolean
  isCriterion?: boolean
  toolTipText?: string
  onRegenerate: (additionalPrompt: string) => void
}

const RegenerateCriteria = ({
  buttonColor,
  disabled = false,
  isCriterion = false,
  toolTipText = '',
  onRegenerate,
}: RegenerateCriteriaProps) => {
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
      <CanvasModal
        padding="medium"
        open={isOpen}
        onDismiss={onClose}
        size="medium"
        label={isCriterion ? I18n.t('Regenerate Criterion') : I18n.t('Regenerate Criteria')}
        shouldCloseOnDocumentClick={false}
        closeButtonLabel={I18n.t('Close')}
        errorComponent={canvasErrorComponent()}
        footer={
          <Flex direction="row" gap="small" padding="small">
            <Button onClick={onClose} data-testid="regenerate-criteria-cancel-button">
              {I18n.t('Cancel')}
            </Button>
            <Button
              color="ai-primary"
              onClick={handleRegenerate}
              renderIcon={<IconAiSolid />}
              data-testid="regenerate-criteria-submit-button"
              disabled={additionalPrompt.length > 1000}
            >
              {I18n.t('Regenerate')}
            </Button>
          </Flex>
        }
      >
        <View data-testid="regenerate-criteria-modal-description">
          <Text>
            {isCriterion
              ? I18n.t(
                  `Please provide more information about how you would like to regenerate the criterion.`,
                )
              : I18n.t(
                  `Please provide more information about how you would like to regenerate the criteria.`,
                )}
          </Text>
          <TextArea
            label={I18n.t('Additional Prompt Information')}
            rows={4}
            margin="small 0 0 0"
            data-testid="additional-prompt-textarea"
            value={additionalPrompt}
            placeholder={I18n.t(
              'Enter additional prompt information here. For example, "Target a college-level seminar." or "Focus on argument substance." or "Be lenient." ',
            )}
            onChange={e => setAdditionalPrompt(e.target.value)}
            messages={
              additionalPrompt.length > 1000
                ? [
                    {
                      text: I18n.t(
                        'Additional prompt information must be less than 1000 characters',
                      ),
                      type: 'error',
                    },
                  ]
                : undefined
            }
          />
        </View>
      </CanvasModal>
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

export default RegenerateCriteria
