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

import React, {useState} from 'react'
import PropTypes from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import {TextInput} from '@instructure/ui-text-input'
import {IconButton} from '@instructure/ui-buttons'
import {IconXSolid, IconCheckSolid} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {View} from '@instructure/ui-view'
import Focus from '@canvas/outcomes/react/Focus'

const I18n = useI18nScope('AddGroup')

const AddContentItem = ({
  labelInstructions,
  textInputInstructions,
  onSaveHandler,
  onHideHandler,
}) => {
  const [title, setTitle] = useState('')

  const titleChangeHandler = (e, value) => {
    setTitle(value)
    e.stopPropagation()
  }

  const save = () => {
    onSaveHandler(title)
  }

  const hide = e => {
    onHideHandler(e)
  }

  return (
    <View as="div" padding="xx-small">
      <Focus>
        <TextInput
          renderLabel={<ScreenReaderContent>{textInputInstructions}</ScreenReaderContent>}
          placeholder={textInputInstructions}
          display="inline-block"
          width="12rem"
          onChange={titleChangeHandler}
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
        interaction={title.trim().length > 0 ? 'enabled' : 'disabled'}
        margin="0 0 0 small"
        display="inline-block"
        onClick={save}
        data-testid="outcomes-management-add-content-item"
      >
        <IconCheckSolid />
      </IconButton>
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
