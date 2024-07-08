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
import type {Product} from '../../model/Product'
import {Link} from '@instructure/ui-link'
import {Flex} from '@instructure/ui-flex'
import {Img} from '@instructure/ui-img'
import {Text} from '@instructure/ui-text'
import {TruncateText} from '@instructure/ui-truncate-text'
import {View} from '@instructure/ui-view'
import {Tag} from '@instructure/ui-tag'
import {ZAccountId} from '../../../manage/model/AccountId'

type ProductCardProps = {
  product: Product
}

const ProductCard = (props: ProductCardProps) => {
  const {product} = props
  const accountId = ZAccountId.parse(window.location.pathname.split('/')[2])

  return (
    <Flex.Item>
      <View
        key={product.id}
        as="div"
        width={340}
        height="100%"
        borderColor="primary"
        borderRadius="medium"
        borderWidth="small"
        padding="medium"
      >
        <Flex direction="column" height="100%">
          <Flex gap="small" margin="0 0 medium 0">
            <div style={{borderRadius: '50%', overflow: 'hidden'}}>
              <Img src={product.logo_url} width={48} height={48} />
            </div>
            <div>
              <Text weight="bold" size="large">
                <Link
                  isWithinText={false}
                  themeOverride={{fontWeight: 700, color: 'black'}}
                  href={`/accounts/${accountId}/apps/product_detail/${product.global_product_id}`}
                >
                  {product.name}
                </Link>
              </Text>
              <div>
                by{' '}
                <Text weight="bold" color="secondary">
                  {product.company.name}
                </Text>
              </div>
            </div>
          </Flex>
          <View margin="0 0 medium 0">
            <Text>
              <TruncateText maxLines={3} ellipsis=" (...)">
                {product.tagline}
              </TruncateText>
            </Text>
          </View>
          <View as="div" margin="auto 0 0 0">
            {product?.tags?.map(badge => (
              <Tag key={badge.name} text={badge.name} size="small" margin="0 xx-small 0 0" />
            ))}
          </View>
        </Flex>
      </View>
    </Flex.Item>
  )
}

export default ProductCard
