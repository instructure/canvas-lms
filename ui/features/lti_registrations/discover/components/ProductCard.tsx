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
import type {Product} from '../model/Product'

import {Flex} from '@instructure/ui-flex'
import {Img} from '@instructure/ui-img'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

type ProductCardProps = {
  product: Product
}

const ProductCard = (props: ProductCardProps) => {
  const product = props.product

  return (
    <Flex.Item>
      <View
        key={product.id}
        as="div"
        width={444}
        height={236}
        borderColor="primary"
        borderRadius="small"
        borderWidth="medium"
        padding="medium"
      >
        <Flex gap="small" margin="0 0 medium 0">
          <div style={{borderRadius: '50%', overflow: 'hidden'}}>
            <Img src={product.logoUrl} width={48} height={48} />
          </div>
          <div>
            <Text weight="bold" size="large">
              {product.name}
            </Text>
            <div>
              {/* TODO: Add I18n to below line */}
              by <Link href={product.companyUrl}>{product.company}</Link>
            </div>
          </div>
        </Flex>
        <div>{product.tagline}</div>
      </View>
    </Flex.Item>
  )
}

export default ProductCard
