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
import gql from 'graphql-tag'

export const UPDATE_INTERNAL_SETTING_MUTATION = gql`
  mutation UpdateInternalSetting($internalSettingId: ID!, $value: String!) {
    updateInternalSetting(input: {internalSettingId: $internalSettingId, value: $value}) {
      internalSetting {
        id
        value
        secret
      }
      errors {
        message
      }
    }
  }
`

export const DELETE_INTERNAL_SETTING_MUTATION = gql`
  mutation DeleteInternalSetting($internalSettingId: ID!) {
    deleteInternalSetting(input: {internalSettingId: $internalSettingId}) {
      internalSettingId
      errors {
        message
      }
    }
  }
`

export const CREATE_INTERNAL_SETTING_MUTATION = gql`
  mutation CreateInternalSetting($name: String!, $value: String!) {
    createInternalSetting(input: {name: $name, value: $value}) {
      internalSetting {
        id
        value
        secret
      }
      errors {
        message
      }
    }
  }
`
