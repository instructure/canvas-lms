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

// TO DO - actually install query-string
import queryString from 'query-string'
import getCookie from '@instructure/get-cookie'
import type {Product} from '../model/Product'

// TODO: add actual type
type Params = any
type ProductResponse = {
  tools: Array<Product>
  meta: {
    count: number
    total_count: number
    current_page: number
    num_pages: number
    per_page: number
  }
}

// TODO: remove when backend hooked up
const mockProducts: Array<Product> = [
  {
    id: '3a',
    name: 'Achieve3000',
    tagline:
      "Reading comprehension program that delivers news articles at students' reading levels ",
    company: {
      id: '19a',
      name: 'Vendor Test Company',
    },
    logo_url:
      'https://learn-trials-qa.s3.amazonaws.com/attachments/9/assets/e43a04ca22cb1b83752fdda119e50ba5.png',
  },
  {
    id: '5a',
    name: 'Blendspace',
    tagline:
      'Platform where teachers and students can collect, annotate and share digital resources ',
    company: {
      id: '9a',
      name: 'Smart Sparrow',
    },
    logo_url:
      'https://learn-trials-qa.s3.amazonaws.com/attachments/15/assets/e213c9f60d94a8f3ff62220e201d724d.png',
  },
  {
    id: '45a',
    name: '1000 Sight Words Superhero HD Free',
    tagline: "This product needs a tagline so this is what we'll use",
    company: {
      id: '1a',
      name: 'Khan11',
    },
    logo_url:
      'https://learn-trials-qa.s3.amazonaws.com/attachments/17091/assets/Springfeld_Logo.png',
  },
  {
    id: '83a',
    name: '8notes.com',
    tagline: 'Solid mix of free and paid music ed resources, plus sheet music',
    company: {
      id: '6a',
      name: 'Test',
    },
    logo_url:
      'https://learn-trials-qa.s3.amazonaws.com/attachments/345/assets/9da15d28d2ca333399624545c995ff33.png',
  },
  {
    id: '118a',
    name: 'ABCya!',
    tagline: 'Tons of options, though pesky ads can annoy',
    company: {
      id: '17a',
      name: 'NEW COMPANY',
    },
    logo_url:
      'https://learn-trials-qa.s3.amazonaws.com/attachments/512/assets/4b0a4845542a18261c8fc19197a79803.png',
  },
  {
    id: '3642a',
    name: 'AdditionalLinkTest123',
    tagline: 'adding addition links from Sysadmin side',
    company: {
      id: '17a',
      name: 'NEW COMPANY',
    },
    logo_url: 'https://learn-trials-qa.s3.amazonaws.com/attachments/19788/assets/logo.png',
  },
  {
    id: '3676a',
    name: 'Rake',
    tagline: 'Rake is great for gardening',
    company: {
      id: '101a',
      name: "Tom's Education Company",
    },
    logo_url: 'https://learn-trials-qa.s3.amazonaws.com/attachments/20770/assets/rake.png',
  },
]

export const fetchProducts = async (params: Params): Promise<ProductResponse> => {
  let tools = [...mockProducts]
  if (params.filters.companies.length > 0) {
    tools = tools.filter(product =>
      params.filters.companies.map((c: {id: any}) => c.id).includes(product.company.id)
    )
  }
  if (params.name_cont) {
    tools = tools.filter(
      e => e.name.includes(params.name_cont) || e.company.name.includes(params.name_cont)
    )
  }
  const meta = {
    count: tools.length,
    total_count: tools.length,
    current_page: 1,
    num_pages: 1,
    per_page: 20,
  }
  return {tools, meta}

  // TODO: uncomment when backend hooked up and remove mock data

  // const url = `api/v1/products?${queryString(params)}`

  // const response = await fetch(url, {
  //   method: 'get',
  //   headers: {
  //     'X-CSRF-Token': getCookie('_csrf_token'),
  //     'content-Type': 'application/json',
  //   }
  // })

  // if (!response.ok) {
  //   throw new Error(`Failed to fetch products`)
  // }
  // const {products} = await response.json()

  // return products
}

export const fetchProductDetails = async (id?: string): Promise<Product | null> => {
  if (!id) return null

  return mockProducts.find((product: Product) => product.id === id) || null

  // TODO: uncomment when backend hooked up and remove mock data

  // const url = `api/v1/products/${id}`

  // const response = await fetch(url, {
  //   method: 'get',
  //   headers: {
  //     'X-CSRF-Token': getCookie('_csrf_token'),
  //     'content-Type': 'application/json',
  //   }
  // })

  // if (!response.ok) {
  //   throw new Error(`Failed to fetch product with id ${id}`)
  // }

  // const {product} = await response.json()

  // return product
}
