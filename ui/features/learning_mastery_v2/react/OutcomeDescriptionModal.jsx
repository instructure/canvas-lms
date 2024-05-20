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
import PropTypes from 'prop-types'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import {useScope as useI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {outcomeShape} from './shapes'
import useLMGBContext from '@canvas/outcomes/react/hooks/useLMGBContext'
import {Link} from '@instructure/ui-link'
import {Pill} from '@instructure/ui-pill'

const I18n = useI18nScope('OutcomeDescriptionModal')

const getCalculationMethod = outcome => {
  const calc_int = outcome.calculation_int
  const other_int = 100 - calc_int

  switch (outcome.calculation_method) {
    case 'decaying_average':
      return I18n.t('%{calc_int}/%{other_int} Weighted Average', {calc_int, other_int})
    case 'standard_decaying_average':
      return I18n.t('%{calc_int}/%{other_int} Decaying Average', {calc_int, other_int})
    case 'n_mastery':
      return I18n.t('Number of Times (%{calc_int})', {calc_int})
    case 'highest':
      return I18n.t('Highest')
    case 'latest':
      return I18n.t('Most Recent Score')
    default:
      return I18n.t('Average')
  }
}

const OutcomeDescriptionModal = ({outcome, isOpen, onCloseHandler}) => {
  const {outcomesFriendlyDescriptionFF, contextURL} = useLMGBContext()

  const missingDisplayName = outcome.display_name === ''
  const missingDescription = outcome.description === ''
  const missingFriendlyDescription =
    outcome.friendly_description === null || outcome.friendly_description === ''
  const calculationMethod = getCalculationMethod(outcome)
  const shouldDisplayEmptyModal =
    missingDisplayName && missingDescription && missingFriendlyDescription

  return (
    <Modal
      size="small"
      open={isOpen}
      onDismiss={onCloseHandler}
      shouldReturnFocus={true}
      shouldCloseOnDocumentClick={false}
      overflow="scroll"
      label={I18n.t('%{outcomeTitle}', {outcomeTitle: outcome.title})}
      data-testid="outcome-description-modal"
    >
      <Modal.Body>
        {!shouldDisplayEmptyModal && (
          <>
            <View
              display="block"
              width="100%"
              padding="0 0 medium 0"
              data-testid="outcome-display-name"
            >
              <Text wrap="break-word" size="x-large" weight="bold">
                {outcome.display_name}
              </Text>
            </View>
            <Pill data-testid="calculation-method">{calculationMethod}</Pill>
            {outcomesFriendlyDescriptionFF && !missingFriendlyDescription && (
              <View
                display="block"
                width="100%"
                padding="x-small"
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
            <View
              display="block"
              width="100%"
              padding="small 0 small 0"
              data-testid="outcome-description"
              dangerouslySetInnerHTML={{__html: outcome.description}}
            />
          </>
        )}
        {shouldDisplayEmptyModal && (
          <>
            <View
              display="block"
              width="100%"
              padding="0 0 x-small 0"
              data-testid="outcome-empty-title"
            >
              <Text weight="bold">{I18n.t('There is no description for this outcome.')}</Text>
            </View>
            <View
              display="block"
              width="100%"
              height="300px"
              data-testid="outcome-empty-description"
            >
              <Text>
                {I18n.t(
                  'To edit the name, description, or friendly description of an outcome, open the'
                )}
                &nbsp;
                <Link href={contextURL + '/outcomes'}>{I18n.t('Outcomes')}</Link>
                &nbsp;{I18n.t('view, locate the outcome, and click the')}&nbsp;
                <b>{I18n.t('Edit')}</b>
                &nbsp;{I18n.t('button.')}
              </Text>
            </View>
          </>
        )}
      </Modal.Body>
    </Modal>
  )
}

OutcomeDescriptionModal.propTypes = {
  outcome: PropTypes.shape(outcomeShape).isRequired,
  isOpen: PropTypes.bool.isRequired,
  onCloseHandler: PropTypes.func.isRequired,
}

export default OutcomeDescriptionModal
