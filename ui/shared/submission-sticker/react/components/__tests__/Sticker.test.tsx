/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {render, fireEvent} from '@testing-library/react'
import Sticker from '../Sticker'
import type {StickerProps} from '../../types/stickers.d'

const renderComponent = (props: StickerProps) => {
  return render(<Sticker {...props} />)
}

describe('Sticker', () => {
  let props: StickerProps

  beforeEach(() => {
    props = {confetti: false, size: 'medium', submission: {sticker: 'grad'}}
  })

  it('renders an image', () => {
    const {getByRole} = renderComponent(props)
    expect(
      getByRole('img', {name: 'A sticker with a picture of a graduation cap.'})
    ).toBeInTheDocument()
  })

  it('does not render a button', () => {
    const {queryByRole} = renderComponent(props)
    expect(
      queryByRole('button', {name: 'A sticker with a picture of a graduation cap.'})
    ).not.toBeInTheDocument()
  })

  describe('when confetti is enabled', () => {
    beforeEach(() => {
      props.confetti = true
    })

    it('renders a button', () => {
      const {getByRole} = renderComponent(props)
      expect(
        getByRole('button', {name: 'A sticker with a picture of a graduation cap.'})
      ).toBeInTheDocument()
    })

    it('shows confetti when the button is clicked', () => {
      const {getByRole, getByTestId} = renderComponent(props)
      const button = getByRole('button', {name: 'A sticker with a picture of a graduation cap.'})
      fireEvent.click(button)
      expect(getByTestId('confetti-canvas')).toBeInTheDocument()
    })

    it('does not show confetti when the button has not been clicked', () => {
      const {queryByTestId} = renderComponent(props)
      expect(queryByTestId('confetti-canvas')).not.toBeInTheDocument()
    })
  })
})
