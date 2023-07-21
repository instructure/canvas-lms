/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import axios from '@canvas/axios'

const I18n = useI18nScope('new_user_tutorial')

const API_URL = '/api/v1/users/self/features/flags/new_user_tutorial_on_off'

export default function ConfirmEndTutorialDialog({isOpen, handleRequestClose}) {
  return (
    <Modal
      open={isOpen}
      size="small"
      onDismiss={handleRequestClose}
      label={I18n.t('End Course Set-up Tutorial')}
    >
      <Modal.Body>
        {I18n.t(
          'Turning off this tutorial will remove the tutorial tray from your view for all of your courses. It can be turned back on under Feature Options in your User Settings.'
        )}
      </Modal.Body>
      <Modal.Footer>
        <Button onClick={handleRequestClose}>{I18n.t('Cancel')}</Button>
        &nbsp;
        <Button
          onClick={() =>
            axios.put(API_URL, {state: 'off'}).then(() => ConfirmEndTutorialDialog.onSuccess())
          }
          color="primary"
        >
          {I18n.t('Okay')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}
ConfirmEndTutorialDialog.onSuccess = () => window.location.reload()

ConfirmEndTutorialDialog.propTypes = {
  isOpen: PropTypes.bool,
  handleRequestClose: PropTypes.func.isRequired,
}

ConfirmEndTutorialDialog.defaultProps = {
  isOpen: false,
}
