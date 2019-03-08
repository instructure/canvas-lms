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
import I18n from 'i18n!generic_error_page'
import React from 'react'
import {TextArea, TextInput} from '@instructure/ui-forms'
import View from '@instructure/ui-layout/lib/components/View'
import {Button} from '@instructure/ui-buttons'
import {func} from 'prop-types'
import {Flex, FlexItem} from '@instructure/ui-layout'

function ErrorTextInputForm(props) {
  return (
    <View>
      <TextArea
        margin="small"
        onChange={props.handleChangeCommentBox}
        label={I18n.t('What happened?')}
      />
      <View>
        <TextInput
          display="block"
          onChange={props.handleChangeOptionalEmail}
          label={I18n.t('Email Address (Optional)')}
        />
      </View>
      <Flex justifyItems="end">
        <FlexItem>
          <Button margin="small 0" variant="primary" onClick={props.handleSubmitErrorReport}>
            {I18n.t('Submit')}
          </Button>
        </FlexItem>
      </Flex>
    </View>
  )
}

ErrorTextInputForm.propTypes = {
  handleChangeCommentBox: func.isRequired,
  handleSubmitErrorReport: func.isRequired,
  handleChangeOptionalEmail: func.isRequired
}

export default React.memo(ErrorTextInputForm)
