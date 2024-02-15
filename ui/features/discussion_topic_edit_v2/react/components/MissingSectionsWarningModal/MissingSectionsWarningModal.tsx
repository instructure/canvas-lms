// @ts-nocheck
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
import {Modal} from '@instructure/ui-modal'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {List} from '@instructure/ui-list'
import {IconWarningLine} from '@instructure/ui-icons'
import {Flex} from '@instructure/ui-flex'

const I18n = useI18nScope('discussion_create')

type Section = {
  id: string
  name: string
  end_at: string | null
  override_course_and_term_dates: boolean | null
  start_at: string | null
}

type Props = {
  sections: Section[]
  onClose: () => void
  onContinue: () => void
}

export const MissingSectionsWarningModal = ({sections, onClose, onContinue}: Props) => {
  const renderCloseButton = () => {
    return <CloseButton onClick={onClose} screenReaderLabel={I18n.t('Close')} />
  }
  return (
    <Modal
      as="form"
      open={true}
      onDismiss={onClose}
      label={I18n.t('Missing Sections Warning')}
      shouldCloseOnDocumentClick={true}
    >
      <Modal.Header>
        <Flex>
          <Flex.Item margin="0 x-small 0 0">
            <Text size="large">
              <IconWarningLine />
            </Text>
          </Flex.Item>
          <Flex.Item shouldGrow={true}>
            <Heading>{I18n.t('Warning')}</Heading>
          </Flex.Item>
          <Flex.Item>{renderCloseButton()}</Flex.Item>
        </Flex>
      </Modal.Header>
      <Modal.Body padding="small">
        <p>
          <Text>{I18n.t('Not all sections will be assigned this item.')}</Text>
        </p>
        <Text>{I18n.t('Would you like to go back to include:')}</Text>
        <List margin="0 0 medium">
          {sections.map(section => (
            <List.Item key={section.id}>
              <Text weight="bold">{section.name}</Text>
            </List.Item>
          ))}
        </List>
      </Modal.Body>
      <Modal.Footer>
        <Button onClick={onClose} margin="0 x-small 0 0" data-testid="go-back-button">
          {I18n.t('Go Back')}
        </Button>
        <Button onClick={onContinue} color="primary" type="submit" data-testid="continue-button">
          {I18n.t('Continue')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}
