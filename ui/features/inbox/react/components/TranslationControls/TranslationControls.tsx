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

import {Flex} from '@instructure/ui-flex'
import {Checkbox} from '@instructure/ui-checkbox'

import {useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import TranslationOptions from './TranslationOptions'
import useTranslationDisplay from '../../hooks/useTranslationDisplay'
import {NutritionFacts} from '@instructure/platform-nutrition-facts'
import {AiInfo} from '@instructure.ai/aiinfo'

declare const ENV: Global & {
  inbox_translation_enabled?: boolean
}

const I18n = createI18nScope('conversations_2')
const NF_I18n = createI18nScope('nutrition_facts')

const nutritionFactsTranslations = () => ({
  title: '',
  triggerScreenReaderLabel: NF_I18n.t('Nutrition facts'),
  dataPermissionLevelsTitle: NF_I18n.t('Data Permission Levels'),
  dataPermissionLevelsCurrentFeatureText: NF_I18n.t('Current Feature:'),
  dataPermissionLevelsCloseIconButtonScreenReaderLabel: NF_I18n.t('Close'),
  dataPermissionLevelsCloseButtonText: NF_I18n.t('Close'),
  dataPermissionLevelsModalLabel: NF_I18n.t('This is a Data Permission Levels modal'),
  nutritionFactsModalLabel: NF_I18n.t('This is a modal for AI facts'),
  nutritionFactsTitle: NF_I18n.t('Nutrition Facts'),
  nutritionFactsCloseButtonText: NF_I18n.t('Close'),
  nutritionFactsCloseIconButtonScreenReaderLabel: NF_I18n.t('Close'),
})

interface TranslationControlsProps {
  inboxSettingsFeature: boolean
  signature: string
}

export interface Language {
  id: string
  name: string
}

const TranslationControls = (props: TranslationControlsProps) => {
  const [includeTranslation, setIncludeTranslation] = useState(false)

  const {handleIsPrimaryChange, primary} = useTranslationDisplay({
    signature: props.signature,
    inboxSettingsFeature: props.inboxSettingsFeature,
    includeTranslation,
  })

  const inboxTranslationInfo = AiInfo.canvasinboxtranslation
  const showNutritionFacts = ENV?.inbox_translation_enabled && inboxTranslationInfo

  return (
    <>
      <Flex alignItems="center" padding="small small small" gap="small">
        <Flex.Item>
          <Checkbox
            label={I18n.t('Include translated version of this message')}
            value="medium"
            variant="toggle"
            checked={includeTranslation}
            onChange={() => setIncludeTranslation(!includeTranslation)}
          />
        </Flex.Item>
        {showNutritionFacts && (
          <Flex.Item>
            <NutritionFacts
              aiInformation={inboxTranslationInfo.aiInformation.data}
              dataPermissionLevels={inboxTranslationInfo.dataPermissionLevels.data}
              nutritionFacts={inboxTranslationInfo.nutritionFacts}
              translations={nutritionFactsTranslations()}
              iconSize={24}
              fullscreenModals={false}
              color="primary"
              buttonColor="primary"
              withBackground={false}
            />
          </Flex.Item>
        )}
      </Flex>
      {includeTranslation && (
        <TranslationOptions asPrimary={primary} onSetPrimary={handleIsPrimaryChange} />
      )}
    </>
  )
}

export default TranslationControls
