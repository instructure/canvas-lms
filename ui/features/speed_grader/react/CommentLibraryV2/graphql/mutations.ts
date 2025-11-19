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

import {gql} from '@apollo/client'

export const SpeedGraderLegacy_CreateCommentBankItem = gql`
  mutation SpeedGraderLegacy_CreateCommentBankItem($courseId: ID!, $comment: String!) {
    createCommentBankItem(input: { courseId: $courseId, comment: $comment }) {
      commentBankItem {
        id: _id
        comment
      }
      errors {
        attribute
        message
      }
    }
  }
`

export const SpeedGraderLegacy_DeleteCommentBankItem = gql`
  mutation SpeedGraderLegacy_DeleteCommentBankItem($id: ID!) {
    deleteCommentBankItem(input: {id: $id}) {
      commentBankItemId
      errors {
        attribute
        message
      }
    }
  }
`

export const SpeedGraderLegacy_UpdateCommentBankItem = gql`
  mutation SpeedGraderLegacy_UpdateCommentBankItem($id: ID!, $comment: String!) {
    updateCommentBankItem(input: {id: $id, comment: $comment}) {
      commentBankItem {
        id: _id
        comment
      }
      errors {
        attribute
        message
      }
    }
  }
`
