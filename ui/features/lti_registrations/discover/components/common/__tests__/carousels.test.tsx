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
import BadgeCarousel from '../Carousels/BadgeCarousel'
import ImageCarousel from '../Carousels/ImageCarousel'

import type {Product, Company, LtiDetail, Lti, Badges, Tag} from '../../../model/Product'

const company: Company = {
  id: 2,
  name: 'Instructure',
  company_url: 'google.com',
}

const lti_configurations: LtiDetail = {
  lti_13: {services: ['gk'], placements: ['dr']},
  lti_11: {services: ['gk'], placements: ['dr']},
}

const tool_integration_configurations: Lti = {
  lti_13: [{id: 3, integration_type: 'dr', url: 'google.com', unified_tool_id: '5'}],
  lti_11: [{id: 4, integration_type: 'gk', url: 'google.com', unified_tool_id: '6'}],
}

const badges: Badges[] = [{name: 'badge1', image_url: 'google.com', link: 'google.com'}]

const tags: Tag[] = [{id: '1', name: 'tag1'}]

const product: Product[] = [
  {
    id: '1',
    global_product_id: '1',
    name: 'Product 1',
    company,
    logo_url: 'google.com',
    tagline: 'Product 1 tagline',
    description: 'Product 1 description',
    updated_at: '2024-01-01',
    tool_integration_configurations,
    lti_configurations,
    badges,
    screenshots: ['greatimage'],
    terms_of_service_url: 'google.com',
    privacy_policy_url: 'google.com',
    accessibility_url: 'google.com',
    support_link: 'google.com',
    tags,
  },
]

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

  it('BadgeCarousel renders as expected', () => {
    const {getByText} = render(<BadgeCarousel badges={product[0].badges} />)
    expect(getByText('badge1')).toBeInTheDocument()
  })

  it('ImageCarousel renders as expected', () => {
    render(<ImageCarousel screenshots={product[0].screenshots} />)

    const displayedImage = document.querySelector('img') as HTMLImageElement
    expect(displayedImage.src).toContain('greatimage')
  })
})
