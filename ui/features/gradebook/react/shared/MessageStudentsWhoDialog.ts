/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import '@canvas/message-students-dialog/jquery/message_students'
import messageStudentsWhoHelper from '@canvas/grading/messageStudentsWhoHelper'

const MessageStudentsWhoDialog = {
  // @ts-expect-error
  show({assignment, students}, onClose) {
    const settings = messageStudentsWhoHelper.settings(assignment, students)
    settings.onClose = onClose
    // @ts-expect-error
    window.messageStudents(settings)
  },
}

export default MessageStudentsWhoDialog
