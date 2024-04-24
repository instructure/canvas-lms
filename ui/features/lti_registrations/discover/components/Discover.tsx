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
import {Flex} from '@instructure/ui-flex'

import ProductCard from './ProductCard'

const product = {
  name: 'Product Name',
  company: 'Company',
  companyUrl: 'https://google.com',
  tagline: 'This product supports LTI 1.3',
  logoUrl:
    'https://media.istockphoto.com/id/1147544807/vector/thumbnail-image-vector-graphic.jpg?s=612x612&w=0&k=20&c=rnCKVbdxqkjlcs3xH87-9gocETqpspHFXu5dIGB4wuM=',
}

export const Discover = () => {
  const renderProducts = () => {
    return [...Array(10)].map((e, i) => {
      const id = `test-id-${i}`
      return <ProductCard product={{...product, id}} />
    })
  }
  return (
    <div>
      <Flex gap="medium" wrap="wrap">
        {renderProducts()}
      </Flex>
    </div>
  )
}
