// @ts-nocheck
/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import React from 'react'
import {fireEvent, render} from '@testing-library/react'
import {MediaAttachment} from '../MediaAttachment'

jest.mock('@canvas/canvas-media-player', () => () => <div>Media Content</div>)

describe('MediaAttachment', () => {
  let props

  beforeEach(() => {
    props = {
      file: {mediaID: '123', title: 'my-awesome-video.mp4', src: 'somesrc.test', type: 'video'},
      onRemoveMediaComment: jest.fn(),
    }
  })

  it('does not show the remove button by default', () => {
    const {queryByRole} = render(<MediaAttachment {...props} />)
    expect(queryByRole('button', {name: 'Remove media comment'})).not.toBeInTheDocument()
  })

  it('shows the remove button when the element is hovered', () => {
    const {getByTestId, getByRole} = render(<MediaAttachment {...props} />)
    fireEvent.mouseOver(getByTestId('removable-item'))
    expect(getByRole('button', {name: 'Remove media comment'})).toBeInTheDocument()
  })

  it('does not show the remove button when there onRemoveMediaComment is not defined', () => {
    const mediaProps = {...props, onRemoveMediaComment: undefined}
    const {queryByTestId} = render(<MediaAttachment {...mediaProps} />)
    expect(queryByTestId('removable-item')).not.toBeInTheDocument()
  })

  it('calls onRemoveMediaComment when the button is clicked', () => {
    const {getByTestId, getByRole} = render(<MediaAttachment {...props} />)
    fireEvent.mouseOver(getByTestId('removable-item'))
    const button = getByRole('button', {name: 'Remove media comment'})
    fireEvent.click(button)
    expect(props.onRemoveMediaComment).toHaveBeenCalledTimes(1)
  })

  it('displays the media title', () => {
    const {getByText} = render(<MediaAttachment {...props} />)
    expect(getByText(props.file.title)).toBeInTheDocument()
  })
})
