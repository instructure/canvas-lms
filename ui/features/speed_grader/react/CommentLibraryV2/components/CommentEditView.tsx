/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {TextArea} from '@instructure/ui-text-area'
import {View} from '@instructure/ui-view'
import {useEffect, useRef, useState} from 'react'
import {SpeedGraderLegacy_UpdateCommentBankItem} from '../graphql/mutations'
import {useMutation} from '@apollo/client'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'
import {SpeedGraderLegacy_UpdateCommentBankItemMutation} from '@canvas/graphql/codegen/graphql'

const I18n = createI18nScope('CommentLibrary')

export type CommentEditViewProps = {
  id: string
  initialValue: string
  onClose: () => void
}

// eslint-disable-next-line react/prop-types
const CommentEditView: React.FC<CommentEditViewProps> = ({id, initialValue, onClose}) => {
  const textAreaRef = useRef<HTMLTextAreaElement | null>(null)
  const [value, setValue] = useState(initialValue)

  const [updateCommentBankItem, {loading}] =
    useMutation<SpeedGraderLegacy_UpdateCommentBankItemMutation>(
      SpeedGraderLegacy_UpdateCommentBankItem,
      {
        refetchQueries: [
          'SpeedGraderLegacy_CommentBankItems',
          'SpeedGraderLegacy_CommentBankItemsCount',
        ],
      },
    )

  const handleUpdateCommentBankItem = async () => {
    try {
      await updateCommentBankItem({variables: {id, comment: value}})
      showFlashAlert({message: I18n.t('Comment updated'), type: 'success'})
      onClose()
    } catch {
      showFlashAlert({message: I18n.t('Error updating comment'), type: 'error'})
    }
  }

  // Autofocus if one Comment component switches to edit mode
  useEffect(() => {
    textAreaRef?.current?.focus()
  }, [])

  const allowSave = !loading && value.length > 0 && value !== initialValue

  return (
    <View
      as="div"
      position="relative"
      borderWidth="none none small none"
      padding="small small 0 small"
    >
      <TextArea
        textareaRef={el => {
          textAreaRef.current = el
        }}
        value={value}
        onChange={e => setValue(e.target.value)}
        placeholder={I18n.t('Write something...')}
        label={<ScreenReaderContent>{I18n.t('Edit comment')}</ScreenReaderContent>}
        resize="vertical"
        data-testid="comment-library-edit-textarea"
      />
      <Flex justifyItems="end">
        <Flex.Item margin="xxx-small 0 0 xxx-small">
          <Button
            size="small"
            margin="small"
            onClick={onClose}
            data-testid="comment-library-edit-cancel-button"
          >
            {I18n.t('Cancel')}
          </Button>
        </Flex.Item>
        <Flex.Item margin="xxx-small 0 0 xxx-small">
          <Button
            size="small"
            color="primary"
            onClick={handleUpdateCommentBankItem}
            interaction={allowSave ? 'enabled' : 'disabled'}
            data-testid="comment-library-edit-save-button"
          >
            {I18n.t('Save')}
          </Button>
        </Flex.Item>
      </Flex>
    </View>
  )
}

export default CommentEditView
