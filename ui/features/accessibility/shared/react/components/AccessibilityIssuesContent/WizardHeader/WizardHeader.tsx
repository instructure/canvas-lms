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
import {NutritionFacts} from '@canvas/nutrition-facts/react/NutritionFacts'
import {useAiFeatureInfo} from '../../../hooks/useAiFeatureInfo'
import {Grid, GridArea} from '../../Grid'

const I18n = createI18nScope('accessibility_checker')

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
            aiInformation={getFeatureInfo.aiInformation}
            dataPermissionLevels={getFeatureInfo.dataPermissionLevels}
            nutritionFacts={getFeatureInfo.nutritionFacts}
            iconSize={18}
            responsiveProps={{
              fullscreenModals: false,
              color: 'primary',
              buttonColor: 'primary',
              withBackground: false,
              domElement: 'inbox_nutrition_facts_container',
            }}
          />
        </GridArea>
      )}
    </Grid>
  )
}
