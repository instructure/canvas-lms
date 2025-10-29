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
import {IconButton} from '@instructure/ui-buttons'
import {IconTrashLine} from '@instructure/ui-icons'
import {SpeedGraderLegacy_DeleteCommentBankItem} from '../graphql/mutations'
import {useScope as createI18nScope} from '@canvas/i18n'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {SpeedGraderLegacy_DeleteCommentBankItemMutation} from '@canvas/graphql/codegen/graphql'

const I18n = createI18nScope('CommentLibrary')

type DeleteCommentIconButtonProps = {
  id: string
  comment: string
  index: number
}
const DeleteCommentIconButton: React.FC<DeleteCommentIconButtonProps> = ({id, comment, index}) => {
  const [deleteCommentBankItem, {loading}] =
    useMutation<SpeedGraderLegacy_DeleteCommentBankItemMutation>(
      SpeedGraderLegacy_DeleteCommentBankItem,
      {
        refetchQueries: [
          'SpeedGraderLegacy_CommentBankItems',
          'SpeedGraderLegacy_CommentBankItemsCount',
        ],
      },
    )

  const handleDeleteCommentBankItem = async () => {
    try {
      await deleteCommentBankItem({variables: {id}})
      showFlashAlert({message: I18n.t('Comment deleted'), type: 'success'})
    } catch {
      showFlashAlert({message: I18n.t('Error deleting comment'), type: 'error'})
    }
  }

  return (
    <IconButton
      disabled={loading}
      screenReaderLabel={I18n.t('Delete comment: {{comment}}', {
        comment,
      })}
      renderIcon={IconTrashLine}
      onClick={() => {
        // TODO: do this with dialog
        // This uses window.confirm due to poor focus
        // behavior caused by using a Tray with a
        // Modal.
        const confirmed = window.confirm(I18n.t('Are you sure you want to delete this comment?'))
        if (confirmed) handleDeleteCommentBankItem()
      }}
      withBackground={false}
      withBorder={false}
      size="small"
      data-testid={`comment-library-delete-button-${index}`}
    />
  )
}

export default DeleteCommentIconButton
