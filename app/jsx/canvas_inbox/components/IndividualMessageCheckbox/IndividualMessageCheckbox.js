/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {Checkbox} from '@instructure/ui-checkbox'
import I18n from 'i18n!conversations_2'

export const IndividualMessageCheckbox = props => {
  return (
    <Checkbox
      data-testid="individual-message-checkbox"
      label={I18n.t('Send an individual message to each recipient')}
      size="small"
      {...props}
    />
  )
}

IndividualMessageCheckbox.propTypes = {
  onChange: PropTypes.func.isRequired,
  checked: PropTypes.bool
}

IndividualMessageCheckbox.defaultProps = {
  checked: false
}
