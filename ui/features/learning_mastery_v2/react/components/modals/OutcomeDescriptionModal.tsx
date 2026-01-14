/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import useLMGBContext from '@canvas/outcomes/react/hooks/useLMGBContext'
import {Link} from '@instructure/ui-link'
import {Outcome} from '../../types/rollup'
import OutcomeContextTag from '@canvas/outcome-context-tag'

const I18n = createI18nScope('OutcomeDescriptionModal')

export interface OutcomeDescriptionModalProps {
  outcome: Outcome
  isOpen: boolean
  onCloseHandler: () => void
}

const getCalculationMethod = (outcome: Outcome): string => {
  switch (outcome.calculation_method) {
    case 'decaying_average':
      return I18n.t('Weighted Average')
    case 'standard_decaying_average':
      return I18n.t('Decaying Average')
    case 'n_mastery':
      return I18n.t('Number of Times')
    case 'highest':
      return I18n.t('Highest')
    case 'latest':
      return I18n.t('Most Recent Score')
    default:
      return I18n.t('Average')
  }
}

const NoDisplayNameAndDescriptionsHelpMessage = ({
  contextURL,
}: {
  contextURL: string | undefined
}) => (
  <>
    <View display="block" width="100%" padding="0 0 x-small 0" data-testid="outcome-empty-title">
      <Text weight="bold">{I18n.t('There is no description for this outcome.')}</Text>
    </View>
    <View display="block" width="100%" data-testid="outcome-empty-description">
      <Text>
        {I18n.t('To edit the name, description, or friendly description of an outcome, open the')}
        &nbsp;
        {contextURL == undefined ? (
          <Text>{I18n.t('Outcomes')}</Text>
        ) : (
          <Link href={contextURL + '/outcomes'}>{I18n.t('Outcomes')}</Link>
        )}
        &nbsp;{I18n.t('view, locate the outcome, and click the')}&nbsp;
        <b>{I18n.t('Edit')}</b>
        &nbsp;{I18n.t('button.')}
      </Text>
    </View>
  </>
)

const OutcomeModalBody = ({
  outcome,
  outcomesFriendlyDescriptionFF,
  calculationMethod,
  contextURL,
}: {
  outcome: Outcome
  outcomesFriendlyDescriptionFF: boolean
  calculationMethod: string
  contextURL: string | undefined
}) => (
  <>
    {outcome.display_name && (
      <View display="block" width="100%" margin="0 0 medium 0" data-testid="outcome-display-name">
        <Text wrap="break-word" size="large">
          {outcome.display_name}
        </Text>
      </View>
    )}
    {outcomesFriendlyDescriptionFF && outcome.friendly_description && (
      <View
        display="block"
        width="100%"
        padding="x-small"
        margin="small none medium none"
        background="secondary"
        data-testid="outcome-friendly-description"
      >
        <View display="block" width="100%" padding="xx-small x-small x-small x-small">
          <Text weight="bold">{I18n.t('Friendly Description')}</Text>
        </View>
        <View display="block" width="100%" padding="0 x-small xx-small x-small">
          <Text>{outcome.friendly_description}</Text>
        </View>
      </View>
    )}

    {outcome.description && (
      <View
        display="block"
        margin="small none"
        width="100%"
        data-testid="outcome-description"
        dangerouslySetInnerHTML={{__html: outcome.description ?? ''}}
      />
    )}

    {!outcome.description && !outcome.friendly_description && !outcome.display_name && (
      <NoDisplayNameAndDescriptionsHelpMessage contextURL={contextURL} />
    )}

    <Flex direction="row" margin="large none none none" gap="x-large">
      <View>
        <View as="div">
          <Text weight="bold">{I18n.t('Calculation Method')}</Text>
        </View>
        <Flex gap="x-small" alignItems="center">
          <Text>{calculationMethod}</Text>
          <OutcomeContextTag
            outcomeContextType={outcome.context_type}
            outcomeContextId={outcome.context_id}
          />
        </Flex>
      </View>
      <View>
        <View as="div">
          <Text weight="bold">{I18n.t('Mastery Scale')}</Text>
        </View>
        <Text>
          {I18n.t('%{points_possible} Point', {points_possible: outcome.points_possible})}
        </Text>
      </View>
    </Flex>
  </>
)

export const OutcomeDescriptionModal: React.FC<OutcomeDescriptionModalProps> = ({
  outcome,
  isOpen,
  onCloseHandler,
}) => {
  const {outcomesFriendlyDescriptionFF, contextURL} = useLMGBContext()
  const calculationMethod = getCalculationMethod(outcome)

  return (
    <Modal
      size="medium"
      open={isOpen}
      onDismiss={onCloseHandler}
      shouldReturnFocus={true}
      shouldCloseOnDocumentClick={false}
      overflow="scroll"
      label={I18n.t('%{outcomeTitle}', {outcomeTitle: outcome.title})}
      data-testid="outcome-description-modal"
    >
      <Modal.Body>
        <OutcomeModalBody
          outcome={outcome}
          outcomesFriendlyDescriptionFF={outcomesFriendlyDescriptionFF ?? false}
          calculationMethod={calculationMethod}
          contextURL={contextURL}
        />
      </Modal.Body>
    </Modal>
  )
}
