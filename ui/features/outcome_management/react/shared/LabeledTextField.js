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
import {useField} from 'react-final-form'
import {TextInput} from '@instructure/ui-text-input'
import PropTypes from 'prop-types'

const LabeledTextField = ({name, validate, Component = TextInput, ...props}) => {
  const {
    input,
    meta: {touched, error, submitError}
  } = useField(name, {
    validate
  })

  let errorMessages = []
  if (touched) {
    if (Array.isArray(error)) {
      errorMessages = error
    } else {
      const err = error || submitError
      if (err) {
        errorMessages = [err]
      }
    }
  }

  errorMessages = errorMessages.map(text => ({
    text,
    type: 'error'
  }))

  return <Component {...input} messages={errorMessages} {...props} />
}

LabeledTextField.propTypes = {
  name: PropTypes.string.isRequired,
  validate: PropTypes.func,
  Component: PropTypes.elementType
}

export default LabeledTextField
