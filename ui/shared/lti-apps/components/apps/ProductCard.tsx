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
import type {Product} from '../../models/Product'
import {Link} from '@instructure/ui-link'
import {Flex} from '@instructure/ui-flex'
import {Img} from '@instructure/ui-img'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Tag} from '@instructure/ui-tag'
import {TruncateText} from '@instructure/ui-truncate-text'
import TruncateWithTooltip from '../common/TruncateWithTooltip'

type ProductCardProps = {
  product: Product
}

const ProductCard = (props: ProductCardProps) => {
  const {product} = props
  const productUrl = `${window.location.origin}${window.location.pathname}/product_detail/${
    product.global_product_id
  }${window.location.pathname.endsWith('configurations') ? '#tab-apps' : ''}`

  return (
    <Flex.Item>
      <View
        key={product.id}
        as="div"
        height={200}
        width={350}
        borderColor="primary"
        borderRadius="medium"
        borderWidth="small"
        padding="mediumSmall"
        onClick={() => {
          window.location.href = productUrl
        }}
        cursor="pointer"
      >
        <Flex direction="column" height="100%">
          <Flex gap="small" margin="0 0 medium 0">
            <div style={{borderRadius: '8px', overflow: 'hidden', minWidth: '48px'}}>
              <Img src={product.logo_url} width={48} height={48} />
            </div>
            <div>
              <TruncateWithTooltip
                linesAllowed={1}
                horizontalOffset={0}
                backgroundColor="primary-inverse"
              >
                <Text weight="bold" size="medium">
                  <Link
                    isWithinText={false}
                    themeOverride={{fontWeight: 700, color: 'black'}}
                    href={productUrl}
                  >
                    {product?.name}
                  </Link>
                </Text>
              </TruncateWithTooltip>
              <div>
                <span style={{fontSize: '14px'}}>by </span>
                <Text weight="bold" color="secondary" size="small">
                  {product?.company?.name}
                </Text>
              </div>
            </div>
          </Flex>
          <View margin="0 0 medium 0">
            <Text size="small">
              <TruncateText maxLines={2} ellipsis=" (...)">
                {product.tagline}
              </TruncateText>
            </Text>
          </View>
          <View as="div" margin="auto 0 0 0">
            {product?.tags?.slice(0, 1).map(tag => (
              <Tag key={tag.name} text={tag.name} size="small" margin="0 xx-small 0 0" />
            ))}
          </View>
        </Flex>
      </View>
    </Flex.Item>
  )
}

export default ProductCard
