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

import React from 'react'
import {AiInformation} from '@instructure/ui-instructure'
import {IconButton} from '@instructure/ui-buttons'
import {STATIC_TEXT} from './constants'
import {NutritionFactsIcon} from './NutritionFactsIcon'
import {useScope as createI18nScope} from '@canvas/i18n'
import {NutritionFactsProps} from './types'

const I18n = createI18nScope('nutrition_facts')

export const NutritionFacts: React.FC<NutritionFactsProps> = ({
  aiInformation,
  dataPermissionLevels,
  nutritionFacts,
  iconSize,
}) => {
  return (
    <AiInformation
      fullscreenModals={false}
      trigger={
        <IconButton
          id="nutrition_facts_trigger"
          screenReaderLabel={I18n.t('Nutrition facts')}
          margin={'none'}
          withBackground={false}
          withBorder={false}
          shape="circle"
        >
          <NutritionFactsIcon size={iconSize} />
        </IconButton>
      }
      {...STATIC_TEXT}
      data={aiInformation.data}
      dataPermissionLevelsData={dataPermissionLevels.data}
      nutritionFactsData={nutritionFacts.data}
      dataPermissionLevelsCurrentFeature={nutritionFacts.featureName}
      nutritionFactsFeatureName={nutritionFacts.featureName}
    />
  )
}
