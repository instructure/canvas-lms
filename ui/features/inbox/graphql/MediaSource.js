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

export const MediaSource = {
  fragment: gql`
    fragment MediaSource on MediaSource {
      contentType
      url
      bitrate
      fileExt
      height
      isOriginal
      size
      width
    }
  `,

  shape: shape({
    contentType: string,
    url: string,
    bitrate: string,
    fileExt: string,
    height: string,
    isOriginal: string,
    size: string,
    width: string
  }),

  mock: ({
    contentType = 'video/mp4',
    url = 'https://nv.instructuremedia.com/fetch/QkFoYkIxc0hhUVRndjZZU01Hd3JCOUd4WEdBPS0tNTU1MTlhMTMyOGI0MTFkMjVjNzkwNmEwZDYzOWJkYzVjM2U0OTBlZQ.mp4',
    bitrate = '1515981',
    fileExt = 'mp4',
    height = '720',
    isOriginal = '0',
    size = '360',
    width = '1280'
  } = {}) => ({
    contentType,
    url,
    bitrate,
    fileExt,
    height,
    isOriginal,
    size,
    width,
    __typename: 'MediaSource'
  })
}

export const DefaultMocks = {
  MediaSource: () => ({
    contentType: 'video/mp4',
    bitrate: '558995',
    filext: 'mp4',
    height: '360',
    width: '640',
    size: '199'
  })
}
