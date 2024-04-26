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
import type {Product, Company} from '../model/Product'

import {Flex} from '@instructure/ui-flex'
import {Img} from '@instructure/ui-img'
import {CondensedButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {useSearchParams} from 'react-router-dom'

type ProductCardProps = {
  product: Product
}

const ProductCard = (props: ProductCardProps) => {
  const {product} = props
  const [searchParams, setSearchParams] = useSearchParams()

  const setCompany = (company: Company) => {
    const queryParams = searchParams.get('filter')
    const params = queryParams
      ? JSON.parse(queryParams)
      : {companies: [], versions: [], audience: []}

    if (!params.companies.some((c: {id: string}) => c.id === company.id)) {
      setSearchParams({
        filter: JSON.stringify({...params, companies: [...params.companies, company]}),
      })
    }
  }

  return (
    <Flex.Item>
      <View
        key={product.id}
        as="div"
        width={340}
        height={200}
        borderColor="primary"
        borderRadius="small"
        borderWidth="medium"
        padding="medium"
      >
        <Flex gap="small" margin="0 0 x-small 0">
          <div style={{borderRadius: '50%', overflow: 'hidden'}}>
            <Img src={product.logo_url} width={48} height={48} />
          </div>
          <div>
            <Text weight="bold" size="large">
              {product.name}
            </Text>
            <Flex gap="x-small" wrap="no-wrap">
              <div>by</div>
              <CondensedButton onClick={() => setCompany(product.company)}>
                {product.company.name}
              </CondensedButton>
            </Flex>
          </div>
        </Flex>
        <div>{product.tagline}</div>
      </View>
    </Flex.Item>
  )
}

export default ProductCard
