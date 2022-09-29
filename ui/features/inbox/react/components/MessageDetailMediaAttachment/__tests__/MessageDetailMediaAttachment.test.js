/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {fireEvent, render} from '@testing-library/react'
import {MediaComment} from '../../../../graphql/MediaComment'
import {MessageDetailMediaAttachment} from '../MessageDetailMediaAttachment'
import React from 'react'

jest.mock('@instructure/ui-media-player', () => ({
  MediaPlayer: () => <div />,
}))

describe('MessageDetailMediaAttachment', () => {
  it('renders the media attachment title as a toggle button', () => {
    const container = render(<MessageDetailMediaAttachment mediaComment={MediaComment.mock()} />)
    expect(container.getByText('uploaded-movie.mov')).toBeInTheDocument()
  })

  it('Opens the media player when expanded', async () => {
    const container = render(<MessageDetailMediaAttachment mediaComment={MediaComment.mock()} />)
    expect(container.queryByTestId('media-player')).not.toBeInTheDocument()
    const mediaAttachment = container.getByText('uploaded-movie.mov')
    fireEvent.click(mediaAttachment)
    expect(await container.findByTestId('media-player')).toBeInTheDocument()
  })
})
