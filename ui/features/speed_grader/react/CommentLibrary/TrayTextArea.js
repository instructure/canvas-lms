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

import React, {useState, useEffect, useRef} from 'react'
import PropTypes from 'prop-types'
import {View} from '@instructure/ui-view'
import {TextArea} from '@instructure/ui-text-area'
import {Button} from '@instructure/ui-buttons'
import {IconAddLine} from '@instructure/ui-icons'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('CommentLibrary')

const TrayTextArea = ({onAdd, isAdding}) => {
  const [text, setText] = useState('')
  const textInputRef = useRef()
  useEffect(() => {
    if (!isAdding) {
      if (text !== '') {
        setText('')
        textInputRef.current.focus()
      }
    }
  }, [isAdding]) // eslint-disable-line react-hooks/exhaustive-deps

  return (
    <>
      <TextArea
        textareaRef={el => (textInputRef.current = el)}
        value={text}
        onChange={e => setText(e.target.value)}
        placeholder={I18n.t('Write something...')}
        label={I18n.t('Add comment to library')}
        resize="vertical"
        data-testid="comment-library-text-area"
      />
      <View as="div" textAlign="end" padding="small 0 small small">
        <Button
          color="primary"
          onClick={() => onAdd(text)}
          interaction={text.length > 0 && !isAdding ? 'enabled' : 'disabled'}
          renderIcon={isAdding ? '' : IconAddLine}
          data-testid="add-to-library-button"
        >
          {isAdding ? I18n.t('Adding to Library') : I18n.t('Add to Library')}
        </Button>
      </View>
    </>
  )
}

TrayTextArea.propTypes = {
  onAdd: PropTypes.func.isRequired,
  isAdding: PropTypes.bool.isRequired,
}

export default TrayTextArea
