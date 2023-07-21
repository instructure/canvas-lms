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
import {useScope as useI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import {outcomeGroupShape} from './shapes'

const I18n = useI18nScope('OutcomeManagement')

const GroupDescriptionModal = ({outcomeGroup, isOpen, onCloseHandler}) => (
  <Modal
    size="small"
    label={outcomeGroup.title}
    open={isOpen}
    onDismiss={onCloseHandler}
    shouldReturnFocus={true}
  >
    <Modal.Body>
      <View as="div" padding="small 0" maxHeight="330px" tabIndex="0">
        <Text size="medium" weight="bold">
          {I18n.t('Description')}
        </Text>
        <View
          as="div"
          padding="small 0"
          dangerouslySetInnerHTML={{__html: outcomeGroup.description}}
        />
      </View>
    </Modal.Body>
    <Modal.Footer>
      <Button type="button" color="primary" margin="0 x-small 0 0" onClick={onCloseHandler}>
        {I18n.t('Done')}
      </Button>
    </Modal.Footer>
  </Modal>
)

GroupDescriptionModal.propTypes = {
  outcomeGroup: outcomeGroupShape.isRequired,
  isOpen: PropTypes.bool.isRequired,
  onCloseHandler: PropTypes.func.isRequired,
}

export default GroupDescriptionModal
