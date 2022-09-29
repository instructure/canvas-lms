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
import {shape, string} from 'prop-types'

export const MediaTrack = {
  fragment: gql`
    fragment MediaTrack on MediaTrack {
      _id
      content
      locale
      kind
    }
  `,

  shape: shape({
    _id: string,
    content: string,
    locale: string,
    kind: string,
  }),

  mock: ({
    _id = '101',
    content = '1\r\n00:00:00,000 --> 00:00:02,000\r\nMy first video\r\n',
    locale = 'en',
    kind = 'subtitles',
  } = {}) => ({
    _id,
    content,
    locale,
    kind,
    __typename: 'MediaTrack',
  }),
}
