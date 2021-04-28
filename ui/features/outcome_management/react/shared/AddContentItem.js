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
import I18n from 'i18n!AddGroup'
import {TextInput} from '@instructure/ui-text-input'
import {Link} from '@instructure/ui-link'
import {IconButton} from '@instructure/ui-buttons'
import {IconXSolid, IconCheckSolid, IconPlusLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {View} from '@instructure/ui-view'

const AddContentItem = ({labelInstructions, textInputInstructions, showIcon, onSaveHandler}) => {
  const [title, setTitle] = useState('')
  const [expanded, setExpanded] = useState(false)

  const titleChangeHandler = (_event, value) => {
    setTitle(value)
  }

  const cleanUp = () => {
    setExpanded(false)
    setTitle(null)
  }

  const onSave = () => {
    onSaveHandler(title)
    cleanUp()
  }

  const show = e => {
    e.stopPropagation()
    setExpanded(true)
  }

  const hide = e => {
    e.stopPropagation()
    cleanUp()
  }

  return (
    <View as="div">
      {expanded ? (
        <View as="div" padding="xx-small">
          <TextInput
            renderLabel={<ScreenReaderContent>{textInputInstructions}</ScreenReaderContent>}
            placeholder={textInputInstructions}
            display="inline-block"
            width="12rem"
            onChange={titleChangeHandler}
          />
          <IconButton
            screenReaderLabel={I18n.t('Cancel')}
            display="inline-block"
            margin="0 0 0 small"
            onClick={e => hide(e)}
          >
            <IconXSolid />
          </IconButton>
          <IconButton
            screenReaderLabel={labelInstructions}
            interaction={title ? 'enabled' : 'disabled'}
            margin="0 0 0 small"
            display="inline-block"
            onClick={onSave}
          >
            <IconCheckSolid />
          </IconButton>
        </View>
      ) : (
        <View as="div">
          <Link
            isWithinText={false}
            renderIcon={showIcon ? <IconPlusLine size="x-small" /> : ''}
            onClick={e => show(e)}
            size="x-small"
          >
            {labelInstructions}
          </Link>
        </View>
      )}
    </View>
  )
}

AddContentItem.propTypes = {
  labelInstructions: PropTypes.string.isRequired,
  textInputInstructions: PropTypes.string.isRequired,
  showIcon: PropTypes.bool.isRequired,
  onSaveHandler: PropTypes.func.isRequired
}

export default AddContentItem
