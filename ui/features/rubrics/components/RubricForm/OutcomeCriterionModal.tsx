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
import {useScope as useI18nScope} from '@canvas/i18n'
import type {RubricCriterion} from '@canvas/rubrics/react/types/rubric'
import {CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Table} from '@instructure/ui-table'
import {possibleString} from '@canvas/rubrics/react/Points'

const I18n = useI18nScope('rubrics-criterion-modal')

export type OutcomeCriterionModalProps = {
  criterion?: RubricCriterion
  isOpen: boolean
  onDismiss: () => void
}
export const OutcomeCriterionModal = ({
  criterion,
  isOpen,
  onDismiss,
}: OutcomeCriterionModalProps) => {
  const {ratings: existingRatings = []} = criterion ?? {}

  return (
    <Modal
      open={isOpen}
      onDismiss={onDismiss}
      width="66.5rem"
      height="45.125rem"
      label={I18n.t('Rubric Outcome Criterion Modal')}
      shouldCloseOnDocumentClick={false}
      data-testid="outcome-rubric-criterion-modal"
    >
      <Modal.Header>
        <CloseButton placement="end" offset="small" onClick={onDismiss} screenReaderLabel="Close" />
        <Heading>{I18n.t('View Outcome')}</Heading>
      </Modal.Header>
      <Modal.Body>
        <View as="div" margin="0" display="flex">
          <View as="span" margin="0 0 0 small" themeOverride={{marginSmall: '0.75rem'}}>
            <View as="div">
              <Text weight="bold">{I18n.t('Criterion Name')}</Text>
            </View>
            <View as="div">
              <Text data-testid="outcome-title">{criterion?.outcome?.title}</Text>
            </View>
          </View>
          <View as="span" margin="0 xx-large 0 auto" themeOverride={{marginSmall: '0.75rem'}}>
            <View as="div">
              <Text weight="bold">{I18n.t('Friendly Name')}</Text>
            </View>
            <View as="div">
              <Text data-testid="outcome-friendly-name">{criterion?.outcome?.displayName}</Text>
            </View>
          </View>
        </View>
        <View as="div" margin="small 0 0 0" display="flex">
          <View as="span" margin="0 0 0 small" themeOverride={{marginSmall: '0.75rem'}}>
            <View as="div">
              <Text weight="bold">{I18n.t('Description')}</Text>
            </View>
            <View as="div">
              <Text data-testid="outcome-description">{criterion?.description}</Text>
            </View>
          </View>
        </View>
        <View as="div" margin="small 0 0 small">
          <Text data-testid="outcome-mastery-points">
            {I18n.t('Threshold: %{threshold}', {
              threshold: possibleString(criterion?.masteryPoints),
            })}
          </Text>
        </View>
        <View as="div" margin="medium 0 0 0" display="flex">
          <Table caption={I18n.t('Outcome Criterion Edit')}>
            <Table.Head>
              <Table.Row>
                <Table.ColHeader id="Display" textAlign="center">
                  {I18n.t('Display')}
                </Table.ColHeader>
                <Table.ColHeader id="Title">{I18n.t('Points')}</Table.ColHeader>
                <Table.ColHeader id="Year">{I18n.t('Rating Name')}</Table.ColHeader>
              </Table.Row>
            </Table.Head>
            <Table.Body>
              {existingRatings.map((rating, index) => {
                const scale = existingRatings.length - (index + 1)
                return (
                  <Table.Row key={rating.id}>
                    <Table.RowHeader textAlign="center">{scale}</Table.RowHeader>
                    <Table.Cell data-testid="outcome-rating-points" textAlign="center">
                      {rating.points}
                    </Table.Cell>
                    <Table.Cell data-testid="outcome-rating-description">
                      {rating.description}
                    </Table.Cell>
                  </Table.Row>
                )
              })}
            </Table.Body>
          </Table>
        </View>
      </Modal.Body>
    </Modal>
  )
}
