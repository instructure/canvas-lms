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

import {useScope as createI18nScope} from '@canvas/i18n'
import React, {useState} from 'react'
import {useLocation} from 'react-router-dom'
import useBreakpoints from '@canvas/lti-apps/hooks/useBreakpoints'
import useSimilarProducts from '../../queries/useSimilarProducts'
import useProduct from '../../queries/useProduct'
import {Breadcrumb} from '@instructure/ui-breadcrumb'
import {Spinner} from '@instructure/ui-spinner'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {Tag} from '@instructure/ui-tag'
import {View} from '@instructure/ui-view'
import {IconExpandStartLine, IconExternalLinkLine, IconMessageLine} from '@instructure/ui-icons'
import GenericErrorPage from '@canvas/generic-error-page/react'
import {TruncateText} from '@instructure/ui-truncate-text'
import TruncateWithTooltip from '../common/TruncateWithTooltip'
import {stripHtmlTags} from '../common/stripHtmlTags'
import LtiConfigurationDetail from './LtiConfigurationDetail'
import IntegrationDetailModal from './IntegrationDetailModal'
import ExternalLinks from './ExternalLinks'
import ProductCarousel from '../common/Carousels/ProductCarousel'
import ImageCarousel from '../common/Carousels/ImageCarousel'
import Disclaimer from '../common/Disclaimer'
import type {Lti, Product} from '../../models/Product'
import {instructorAppsRoute} from '@canvas/lti-apps/utils/route'

const I18n = createI18nScope('lti_registrations')

type ProductDetailProps = {
  renderConfigureButton?: (buttonWidth: 'block' | 'inline-block', lti: Lti) => JSX.Element
}

