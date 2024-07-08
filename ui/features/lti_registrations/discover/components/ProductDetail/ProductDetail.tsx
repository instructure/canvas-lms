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
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {
  IconA11yLine,
  IconExpandStartLine,
  IconExternalLinkLine,
  IconEyeLine,
  IconMessageLine,
  IconQuizTitleLine,
} from '@instructure/ui-icons'
import {Img} from '@instructure/ui-img'
import {Link} from '@instructure/ui-link'
import {Pill} from '@instructure/ui-pill'
import {Text} from '@instructure/ui-text'
import {useQuery} from '@tanstack/react-query'
import {useLocation, useNavigate} from 'react-router-dom'
import {fetchProductDetails, fetchProducts} from '../../queries/productsQuery'
import ImageCarousel from './ImageCarousel'
// import LtiDetailModal from './LtiDetailModal'

import {openDynamicRegistrationWizard} from '../../../manage/registration_wizard/RegistrationWizardModalState'
import type {Product} from '../../model/Product'
import ProductCard from '../ProductCard/ProductCard'

const ProductDetail = () => {
  // TODO: Reimplement LtiDetailModal
  const [isModalOpen, setModalOpen] = useState(false)
  const [clickedLtiTitle, setClickedLtiTitle] = useState('')

  const navigate = useNavigate()

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
              <Link href={badge.link} isWithinText={false}>
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

  const renderTags = () => {
    return product?.tags.map((t, i) => (
      <Pill margin="0 x-small 0 0" key={`${i + 1}`}>
        {t.name}
      </Pill>
    ))
  }

  const ltiDataClickHandle = (title: string) => {
    setModalOpen(true)
    setClickedLtiTitle(title)
  }

  const renderLtiTitle = () => {
    const lti = product?.tool_integration_configurations
    const version: string[] = []

    if (lti?.hasOwnProperty('lti_13')) {
      version.push('Learning Tools Interoperability (LTI)® v.1.3 Core Specification')
    }
    if (lti?.hasOwnProperty('lti_11')) {
      version.push('Learning Tools Interoperability (LTI)® v.1.1 Core Specification')
    }

    return version.map(title => (
      <Flex.Item margin="0 0 small 0">
        <Link onClick={() => ltiDataClickHandle(title)} isWithinText={false}>
          <Text weight="bold">{title}</Text>
        </Link>
      </Flex.Item>
    ))
  }

  const formattedUpdatedAt = () => {
    const date = new Date(product?.updated_at)
    return date.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    })
  }

  const dynamicRegistrationInformation = product?.tool_integration_configurations?.lti_13?.find(
    configuration => configuration.integration_type === 'lti_13_dynamic_registration'
  )

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
              <Button
                color="primary"
                interaction={dynamicRegistrationInformation ? 'enabled' : 'disabled'}
                onClick={() => {
                  if (!dynamicRegistrationInformation) return null

                  openDynamicRegistrationWizard(
                    dynamicRegistrationInformation.url,
                    dynamicRegistrationInformation.unified_tool_id,
                    () => {
                      // redirect to apps page
                      navigate('/manage')
                    }
                  )
                }}
              >
                Configure
              </Button>
            </Flex.Item>
          </Flex>
          <Flex margin="0 0 0 xx-large">
            <Flex.Item padding="0 0 0 x-small" margin="0 0 0 medium">
              <Text color="secondary">by {product.company.name}</Text> |{' '}
              <Text color="secondary">Updated: {formattedUpdatedAt()}</Text>
            </Flex.Item>
          </Flex>
          <Flex padding="small 0 0 small" margin="0 medium large xx-large">
            <Flex.Item margin="0 0 0 small">{renderTags()}</Flex.Item>
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
              <Text dangerouslySetInnerHTML={{__html: product.description}} />
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
      {/* TODO: Reimplement LtiDetailModal */}
      {/* <LtiDetailModal
        ltiTitle={clickedLtiTitle}
        integrationData={product?.lti}
        isModalOpen={isModalOpen}
        setModalOpen={setModalOpen}
      /> */}
    </div>
  )
}

export default ProductDetail
