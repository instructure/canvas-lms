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
import {useScope as usei18NScope} from '@canvas/i18n'

const I18N = usei18NScope('disucssion_create')

export default function DiscussionTopicForm({submitForm}) {
  const validateForm = () => {
    return true
  }

  const handleSubmit = shouldPublish => {
    if (validateForm()) {
      submitForm({title: 'Example discussion', message: '<p>Lorem ipsum</p>', shouldPublish})
      return true
    }
    return false
  }

  return (
    <>
      <button type="button" onClick={_ => handleSubmit(true)}>
        {I18N.t('Submit')}
      </button>
    </>
  )
}

DiscussionTopicForm.propTypes = {
  submitForm: PropTypes.func,
}

DiscussionTopicForm.defaultProps = {
  submitForm: () => {},
}
