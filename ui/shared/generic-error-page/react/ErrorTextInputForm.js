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
import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import {TextArea} from '@instructure/ui-text-area'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'
import {Button} from '@instructure/ui-buttons'
import {func, string} from 'prop-types'

const I18n = useI18nScope('generic_error_page')

export default function ErrorTextInputForm(props) {
  const submitButtonState = props.email.length === 0 ? 'disabled' : 'enabled'
  return (
    <View margin="small">
      <TextArea
        onChange={props.handleChangeCommentBox}
        label={I18n.t('What happened?')}
        value={props.textAreaComment}
      />
      <View margin="small">
        <TextInput
          onChange={props.handleChangeEmail}
          renderLabel={I18n.t('Your Email Address')}
          isRequired={true}
          placeholder={I18n.t('email@example.com')}
          value={props.email}
        />
      </View>
      <View textAlign="end" display="block">
        <Button
          margin="small 0"
          color="primary"
          interaction={submitButtonState}
          onClick={props.handleSubmitErrorReport}
        >
          {I18n.t('Submit')}
        </Button>
      </View>
    </View>
  )
}

ErrorTextInputForm.propTypes = {
  textAreaComment: string.isRequired,
  email: string.isRequired,
  handleChangeCommentBox: func.isRequired,
  handleSubmitErrorReport: func.isRequired,
  handleChangeEmail: func.isRequired,
}
