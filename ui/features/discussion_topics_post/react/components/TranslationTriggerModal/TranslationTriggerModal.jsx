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

import {Modal} from '@instructure/ui-modal'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {useScope as createI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'

export const TranslationTriggerModal = ({
  isModalOpen,
  closeModal,
  closeModalAndKeepTranslations,
  closeModalAndRemoveTranslations,
  isAnnouncement,
}) => {
  const I18n = createI18nScope('discussions_posts')

  const description = isAnnouncement
    ? I18n.t('Closing this module will also remove the translated announcement')
    : I18n.t('Closing this module will also remove the translated discussion')

  return (
    <Modal label={I18n.t('Close translation')} open={isModalOpen} size="medium">
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={closeModal}
          screenReaderLabel="Close"
          data-testid="translations-modal-close-button"
        />
        <Heading>{I18n.t('Are you sure you want to close?')}</Heading>
      </Modal.Header>
      <Modal.Body>
        <Text>{description}</Text>
      </Modal.Body>
      <Modal.Footer>
        <Flex gap="small">
          <Flex.Item>
            <Button onClick={closeModal}> {I18n.t('Cancel')}</Button>
          </Flex.Item>
          <Flex.Item>
            <Button onClick={closeModalAndKeepTranslations}>
              {' '}
              {I18n.t('Close and Keep Translations')}
            </Button>
          </Flex.Item>
          <Flex.Item>
            <Button onClick={closeModalAndRemoveTranslations} color="primary">
              {' '}
              {I18n.t('Close and Remove Translations')}
            </Button>
          </Flex.Item>
        </Flex>
      </Modal.Footer>
    </Modal>
  )
}

TranslationTriggerModal.propTypes = {
  closeModal: PropTypes.func,
  closeModalAndKeepTranslations: PropTypes.func,
  closeModalAndRemoveTranslations: PropTypes.func,
  isModalOpen: PropTypes.bool,
}
