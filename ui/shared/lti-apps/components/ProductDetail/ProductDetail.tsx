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

import GenericErrorPage from '@canvas/generic-error-page/react'
import {useScope as createI18nScope} from '@canvas/i18n'
import useBreakpoints from '@canvas/lti-apps/hooks/useBreakpoints'
import {pickPreferredIntegration} from '@canvas/lti-apps/utils/pickPreferredIntegration'
import {instructorAppsRoute} from '@canvas/lti-apps/utils/routes'
import {IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {
  IconExpandStartLine,
  IconExternalLinkLine,
  IconImageLine,
  IconMessageLine,
} from '@instructure/ui-icons'
import {Img} from '@instructure/ui-img'
import {Link} from '@instructure/ui-link'
import {Spinner} from '@instructure/ui-spinner'
import {Tag} from '@instructure/ui-tag'
import {Text} from '@instructure/ui-text'
import {TruncateText} from '@instructure/ui-truncate-text'
import {ContextView, View} from '@instructure/ui-view'
import React, {useState, useEffect} from 'react'
import {useLocation} from 'react-router-dom'
import {useAppendBreadcrumb} from '../../../breadcrumbs/useAppendBreadcrumb'
import type {Product} from '../../models/Product'
import useProduct from '../../queries/useProduct'
import useSimilarProducts from '../../queries/useSimilarProducts'
import ImageCarouselModal from '../common/Carousels/ImageCarouselModal'
import ProductCarousel from '../common/Carousels/ProductCarousel'
import Disclaimer from '../common/Disclaimer'
import TruncateWithTooltip from '../common/TruncateWithTooltip'
import {stripHtmlTags} from '../common/stripHtmlTags'
import ExternalLinks from './ExternalLinks'
import IntegrationDetailModal from './IntegrationDetailModal'
import LtiConfigurationDetail from './LtiConfigurationDetail'

const I18n = createI18nScope('lti_registrations')

type ProductDetailProps = {
  renderConfigureButton?: (buttonWidth: 'block' | 'inline-block', product: Product) => JSX.Element
}

const ProductDetail = (props: ProductDetailProps) => {
  const [isImageModalOpen, setImageModalOpen] = useState(false)
  const [imageModalScreenshots, setImageModalScreenshots] = useState<string[]>([])
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

  const {product, isLoading, isError} = useProduct({
    productId: currentProductId,
  })
  // @ts-expect-error
  useAppendBreadcrumb(product?.name, previousPath, !!product?.name)
  // @ts-expect-error
  const productDescription = stripHtmlTags(product?.description)

  useEffect(() => {
    if (window.pendo && typeof window.pendo.track === 'function' && product?.id && product?.name) {
      window.pendo.track('Product', {
        productId: product.id,
        productName: product.name,
        source: 'canvas-apps',
        placement: 'standard',
      })
    }
  }, [product?.id, product?.name])

  const {otherProductsByCompany} = useSimilarProducts({
    params: {
      filters: {
        companies: [{id: product?.company.id.toString(), name: product?.company.name}],
      },
    },
    product,
  })

  const ErrorPage = () => {
    return <GenericErrorPage errorMessage={I18n.t('Error loading product details')} />
  }

  const excludeCurrentProduct = otherProductsByCompany?.tools.filter(
    (otherProducts: Product) => otherProducts.global_product_id !== currentProductId,
  )

  const ltiConfiguration = product?.canvas_lti_configurations
  const relevantIntegration = pickPreferredIntegration(ltiConfiguration ? ltiConfiguration : [])

  const imageModalClickHandler = (screenshots: string[]) => {
    setImageModalOpen(true)
    setImageModalScreenshots(screenshots)
  }
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
          {props.renderConfigureButton
            ? // @ts-expect-error
              props.renderConfigureButton(buttonWidth, product)
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
              {/* @ts-expect-error */}
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
                  // @ts-expect-error
                  src={product.logo_url}
                  width={80}
                  height={80}
                  style={{borderRadius: 8}}
                />
              </div>
            </Flex.Item>
          )}
          <Flex.Item shouldGrow={true} shouldShrink={true} margin="small 0 0 mediumSmall">
            {/* @ts-expect-error */}
            <Heading level="h1">{product.name}</Heading>
            <Flex.Item shouldGrow={true} shouldShrink={true}>
              <div style={{marginBottom: '.5rem'}}>
                <TruncateWithTooltip
                  linesAllowed={2}
                  horizontalOffset={isDesktop ? -150 : -10}
                  backgroundColor="primary"
                >
                  {/* @ts-expect-error */}
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
            {/* @ts-expect-error */}
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
            {/* @ts-expect-error */}
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

  // @ts-expect-error
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
        <Flex justifyItems="center">
          <Spinner renderTitle="Loading Page" role="alert" aria-busy="true" data-testid="loading" />
        </Flex>
      ) : (
        product && (
          <>
            {renderHeader()}
            {renderBylineAndUpdatedAt()}
            <Flex
              padding="small 0 0 small"
              margin={isDesktop ? '0 medium medium medium' : '0 medium medium 0'}
            >
              <Flex.Item margin={isDesktop ? '0 0 0 xx-large' : '0'}>{renderTags()}</Flex.Item>
            </Flex>
            {!isDesktop && renderConfigureButton()}
            <View
              as="div"
              width={130}
              margin="small 0 small 0"
              position="relative"
              withFocusOutline={!showTrucatedDescription}
            >
              <Heading level="h2" themeOverride={{h2FontWeight: 700}}>
                {I18n.t('Overview')}
              </Heading>
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
            <Flex direction="column">
              <Flex.Item width={'90%'} margin="0 small small 0">
                <TruncateText
                  maxLines={showTrucatedDescription ? 4 : 50}
                  truncate="word"
                  ellipsis=" (...)"
                  onUpdate={() => setIsTruncated(true)}
                >
                  <Text>{productDescription}</Text>
                </TruncateText>
              </Flex.Item>

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
              {product.screenshots.length > 0 && (
                <Flex.Item>
                  <IconButton
                    size="large"
                    themeOverride={{largeHeight: '5rem'}}
                    screenReaderLabel="View decorative image carousel"
                    onClick={() => {
                      imageModalClickHandler(product?.screenshots)
                    }}
                  >
                    <Img display="block" loading="lazy" src={product?.screenshots[0]}></Img>
                  </IconButton>
                  <div style={{position: 'relative', bottom: 30, zIndex: 10}}>
                    <ContextView
                      width={80}
                      padding="xxx-small"
                      textAlign="end"
                      placement="bottom"
                      themeOverride={{arrowSize: '0'}}
                    >
                      <Text size={product?.screenshots.length > 9 ? 'x-small' : 'small'}>
                        <IconImageLine /> {product?.screenshots.length} images
                      </Text>
                    </ContextView>
                  </div>
                </Flex.Item>
              )}
            </Flex>
            <ExternalLinks product={product} />
            <LtiConfigurationDetail
              badges={product.integration_badges}
              integrationData={relevantIntegration}
            />
            <Flex margin="medium 0 0 0">
              <Flex.Item margin="0 0 small 0">
                <Heading level="h2" themeOverride={{h2FontWeight: 700}}>
                  {I18n.t('Implementation Resources')}
                </Heading>
              </Flex.Item>
            </Flex>
            <Flex direction="column" margin="0 0 large 0">
              {hasIntegrationResources
                ? renderIntegrationResources()
                : I18n.t(
                    'The tool provider did not include implementation resources for this tool.',
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
      <ImageCarouselModal
        isModalOpen={isImageModalOpen}
        setModalOpen={setImageModalOpen}
        screenshots={imageModalScreenshots}
        // @ts-expect-error
        productName={product?.name}
      />
    </div>
  )
}

export default ProductDetail
