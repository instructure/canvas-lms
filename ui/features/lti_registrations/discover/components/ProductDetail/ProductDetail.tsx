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
import {useLocation} from 'react-router-dom'
import {fetchProductDetails, fetchProducts} from '../../queries/productsQuery'
import {useQuery} from '@tanstack/react-query'
import {Flex} from '@instructure/ui-flex'
import {Img} from '@instructure/ui-img'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {Button} from '@instructure/ui-buttons'
import {Pill} from '@instructure/ui-pill'
import {View} from '@instructure/ui-view'
import {
  IconExpandStartLine,
  IconArrowUpSolid,
  IconEyeLine,
  IconQuizTitleLine,
  IconA11yLine,
  IconMessageLine,
} from '@instructure/ui-icons'

import ProductCard from '../ProductCard/ProductCard'
import type {Product} from '../../model/Product'

const ProductDetail = () => {
  const location = useLocation()
  const currentProductId = location.pathname.replace('/product_detail/', '') as String

  const {data: product} = useQuery({
    queryKey: ['lti_product_detail'],
    queryFn: () => fetchProductDetails(currentProductId),
  })

  const params = () => {
    return {
      filters: {companies: [product?.company]},
    }
  }

  const {data: lti_product_info} = useQuery({
    queryKey: ['lti_product_info', product?.company],
    queryFn: () => fetchProducts(params()),
  })

  const excludeCurrentProduct = lti_product_info?.tools.filter(
    otherProducts => otherProducts.id !== currentProductId
  )

  const renderProducts = () => {
    return excludeCurrentProduct?.map((products: Product) => <ProductCard product={products} />)
  }

  const renderBadges = () => {
    return product?.badges.map(badge => (
      <Flex margin="0 0 large 0">
        <Flex.Item>
          <div>
            <Img src={badge.image_url} width={50} height={50} />
          </div>
        </Flex.Item>
        <Flex.Item padding="0 0 0 small">
          <Text weight="bold" size="medium">
            {badge.name}
          </Text>
          <Flex.Item>
            <div>
              <Link href={badge.badge_url} isWithinText={false}>
                <Text weight="bold">Learn More</Text>
              </Link>
            </div>
          </Flex.Item>
        </Flex.Item>
      </Flex>
    ))
  }

  return (
    <div>
      {product && product.lti && product.company && product.countries ? (
        <>
          <Flex>
            <Flex.Item>
              <div>
                <Img src={product.logo_url} width={80} height={80} />
              </div>
            </Flex.Item>
            <Flex.Item shouldGrow={true} shouldShrink={true} padding="0 0 0 small">
              <Text weight="bold" size="x-large">
                {product.name}
              </Text>
              <Flex.Item shouldGrow={true} shouldShrink={true}>
                <div style={{marginBottom: '.5rem'}}>{product.tagline}</div>
              </Flex.Item>
            </Flex.Item>
            <Flex.Item align="start">
              <Button color="secondary" margin="0 small 0 0">
                Deploy
              </Button>
              <Button color="primary">Configure</Button>
            </Flex.Item>
          </Flex>
          <Flex margin="0 0 0 xx-large">
            <Flex.Item padding="0 0 0 x-small" margin="0 0 0 medium">
              by{' '}
              <Link isWithinText={false} href={product.company.company_url}>
                <Text color="secondary">{product.company.name}</Text>
              </Link>{' '}
              | Updated: {product.updatedAt}
            </Flex.Item>
          </Flex>
          <Flex padding="small 0 0 x-small" margin="0 medium medium medium">
            <Flex.Item padding="0 small 0 xx-large">
              <Pill>{product.toolType}</Pill>
            </Flex.Item>
            <Flex.Item padding="0 x-small 0 0">
              <Pill>{product.demographic}</Pill>
            </Flex.Item>
            <Flex.Item padding="0 x-small 0 0">
              <Pill>{product.lti.versions[0]}</Pill>
            </Flex.Item>
            <Flex.Item padding="0 x-small 0 0">
              <Pill>{product.lti.versions[1]}</Pill>
            </Flex.Item>
          </Flex>
          <View
            as="span"
            display="inline-block"
            maxWidth="10rem"
            height={265}
            minWidth={340}
            margin="0 medium small 0"
            padding="medium"
            background="primary"
            shadow="above"
          >
            placeholder
          </View>
          <View
            as="span"
            display="inline-block"
            maxWidth="10rem"
            height={265}
            minWidth={340}
            margin="0 medium small 0"
            padding="medium"
            background="primary"
            shadow="above"
          >
            placeholder
          </View>
          <View
            as="span"
            display="inline-block"
            maxWidth="10rem"
            height={265}
            minWidth={340}
            margin="0 0 small 0"
            padding="medium"
            background="primary"
            shadow="above"
          >
            placeholder
          </View>
          <Flex margin="medium 0 0 0">
            <Flex.Item>
              <Text weight="bold" size="large">
                Overview
              </Text>
            </Flex.Item>
          </Flex>
          <Flex>
            <Flex.Item margin="medium 0 small 0">
              <Text>{product.description}</Text>
            </Flex.Item>
          </Flex>
          <Link href={product.company.company_url} isWithinText={false}>
            <Text weight="bold">See more</Text>
          </Link>
          <Flex>
            <Flex.Item margin="medium 0 small 0">
              <Text weight="bold" size="large">
                Links
              </Text>
            </Flex.Item>
          </Flex>
          <Flex>
            <Flex.Item>
              <Link
                href={product.company.company_url}
                isWithinText={false}
                renderIcon={<IconExpandStartLine />}
              >
                <Text weight="bold">Website</Text>
                <IconArrowUpSolid />
              </Link>
            </Flex.Item>
            <Flex.Item margin="0 0 0 large">
              <Link
                href={product.company.company_url}
                isWithinText={false}
                renderIcon={<IconEyeLine />}
              >
                <Text weight="bold">Privacy Policy</Text>
                <IconArrowUpSolid />
              </Link>
            </Flex.Item>
            <Flex.Item margin="0 0 0 large">
              <Link
                href={product.company.company_url}
                isWithinText={false}
                renderIcon={<IconQuizTitleLine />}
              >
                <Text weight="bold">Terms of Service</Text>
                <IconArrowUpSolid />
              </Link>
            </Flex.Item>
            <Flex.Item margin="0 0 0 large">
              <Link
                href={product.company.company_url}
                isWithinText={false}
                renderIcon={<IconA11yLine />}
              >
                <Text weight="bold">Accessibility</Text>
                <IconArrowUpSolid />
              </Link>
            </Flex.Item>
            <Flex.Item margin="0 0 0 large">
              <Link
                href={product.company.company_url}
                isWithinText={false}
                renderIcon={<IconMessageLine />}
              >
                <Text weight="bold">Contact</Text>
                <IconArrowUpSolid />
              </Link>
            </Flex.Item>
          </Flex>
          <Flex>
            <Flex.Item margin="medium 0 medium 0">
              <Text weight="bold" size="large">
                Hosting Countries
              </Text>
            </Flex.Item>
          </Flex>
          <Text>{product.countries.join(', ')}</Text>
          <Flex>
            <Flex.Item margin="medium 0 medium 0">
              <Text weight="bold" size="large">
                Resources and Documents
              </Text>
            </Flex.Item>
          </Flex>
          <Text weight="bold" size="medium">
            Integrations
          </Text>
          <Flex>
            <Flex.Item margin="small 0 small 0">
              <Link href={product.company.company_url} isWithinText={false}>
                <Text weight="bold">{product.lti.title[0]}</Text>
              </Link>
            </Flex.Item>
          </Flex>
          <Flex>
            <Flex.Item margin="0 0 small 0">
              <Link href={product.company.company_url} isWithinText={false}>
                <Text weight="bold">{product.lti.title[1]}</Text>
              </Link>
            </Flex.Item>
          </Flex>
          <Flex>
            <Flex.Item margin="0 0 small 0">
              <Text weight="bold" size="medium">
                Other
              </Text>
            </Flex.Item>
          </Flex>
          <Flex>
            <Flex.Item margin="0 0 0 0">
              <Link href={product.company.company_url} isWithinText={false}>
                <Text weight="bold">Subscription Information</Text>
                <IconArrowUpSolid />
              </Link>
            </Flex.Item>
          </Flex>
          <Flex>
            <Flex.Item margin="medium 0 medium 0">
              <Text weight="bold" size="large">
                Badges
              </Text>
            </Flex.Item>
          </Flex>
          <Flex direction="row" gap="xx-large">
            {renderBadges()}
          </Flex>
          {excludeCurrentProduct?.length ? (
            <Flex justifyItems="space-between" margin="0 0 medium 0">
              <Flex.Item>
                <Text weight="bold" size="large">
                  More Products by {product.company.name}
                </Text>
              </Flex.Item>
              <Flex.Item>
                <Link href={product.company.company_url} isWithinText={false}>
                  <Text weight="bold">See All</Text>
                </Link>
              </Flex.Item>
            </Flex>
          ) : (
            <div />
          )}{' '}
        </>
      ) : (
        <div />
      )}
      <Flex direction="row" gap="small">
        {renderProducts()}
      </Flex>
    </div>
  )
}

export default ProductDetail
