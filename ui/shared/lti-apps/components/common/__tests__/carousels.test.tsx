/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import '@testing-library/jest-dom/extend-expect'
import ProductCarousel from '../Carousels/ProductCarousel'
import ImageCarousel from '../Carousels/ImageCarousel'
import {product, company} from './data'

beforeAll(() => {
  Object.defineProperty(window, 'matchMedia', {
    writable: true,
    value: jest.fn().mockImplementation(query => ({
      matches: false,
      media: query,
      onchange: null,
      addListener: jest.fn(), // deprecated
      removeListener: jest.fn(), // deprecated
      addEventListener: jest.fn(),
      removeEventListener: jest.fn(),
      dispatchEvent: jest.fn(),
    })),
  })
})

describe('Carousels render as expected', () => {
  const originalLocation = window.location

  afterEach(() => {
    Object.defineProperty(window, 'location', {
      writable: true,
      value: originalLocation,
    })
  })

  it('ProductCarousel renders as expected', () => {
    const testPath = 'ipsum/lorem/12/dolor'

    Object.defineProperty(window, 'location', {
      writable: true,
      value: {...originalLocation, pathname: testPath},
    })

    const {getByText} = render(<ProductCarousel products={product} companyName={company.name} />)
    expect(getByText('Product 1')).toBeInTheDocument()
  })

  it('ImageCarousel renders as expected', () => {
    render(<ImageCarousel screenshots={product[0].screenshots} />)

    const displayedImage = document.querySelector('img') as HTMLImageElement
    expect(displayedImage.src).toContain('greatimage')
  })
})
