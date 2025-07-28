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

import React from 'react'
import { render, screen } from '@testing-library/react'
import ProductCard from '../ProductCard'
import type { OrganizationProduct } from '../../../models/Product' 
import { product } from '../../common/__tests__/data'

// Mock the productRoute function
jest.mock('../../../utils/routes', () => ({
  productRoute: jest.fn((id) => `/product/${id}`),
}))

const mockOrganizationProduct: OrganizationProduct = {
  ...product[0],
  organization_tool: {
    product_status: {
      id: 1,
      name: 'Active',
      color: '#00FF00',
      description: 'This product is active',
    },
    privacy_status: {
      id: 0,
      name: 'Not Approved',
      color: '#808080',
      description: 'This product is not approved',
    }
  },
}

describe('ProductCard', () => {
  it('renders the product card correctly', () => {
    render(<ProductCard product={product[0]} />)

    // Check if key elements are rendered
    expect(screen.getByText('Product 1')).toBeInTheDocument()
    expect(screen.getByText('Product 1 tagline')).toBeInTheDocument()
    expect(screen.getByText('Instructure')).toBeInTheDocument()
    expect(screen.getByText('tag1')).toBeInTheDocument()

    // Check if the logo is rendered
    const logo = screen.getByRole('img')
    expect(logo).toHaveAttribute('src', 'logourl.com')
  })

  it('renders organization tool and privacy status when present', () => {
    render(<ProductCard product={mockOrganizationProduct} />)

    expect(screen.getByText('Active')).toBeInTheDocument()
  })

  it('does not render organization tool status when not present', () => {
    render(<ProductCard product={product[0]} />)

    expect(screen.queryByText('Active')).not.toBeInTheDocument()
  })
})