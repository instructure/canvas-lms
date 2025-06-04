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

import React, {useState, useRef} from 'react'
import PropTypes from 'prop-types'
import {useScope as createI18nScope} from '@canvas/i18n'
import {TextInput} from '@instructure/ui-text-input'
import {IconButton} from '@instructure/ui-buttons'
import {IconXSolid, IconCheckSolid} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import Focus from '@canvas/outcomes/react/Focus'

const I18n = createI18nScope('AddGroup')

const validateTitle = title => {
  const MAX_TITLE_LENGTH = 255
  if (!title || title.trim().length <= 0)
    return [{type: 'newError', text: I18n.t('Cannot be blank')}]
  if (title.trim().length > MAX_TITLE_LENGTH)
    return [{type: 'newError', text: I18n.t('Must be 255 characters or less')}]
  return []
}

const AddContentItem = ({
  labelInstructions,
  textInputInstructions,
  onSaveHandler,
  onHideHandler,
}) => {
  const [title, setTitle] = useState('')
  const titleRef = useRef(null)
  const [errorMessages, setErrorMessages] = useState([])

  const titleChangeHandler = (event, value) => {
    setTitle(value)
    setErrorMessages(validateTitle(value))
    event?.stopPropagation()
  }

  const save = () => {
    if (errorMessages.length > 0) {
      titleRef.current?.focus()
      return
    }
    onSaveHandler(title)
  }

  const hide = e => {
    onHideHandler(e)
  }

  return (
    <View as="div" padding="xx-small" onFocus={e => e.stopPropagation()}>
      <Flex alignItems="start">
        <Focus>
          <TextInput
            elementRef={ref => (titleRef.current = ref)}
            renderLabel={<ScreenReaderContent>{textInputInstructions}</ScreenReaderContent>}
            placeholder={textInputInstructions}
            display="inline-block"
            width="14rem"
            onChange={titleChangeHandler}
            onBlur={event => titleChangeHandler(event, title)}
            messages={errorMessages}
          />
        </Focus>
        <IconButton
          screenReaderLabel={I18n.t('Cancel')}
          display="inline-block"
          margin="0 0 0 small"
          onClick={hide}
        >
          <IconXSolid />
        </IconButton>
        <IconButton
          screenReaderLabel={labelInstructions}
          margin="0 0 0 small"
          display="inline-block"
          onClick={save}
          data-testid="outcomes-management-add-content-item"
        >
          <IconCheckSolid />
        </IconButton>
      </Flex>
    </View>
  )
}

AddContentItem.propTypes = {
  labelInstructions: PropTypes.string.isRequired,
  textInputInstructions: PropTypes.string.isRequired,
  onSaveHandler: PropTypes.func.isRequired,
  onHideHandler: PropTypes.func.isRequired,
}

export default AddContentItem
