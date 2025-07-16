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
import {RESTORE_DELETED_DISCUSSION_ENTRY} from '../../graphql/Mutations'

const useRestoreEntry = (updateLoadedSubentry: (entry: any) => void) => {
  const restoreEntry = async (discussionEntryId: string) => {
    const {data} = await update({variables: {discussionEntryId}})

    if (!data.restoreDeletedDiscussionEntry.error) {
      updateLoadedSubentry(data.restoreDeletedDiscussionEntry.discussionEntry)
    }
  }

  const [update, {loading}] = useMutation(RESTORE_DELETED_DISCUSSION_ENTRY)

  return {
    restoreEntry,
    loading,
  }
}

export default useRestoreEntry
