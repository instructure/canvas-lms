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

import React, {useEffect} from 'react'
import {useField} from 'react-final-form'
import PropTypes from 'prop-types'
import {TextArea} from '@instructure/ui-text-area'
import useRCE from '../../../features/outcome_management/react/hooks/useRCE'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

const LabeledRceField = ({name, validate, ...props}) => {
  const {
    input,
    meta: {touched, error, submitError}
  } = useField(name, {
    validate,
    beforeSubmit: () => {
      input.onChange(getCode())
    }
  })

  // eslint-disable-next-line no-unused-vars
  const [textareaRef, getCode, setCode, code] = useRCE()

  useEffect(() => {
    if (code !== null) {
      input.onChange(code)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [code])

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

  return (
    <>
      <TextArea textareaRef={textareaRef} {...props} defaultValue={input.value} />
      {errorMessages.length > 0 && (
        <View as="div" margin="0 0 small">
          {errorMessages.map(err => (
            <Text key={err} color="error">
              {err}
            </Text>
          ))}
        </View>
      )}
    </>
  )
}

LabeledRceField.propTypes = {
  name: PropTypes.string.isRequired,
  validate: PropTypes.func
}

export default LabeledRceField