const ProductDetail = (props: ProductDetailProps) => {
  const [isIntDetailModalOpen, setIntDetailModalOpen] = useState(false)
  const [intDetailTitle, setIntDetailTitle] = useState('')
  const [intDetailContent, setIntDetailContent] = useState('')
  const [isTruncated, setIsTruncated] = useState(false)
  const [showTrucatedDescription, setShowTruncatedDescription] = useState(true)

  const location = useLocation()

  const currentProductId = location.pathname.replace('/product_detail/', '')
  const {isDesktop, isMobile, isMaxMobile, isMaxTablet} = useBreakpoints()
  const previousPathRegexp = window.location.pathname.replace(/\product_detail.*/, '')
  const previousPath = previousPathRegexp.endsWith(`${instructorAppsRoute}/`)
    ? `${previousPathRegexp.slice(0, -1)}#tab-apps`
    : previousPathRegexp

  const {product, isLoading, isError} = useProduct({productId: currentProductId})
  const productDescription = stripHtmlTags(product?.description)
  const lti_13 = product?.lti_configurations.lti_13
  const integrationData =
    (lti_13?.placements?.length ?? 0) > 0 || (lti_13?.services?.length ?? 0) > 0
      ? product?.lti_configurations.lti_13
      : product?.lti_configurations.lti_11

  const params = () => {
    return {
      filters: {companies: [{id: product?.company.id.toString(), name: product?.company.name}]},
    }
  }

  const {otherProductsByCompany} = useSimilarProducts({params: params(), product})

  const ErrorPage = () => {
    return <GenericErrorPage errorMessage={I18n.t('Error loading product details')} />
  }

  const excludeCurrentProduct = otherProductsByCompany?.tools.filter(
    (otherProducts: Product) => otherProducts.global_product_id !== currentProductId
  )

  const ltiConfiguration = product?.tool_integration_configurations

  const intDetailClickHandler = (title: string, content: string) => {
    setIntDetailModalOpen(true)
    setIntDetailTitle(title)
    setIntDetailContent(content)
  }

  const formattedUpdatedAt = () => {
    const date = new Date(product?.updated_at as string)
    return date.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    })
  }

  const renderConfigureButton = () => {
    const buttonMargins = !isDesktop ? '0 0 medium 0' : '0 0 xx-large 0'
    const tabletMargin = isMaxTablet ? '0 0 0 small' : '0'
    const buttonWidth = isMaxMobile ? 'block' : 'inline-block'

    return (
      <Flex margin={buttonMargins}>
        <Flex.Item shouldGrow={true} margin={tabletMargin}>
          {props.renderConfigureButton && ltiConfiguration
            ? props.renderConfigureButton(buttonWidth, ltiConfiguration)
            : null}
        </Flex.Item>
      </Flex>
    )
  }

  const renderHeader = () => {
    return (
      <div>
        {!isDesktop && (
          <Flex margin="medium 0 0 small">
            <div style={{borderRadius: '8px'}}>
              <img alt="" src={product.logo_url} width={80} height={80} style={{borderRadius: 8}} />
            </div>
          </Flex>
        )}
        <Flex margin={isDesktop ? 'small 0 0 0' : '0'}>
          {isDesktop && (
            <Flex.Item>
              <div style={{borderRadius: '8px'}}>
                <img
                  alt=""
                  src={product.logo_url}
                  width={80}
                  height={80}
                  style={{borderRadius: 8}}
                />
              </div>
            </Flex.Item>
          )}
          <Flex.Item shouldGrow={true} shouldShrink={true} padding="small 0 0 small">
            <Text weight="bold" size="x-large">
              {product.name}
            </Text>
            <Flex.Item shouldGrow={true} shouldShrink={true}>
              <div style={{marginBottom: '.5rem'}}>
                <TruncateWithTooltip
                  linesAllowed={2}
                  horizontalOffset={isDesktop ? -150 : -10}
                  backgroundColor="primary"
                >
                  <Text>{product.tagline}</Text>
                </TruncateWithTooltip>
              </div>
            </Flex.Item>
          </Flex.Item>
          {isDesktop && renderConfigureButton()}
        </Flex>
      </div>
    )
  }

  const renderBylineAndUpdatedAt = () => {
    return !isMobile ? (
      <Flex margin={isDesktop ? '0 0 0 large' : '0 0 0 small'}>
        <Flex.Item margin={isDesktop ? '0 0 0 xx-large' : '0'}>
          <Text color="secondary">
            {I18n.t('by')} {product.company.name}
          </Text>{' '}
          |{' '}
          <Text color="secondary">
            {I18n.t('Updated')}: {formattedUpdatedAt()}
          </Text>
        </Flex.Item>
      </Flex>
    ) : (
      <Flex direction="column">
        <Flex.Item margin="0 0 0 small">
          <Text color="secondary">
            {I18n.t('by')} {product.company.name}
          </Text>
        </Flex.Item>
        <Flex.Item margin="0 0 0 small">
          <Text color="secondary">
            {I18n.t('Updated')}: {formattedUpdatedAt()}
          </Text>
        </Flex.Item>
      </Flex>
    )
  }

  const renderTags = () => {
    return product?.tags.map((t, i) => (
      <Tag text={t.name} margin="x-small x-small 0 0" key={`${i + 1}`} />
    ))
  }

  const hasIntegrationResources = product?.integration_resources.resources?.length > 0

  const renderIntegrationResources = () => {
    if (!product) return null

    const {comments, resources} = product.integration_resources

    const renderComments = comments ? (
      <Flex>
        <Flex.Item direction="row">
          <Text dangerouslySetInnerHTML={{__html: comments || ''}} />
        </Flex.Item>
      </Flex>
    ) : null

    const renderResources =
      resources?.length === 0 ? (
        <Flex.Item margin="small 0 large 0">
          <Text>The tool provider did not include implementation resources for this tool.</Text>
        </Flex.Item>
      ) : (
        resources?.map((resource, i) => (
          <Flex.Item margin="0 0 medium 0" key={`${i + 1}`}>
            <Link
              style={{alignItems: 'center', display: 'flex'}}
              onClick={() => {
                intDetailClickHandler(resource.name, resource.content)
              }}
              isWithinText={false}
            >
              <Text weight="bold">{resource.name}</Text>
              <View margin="0 0 0 x-small">
                <IconExternalLinkLine width={18} height={18} />
              </View>
            </Link>

            <div>
              <Text>{resource.description}</Text>
            </div>
          </Flex.Item>
        ))
      )

    return (
      <>
        {renderComments}
        {renderResources}
      </>
    )
  }

  if (isError) {
    return <ErrorPage />
  }

  return (
    <div>
      {isLoading ? (
        <Spinner renderTitle="Loading Page" role="alert" aria-busy="true" data-testid="loading" />
      ) : (
        product && (
          <>
            <Breadcrumb label={I18n.t('Apps')}>
              <Breadcrumb.Link href={previousPath}>{I18n.t('Apps')}</Breadcrumb.Link>
              <Breadcrumb.Link>{product.name}</Breadcrumb.Link>
            </Breadcrumb>
            {renderHeader()}
            {renderBylineAndUpdatedAt()}
            <Flex
              padding="small 0 0 small"
              margin={isDesktop ? '0 medium medium medium' : '0 medium medium 0'}
            >
              <Flex.Item margin={isDesktop ? '0 0 0 xx-large' : '0'}>{renderTags()}</Flex.Item>
            </Flex>
            {!isDesktop && renderConfigureButton()}
            <ImageCarousel screenshots={product.screenshots} />
            <View
              as="div"
              width={130}
              margin="small 0 small 0"
              position="relative"
              withFocusOutline={!showTrucatedDescription}
            >
              <Text weight="bold" size="x-large">
                {I18n.t('Overview')}
              </Text>
            </View>{' '}
            <Flex gap="x-large">
              {product.company.company_url && (
                <Flex.Item margin="0 small medium small">
                  <Link
                    href={product.company.company_url}
                    isWithinText={false}
                    renderIcon={<IconExpandStartLine />}
                    target="_blank"
                  >
                    <Text weight="bold">{I18n.t('Website')}</Text>
                  </Link>
                </Flex.Item>
              )}
              {product.support_url && (
                <Flex.Item margin="0 0 medium 0">
                  <Link
                    href={product.support_url}
                    isWithinText={false}
                    renderIcon={<IconMessageLine />}
                    target="_blank"
                  >
                    <Text weight="bold">{I18n.t('Contact')}</Text>
                  </Link>
                </Flex.Item>
              )}
            </Flex>
            <Flex>
              <Flex.Item margin="0 0 small 0">
                <TruncateText
                  maxLines={showTrucatedDescription ? 4 : 50}
                  truncate="word"
                  ellipsis=" (...)"
                  onUpdate={() => setIsTruncated(true)}
                >
                  <Text>{productDescription}</Text>
                </TruncateText>
              </Flex.Item>
            </Flex>
            {isTruncated && (
              <Link
                margin="0 medium medium 0"
                forceButtonRole={true}
                isWithinText={false}
                onClick={() => setShowTruncatedDescription(!showTrucatedDescription)}
                themeOverride={{
                  focusOutlineColor: 'transparent',
                  fontWeight: 600,
                }}
              >
                {showTrucatedDescription ? 'See more' : 'See less'}
              </Link>
            )}
            <ExternalLinks product={product} />
            <LtiConfigurationDetail integrationData={integrationData} />
            <Flex margin="medium 0 0 0">
              <Flex.Item margin="0 0 small 0">
                <Text weight="bold" size="x-large">
                  {I18n.t('Implementation Resources')}
                </Text>
              </Flex.Item>
            </Flex>
            <Flex direction="column" margin="0 0 large 0">
              {hasIntegrationResources
                ? renderIntegrationResources()
                : I18n.t(
                    'The tool provider did not include implementation resources for this tool.'
                  )}
            </Flex>
            {(excludeCurrentProduct?.length ?? 0) > 0 && (
              <ProductCarousel
                products={excludeCurrentProduct ?? []}
                companyName={product.company.name}
              />
            )}
            <div style={{marginTop: '35px'}}>
              <Disclaimer />
            </div>
          </>
        )
      )}
      <IntegrationDetailModal
        title={intDetailTitle}
        content={intDetailContent}
        isModalOpen={isIntDetailModalOpen}
        setModalOpen={setIntDetailModalOpen}
      />
    </div>
  )
}

export default ProductDetail
