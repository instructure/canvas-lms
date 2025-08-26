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
import CanvasModal from '@canvas/instui-bindings/react/Modal'
import {Text} from '@instructure/ui-text'
import {TextArea} from '@instructure/ui-text-area'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('rubrics-criteria-row')

type RegenerateCriteriaProps = {
  buttonColor: 'ai-primary' | 'ai-secondary'
  disabled?: boolean
  isCriterion?: boolean
  onRegenerate: (additionalPrompt: string) => void
}

const RegenerateCriteria = ({
  buttonColor,
  disabled = false,
  isCriterion = false,
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
        footer={
          <Flex direction="row" gap="small" padding="small">
            <Button onClick={onClose}>{I18n.t('Cancel')}</Button>
            <Button color="ai-primary" onClick={handleRegenerate} renderIcon={<IconAiSolid />}>
              {I18n.t('Regenerate')}
            </Button>
          </Flex>
        }
      >
        <View>
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
          />
        </View>
      </CanvasModal>
      <Button
        onClick={() => setIsOpen(true)}
        data-testid="generate-criteria-button"
        color={buttonColor}
        renderIcon={buttonColor === 'ai-primary' ? <IconAiSolid /> : <IconAiColoredSolid />}
        disabled={disabled}
      >
        {I18n.t('Regenerate')}
      </Button>
    </>
  )
}

export default RegenerateCriteria
