/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {IconButton} from '@instructure/ui-buttons'
import {IconArrowOpenDownLine} from '@instructure/ui-icons'
import {Menu} from '@instructure/ui-menu'
import {View} from '@instructure/ui-view'
import {TruncateText} from '@instructure/ui-truncate-text'
import useModal from '@canvas/outcomes/react/hooks/useModal'
import {useScope as useI18nScope} from '@canvas/i18n'
import {CELL_HEIGHT, COLUMN_WIDTH} from './constants'
import {outcomeShape} from './shapes'
import OutcomeDescriptionModal from './OutcomeDescriptionModal'

const I18n = useI18nScope('learning_mastery_gradebook')

const OutcomeHeader = ({outcome}) => {
  // OD => OutcomeDescription
  const [isODModalOpen, openODModal, closeODModal] = useModal()

  return (
    <>
      <View background="secondary" as="div" width={COLUMN_WIDTH} borderWidth="large 0 medium 0">
        <Flex alignItems="center" justifyItems="space-between" height={CELL_HEIGHT}>
          <Flex.Item size="80%" padding="0 0 0 small">
            <TruncateText>
              <Text weight="bold">{outcome.title}</Text>
            </TruncateText>
          </Flex.Item>
          <Flex.Item padding="0 small 0 0">
            <Menu
              placement="bottom"
              trigger={
                <IconButton
                  withBorder={false}
                  withBackground={false}
                  size="small"
                  screenReaderLabel={I18n.t('Sort Outcome Column')}
                >
                  <IconArrowOpenDownLine />
                </IconButton>
              }
            >
              <Menu.Group label={I18n.t('Sort By')}>
                <Menu.Item defaultSelected={true}>{I18n.t('Default')}</Menu.Item>
                <Menu.Item>{I18n.t('Ascending')}</Menu.Item>
                <Menu.Item>{I18n.t('Descending')}</Menu.Item>
              </Menu.Group>
              <Menu.Separator />
              <Menu.Item>{I18n.t('Show Contributing Scores')}</Menu.Item>
              <Menu.Item onClick={openODModal}>{I18n.t('Outcome Description')}</Menu.Item>
            </Menu>
          </Flex.Item>
        </Flex>
      </View>
      <OutcomeDescriptionModal
        outcome={outcome}
        isOpen={isODModalOpen}
        onCloseHandler={closeODModal}
      />
    </>
  )
}

OutcomeHeader.propTypes = {
  outcome: PropTypes.shape(outcomeShape).isRequired,
}

export default OutcomeHeader
