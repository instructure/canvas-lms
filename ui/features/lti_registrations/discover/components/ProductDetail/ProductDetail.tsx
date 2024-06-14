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

import React, {useState} from 'react'
import {useLocation} from 'react-router-dom'
import {fetchProductDetails, fetchProducts} from '../../queries/productsQuery'
import {useQuery} from '@tanstack/react-query'
import LtiDetailModal from './LtiDetailModal'
import {Flex} from '@instructure/ui-flex'
import {Img} from '@instructure/ui-img'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {Button} from '@instructure/ui-buttons'
import {Pill} from '@instructure/ui-pill'
import {
  IconExpandStartLine,
  IconExternalLinkLine,
  IconEyeLine,
  IconQuizTitleLine,
  IconA11yLine,
  IconMessageLine,
} from '@instructure/ui-icons'
import ImageCarousel from './ImageCarousel'

import ProductCard from '../ProductCard/ProductCard'
import type {Product} from '../../model/Product'

const ProductDetail = () => {
  const [isModalOpen, setModalOpen] = useState(false)
  const [clickedLtiTitle, setClickedLtiTitle] = useState('')

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

  const {data: otherProductsByCompany} = useQuery({
    queryKey: ['lti_similar_products_by_company', product?.company],
    queryFn: () => fetchProducts(params()),
  })

  const excludeCurrentProduct = otherProductsByCompany?.tools.filter(
    otherProducts => otherProducts.id !== currentProductId
  )

  const renderProducts = () => {
    return excludeCurrentProduct?.map((products: Product, i) => (
      <ProductCard key={`${i + 1}`} product={products} />
    ))
  }

  const renderBadges = () => {
    return product?.badges.map((badge, i) => (
      <Flex key={`${i + 1}`} margin="0 0 large 0">
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
                <Text weight="bold">
                  Learn More <IconExternalLinkLine />
                </Text>
              </Link>
            </div>
          </Flex.Item>
        </Flex.Item>
      </Flex>
    ))
  }

  const renderLtiVersions = () => {
    return product?.lti.versions.map(version => <Pill margin="0 x-small 0 0">{version}</Pill>)
  }
  const ltiDataClickHandle = (title: string) => {
    setModalOpen(true)
    setClickedLtiTitle(title)
  }
  const renderLtiTitle = () => {
    return product?.lti.title.map(title => (
      <Flex.Item margin="0 0 small 0">
        <Link onClick={() => ltiDataClickHandle(title)} isWithinText={false}>
          <Text weight="bold">{title}</Text>
        </Link>
      </Flex.Item>
    ))
  }
  return (
    <div>
      {product ? (
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
              <Button color="primary">Configure</Button>
            </Flex.Item>
          </Flex>
          <Flex margin="0 0 0 xx-large">
            <Flex.Item padding="0 0 0 x-small" margin="0 0 0 medium">
              <Text color="secondary">by {product.company.name}</Text> |{' '}
              <Text color="secondary">Updated: {product.updatedAt}</Text>
            </Flex.Item>
          </Flex>
          <Flex padding="small 0 0 x-small" margin="0 medium medium medium">
            <Flex.Item padding="0 x-small 0 xx-large">
              <Pill>{product.toolType}</Pill>
            </Flex.Item>
            <Flex.Item padding="0 x-small 0 0">
              <Pill>{product.demographic}</Pill>
            </Flex.Item>
            <Flex.Item padding="0 0 0 0">{renderLtiVersions()}</Flex.Item>
          </Flex>
          <ImageCarousel screenshots={product.screenshots} />
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
              </Link>
            </Flex.Item>
            <Flex.Item margin="0 0 0 large">
              <Link
                href={product.company.company_url}
                isWithinText={false}
                renderIcon={<IconEyeLine />}
              >
                <Text weight="bold">Privacy Policy</Text>
              </Link>
            </Flex.Item>
            <Flex.Item margin="0 0 0 large">
              <Link
                href={product.company.company_url}
                isWithinText={false}
                renderIcon={<IconQuizTitleLine />}
              >
                <Text weight="bold">Terms of Service</Text>
              </Link>
            </Flex.Item>
            <Flex.Item margin="0 0 0 large">
              <Link
                href={product.company.company_url}
                isWithinText={false}
                renderIcon={<IconA11yLine />}
              >
                <Text weight="bold">Accessibility</Text>
              </Link>
            </Flex.Item>
            <Flex.Item margin="0 0 0 large">
              <Link
                href={product.company.company_url}
                isWithinText={false}
                renderIcon={<IconMessageLine />}
              >
                <Text weight="bold">Contact</Text>
              </Link>
            </Flex.Item>
          </Flex>
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
          <Flex direction="column" margin="small 0 0 0">
            {renderLtiTitle()}
          </Flex>
          <Flex>
            <Flex.Item margin="0 0 small 0">
              <Text weight="bold" size="medium">
                Other
              </Text>
            </Flex.Item>
          </Flex>
          <Flex>
            <Flex.Item>
              <Link href={product.company.company_url} isWithinText={false}>
                <Text weight="bold">
                  Subscription Information <IconExternalLinkLine />
                </Text>
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

      <LtiDetailModal
        ltiTitle={clickedLtiTitle}
        integrationData={product?.lti}
        isModalOpen={isModalOpen}
        setModalOpen={setModalOpen}
      />
    </div>
  )
}

export default ProductDetail
