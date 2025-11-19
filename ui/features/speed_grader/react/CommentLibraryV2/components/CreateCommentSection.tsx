/* eslint-disable react/prop-types */
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

import {useMutation} from '@apollo/client'
import {Button} from '@instructure/ui-buttons'
import {IconAddLine} from '@instructure/ui-icons'
import {TextArea} from '@instructure/ui-text-area'
import {View} from '@instructure/ui-view'
import {useRef, useState} from 'react'
import {SpeedGraderLegacy_CreateCommentBankItem} from '../graphql/mutations'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'
import {SpeedGraderLegacy_CreateCommentBankItemMutation} from '@canvas/graphql/codegen/graphql'

const I18n = createI18nScope('CommentLibrary')

type CreateCommentSectionProps = {
  courseId: string
}

export const CreateCommentSection: React.FC<CreateCommentSectionProps> = ({courseId}) => {
  const textInputRef = useRef<HTMLTextAreaElement | null>()
  const [value, setValue] = useState('')

  const [createComment, {loading}] = useMutation<SpeedGraderLegacy_CreateCommentBankItemMutation>(
    SpeedGraderLegacy_CreateCommentBankItem,
    {
      refetchQueries: [
        'SpeedGraderLegacy_CommentBankItems',
        'SpeedGraderLegacy_CommentBankItemsCount',
      ],
    },
  )

  const handleAddComment = async () => {
    try {
      await createComment({variables: {courseId, comment: value}})
      showFlashAlert({message: I18n.t('Comment added'), type: 'success'})
      setValue('')
      textInputRef?.current?.focus()
    } catch {
      showFlashAlert({message: I18n.t('Failed to add comment'), type: 'error'})
    }
  }

  return (
    <>
      <TextArea
        textareaRef={el => {
          textInputRef.current = el
        }}
        value={value}
        onChange={e => setValue(e.target.value)}
        placeholder={I18n.t('Write something...')}
        label={I18n.t('Add comment to library')}
        resize="vertical"
        data-testid="create-comment-library-item-textarea"
      />
      <View as="div" textAlign="end" padding="small 0 small small">
        <Button
          color="primary"
          onClick={handleAddComment}
          interaction={value.length > 0 && !loading ? 'enabled' : 'disabled'}
          renderIcon={!loading && <IconAddLine />}
          data-testid="add-to-library-button"
        >
          {loading ? I18n.t('Adding to Library') : I18n.t('Add to Library')}
        </Button>
      </View>
    </>
  )
}
