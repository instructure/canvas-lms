/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {useScope as createI18nScope} from '@canvas/i18n'
import React from 'react'
import {CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Tooltip} from '@instructure/ui-tooltip'
import {TruncateText} from '@instructure/ui-truncate-text'
import {NutritionFacts} from '@instructure/platform-nutrition-facts'
import {useAiFeatureInfo} from '../../../hooks/useAiFeatureInfo'
import {Grid, GridArea} from '../../Grid'

const I18n = createI18nScope('accessibility_checker')
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

interface WizardProps {
  title: string
  onDismiss: () => void
  headingRef?: (el: Element | null) => void
}

export const WizardHeader: React.FC<WizardProps> = ({title, onDismiss, headingRef}) => {
  const [isHeaderTruncated, setIsHeaderTruncated] = React.useState(false)
  const getFeatureInfo = useAiFeatureInfo()

  // DOM order: title | close (button) | nutrition-facts
  // Visual order: title | nutrition-facts | . (spacer) | close (button)
  const templateColumns = getFeatureInfo
    ? 'minmax(0, auto) auto 1fr auto'
    : 'minmax(0, auto) 1fr auto'
  const templateAreas = getFeatureInfo ? '"title nutrition-facts . close"' : '"title . close"'

  return (
    <Grid
      key={getFeatureInfo ? 'with-ai' : 'without-ai'}
      templateColumns={templateColumns}
      templateAreas={templateAreas}
      rowGap="0"
      alignItems="center"
    >
      <GridArea area="title">
        <Tooltip on={isHeaderTruncated ? ['hover'] : []} placement="start center" renderTip={title}>
          <Heading level="h2" variant="titleCardRegular" elementRef={headingRef} tabIndex={-1}>
            <TruncateText onUpdate={isTruncated => setIsHeaderTruncated(isTruncated)}>
              {title}
            </TruncateText>
          </Heading>
        </Tooltip>
      </GridArea>
      <GridArea area="close">
        <CloseButton
          data-testid="wizard-close-button"
          onClick={onDismiss}
          size="small"
          screenReaderLabel={I18n.t('Close')}
        />
      </GridArea>
      {getFeatureInfo && (
        <GridArea
          area="nutrition-facts"
          additionalStyles={{
            height: '0',
            overflow: 'visible',
            display: 'flex',
            alignItems: 'center',
          }}
        >
          <NutritionFacts
            aiInformation={getFeatureInfo.aiInformation.data}
            dataPermissionLevels={getFeatureInfo.dataPermissionLevels.data}
            nutritionFacts={getFeatureInfo.nutritionFacts}
            translations={nutritionFactsTranslations()}
            iconSize={18}
            fullscreenModals={false}
            color="primary"
            buttonColor="primary"
            withBackground={false}
          />
        </GridArea>
      )}
    </Grid>
  )
}
