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

import {render} from '@testing-library/react'
import CommentRow from '../CommentsTray/CommentRow'

const getMockProps = () => ({
  comment: {
    attachments: [],
    __typename: 'SubmissionComment',
    _id: '23',
    author: {
      __typename: 'User',
      avatarUrl: null,
      shortName: 'Test Student',
    },
    htmlComment: '',
    mediaObject: {
      __typename: 'MediaObject',
      id: 'Tbg==',
      _id: 'm-2Jk1n',
      mediaSources: [
        {
          __typename: 'MediaSource',
          height: '480',
          src: 'http://notorious-web.inseng.test/fMw.mp4',
          type: 'video/mp4',
          width: '1166',
        },
        {
          __typename: 'MediaSource',
          height: '360',
          src: 'http://notorious-web.inseng.test/Q0ZA.mp4',
          type: 'video/mp4',
          width: '874',
        },
      ],
      mediaTracks: [],
      mediaType: null,
      title: 'recording.mov',
    },
    read: true,
    updatedAt: '2025-03-26T07:02:26-06:00',
  },
})

describe('CommentRow', () => {
  beforeEach(() => {
    global.ENV = {current_user: {id: '1'}}
    global.ENV.FEATURES = {}
    global.ENV.FEATURES.consolidated_media_player = false
  })

  it('should render', () => {
    const props = getMockProps()
    render(<CommentRow {...props} />)
  })

  it('should use studio player when consolidated_media_player is enabled', () => {
    global.ENV.FEATURES.consolidated_media_player = true
    const props = getMockProps()
    const {queryByTestId} = render(<CommentRow {...props} />)
    expect(queryByTestId('canvas-studio-player')).toBeInTheDocument()
  })

  it('should use media player when consolidated_media_player is disabled', () => {
    const props = getMockProps()
    const {queryByTestId, container} = render(<CommentRow {...props} />)
    expect(queryByTestId('canvas-studio-player')).not.toBeInTheDocument()
    expect(container.querySelector('video')).toBeInTheDocument()
  })
})
