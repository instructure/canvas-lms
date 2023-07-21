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

import React, {useState} from 'react'
import PropTypes from 'prop-types'
import {View} from '@instructure/ui-view'
import {TextInput} from '@instructure/ui-text-input'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {Button} from '@instructure/ui-buttons'
import {useScope as usei18NScope} from '@canvas/i18n'

const I18N = usei18NScope('discussion_create')

export default function DiscussionTopicForm({onSubmit}) {
  const [title, setTitle] = useState('')
  const [titleValidationMessages, setTitleValidationMessages] = useState([
    {text: '', type: 'success'},
  ])

  const validateTitle = newTitle => {
    if (newTitle.length > 255) {
      setTitleValidationMessages([{text: 'Title must be less than 255 characters.', type: 'error'}])
      return false
    } else if (newTitle.length === 0) {
      setTitleValidationMessages([{text: 'Title must not be empty.', type: 'error'}])
      return false
    } else {
      setTitleValidationMessages([{text: '', type: 'success'}])
      return true
    }
  }

  const validateFormFields = () => {
    // Will add more conditions in future tickets
    return validateTitle(title)
  }

  const submitForm = shouldPublish => {
    if (validateFormFields()) {
      onSubmit({title, message: '<p>Lorem ipsum</p>', shouldPublish})
      return true
    }
    return false
  }

  return (
    <>
      <FormFieldGroup description="" rowSpacing="small">
        <TextInput
          renderLabel={I18N.t('Topic Title')}
          type={I18N.t('text')}
          placeholder={I18N.t('Topic Title')}
          value={title}
          onChange={(_, value) => {
            validateTitle(value)
            const newTitle = value.substring(0, 255)
            setTitle(newTitle)
          }}
          messages={titleValidationMessages}
        />
        <View display="block" textAlign="end">
          <Button type="button" color="secondary">
            {I18N.t('Cancel')}
          </Button>
          <Button
            type="submit"
            onClick={() => submitForm(true)}
            color="secondary"
            margin="xxx-small"
          >
            {I18N.t('Save and Publish')}
          </Button>
          <Button type="submit" onClick={() => submitForm(false)} color="primary">
            {I18N.t('Save')}
          </Button>
        </View>
      </FormFieldGroup>
    </>
  )
}

DiscussionTopicForm.propTypes = {
  onSubmit: PropTypes.func,
}

DiscussionTopicForm.defaultProps = {
  onSubmit: () => {},
}
