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

import React from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import PropTypes from 'prop-types'

const I18n = useI18nScope('external_tools')

const ConfirmationForm = props => {
  const {cancelLabel, confirmLabel, onCancel, onConfirm, message} = props

  return (
    <View display="block">
      <View display="block">
        <Text className="confirmation-message" size="large">
          {message}
        </Text>
      </View>
      <View display="block" margin="small 0 0 0">
        <Button onClick={onCancel} margin="0 x-small 0 0">
          {cancelLabel}
        </Button>
        <Button onClick={onConfirm} color="primary">
          {confirmLabel}
        </Button>
      </View>
    </View>
  )
}

ConfirmationForm.propTypes = {
  onCancel: PropTypes.func.isRequired,
  onConfirm: PropTypes.func.isRequired,
  message: PropTypes.string.isRequired,
  confirmLabel: PropTypes.string,
  cancelLabel: PropTypes.string,
}

ConfirmationForm.defaultProps = {
  confirmLabel: I18n.t('Submit'),
  cancelLabel: I18n.t('Cancel'),
}

export default ConfirmationForm
