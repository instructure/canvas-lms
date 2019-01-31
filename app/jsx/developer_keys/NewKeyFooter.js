/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import I18n from 'i18n!react_developer_keys'
import PropTypes from 'prop-types'
import React from 'react'

import Button from '@instructure/ui-buttons/lib/components/Button'
import {ModalFooter} from '@instructure/ui-overlays/lib/components/Modal'

const NewKeyFooter = props => {
  return (
    <ModalFooter>
      <Button onClick={props.onCancelClick} margin="0 small 0 0">{I18n.t('Cancel')}</Button>
      <Button onClick={props.onSaveClick} variant="primary" disabled={props.disable}>
        {I18n.t('Save Key')}
      </Button>
    </ModalFooter>
  )
}

NewKeyFooter.propTypes = {
  onCancelClick: PropTypes.func.isRequired,
  onSaveClick: PropTypes.func.isRequired,
  disable: PropTypes.bool
}

export default NewKeyFooter
