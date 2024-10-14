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

import {useScope as useI18nScope} from '@canvas/i18n'
import React, {useState} from 'react'
import {useLocation, useNavigate} from 'react-router-dom'
import useProduct from './queries/useProduct'
import useSimilarProducts from './queries/useSimilarProducts'
import {Breadcrumb} from '@instructure/ui-breadcrumb'
import {Spinner} from '@instructure/ui-spinner'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {Tag} from '@instructure/ui-tag'
import {View} from '@instructure/ui-view'
import {Button} from '@instructure/ui-buttons'
import GenericErrorPage from '@canvas/generic-error-page/react'
import TruncateWithTooltip from '@canvas/lti-apps/components/common/TruncateWithTooltip'
import {
  IconA11yLine,
  IconExternalLinkLine,
  IconExpandStartLine,
  IconEyeLine,
  IconMessageLine,
  IconQuizTitleLine,
} from '@instructure/ui-icons'
import LtiDetailModal from './LtiDetailModal'
import IntegrationDetailModal from './IntegrationDetailModal'
import ProductCarousel from '../common/Carousels/ProductCarousel'
import ImageCarousel from '../common/Carousels/ImageCarousel'
import BadgeCarousel from '../common/Carousels/BadgeCarousel'
import Disclaimer from '@canvas/lti-apps/components/common/Disclaimer'

import type {Product} from '@canvas/lti-apps/models/Product'

import {openDynamicRegistrationWizard} from '../../../manage/registration_wizard/RegistrationWizardModalState'

const I18n = useI18nScope('lti_registrations')

const ProductDetail = () => {
  const [isModalOpen, setModalOpen] = useState(false)
  const [clickedLtiTitle, setClickedLtiTitle] = useState('')
  const [isIntDetailModalOpen, setIntDetailModalOpen] = useState(false)
  const [intDetailTitle, setIntDetailTitle] = useState('')
  const [intDetailContent, setIntDetailContent] = useState('')

  const navigate = useNavigate()
  const location = useLocation()

  const currentProductId = location.pathname.replace('/product_detail/', '')
  const previousPath = window.location.pathname.replace(/\product_detail.*/, '')

  const {product, isLoading, isError} = useProduct({productId: currentProductId})

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

  const renderTags = () => {
    return product?.tags.map((t, i) => (
      <Tag text={t.name} margin="0 x-small 0 0" key={`${i + 1}`} />
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

    return version.map((title, i) => (
      <Flex.Item margin="0 0 small 0" key={`${i + 1}`}>
        <Link onClick={() => ltiDataClickHandle(title)} isWithinText={false}>
          <Text weight="bold">{title}</Text>
        </Link>
      </Flex.Item>
    ))
  }

  const formattedUpdatedAt = () => {
    const date = new Date(product?.updated_at as string)
    return date.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    })
  }

  const dynamicRegistrationInformation = product?.tool_integration_configurations?.lti_13?.find(
    configuration => configuration.integration_type === 'lti_13_dynamic_registration'
  )

  const intDetailClickHandler = (title: string, content: string) => {
    setIntDetailModalOpen(true)
    setIntDetailTitle(title)
    setIntDetailContent(content)
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
          <Flex.Item margin="0 0 large 0" key={`${i + 1}`}>
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
            <Flex margin="small 0 0 0">
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
              <Flex.Item shouldGrow={true} shouldShrink={true} padding="small 0 0 small">
                <Text weight="bold" size="x-large">
                  {product.name}
                </Text>
                <Flex.Item shouldGrow={true} shouldShrink={true}>
                  <div style={{marginBottom: '.5rem'}}>
                    <TruncateWithTooltip
                      linesAllowed={2}
                      horizontalOffset={-150}
                      backgroundColor="primary"
                    >
                      <Text>{product.tagline}</Text>
                    </TruncateWithTooltip>
                  </div>
                </Flex.Item>
              </Flex.Item>
              <Flex.Item align="start" margin="small 0 0 0">
                <Button
                  color="primary"
                  interaction={dynamicRegistrationInformation ? 'enabled' : 'disabled'}
                  onClick={() => {
                    if (!dynamicRegistrationInformation) return null

                    openDynamicRegistrationWizard(
                      dynamicRegistrationInformation.url,
                      // @ts-ignore
                      dynamicRegistrationInformation.unified_tool_id,
                      () => {
                        // redirect to apps page
                        navigate('/manage')
                      }
                    )
                  }}
                >
                  {I18n.t('Configure')}
                </Button>
              </Flex.Item>
            </Flex>
            <Flex margin="0 0 0 xx-large">
              <Flex.Item padding="0 0 0 x-small" margin="0 0 0 medium">
                <Text color="secondary">
                  {I18n.t('by')} {product.company.name}
                </Text>{' '}
                |{' '}
                <Text color="secondary">
                  {I18n.t('Updated')}: {formattedUpdatedAt()}
                </Text>
              </Flex.Item>
            </Flex>
            <Flex padding="small 0 0 small" margin="0 medium large xx-large">
              <Flex.Item margin="0 0 0 small">{renderTags()}</Flex.Item>
            </Flex>
            <ImageCarousel screenshots={product.screenshots} />
            <Flex margin="medium 0 0 0">
              <Flex.Item>
                <Text weight="bold" size="large">
                  {I18n.t('Overview')}
                </Text>
              </Flex.Item>
            </Flex>
            <Flex>
              <Flex.Item margin="small 0 small 0">
                <Text dangerouslySetInnerHTML={{__html: product.description}} />
              </Flex.Item>
            </Flex>
            <Flex>
              <Flex.Item margin="medium 0 small 0">
                <Text weight="bold" size="large">
                  {I18n.t('External Links')}
                </Text>
              </Flex.Item>
            </Flex>
            <Flex>
              {product.company.company_url && (
                <Flex.Item margin="0 large 0 0">
                  <Link
                    href={product.company.company_url}
                    isWithinText={false}
                    renderIcon={<IconExpandStartLine />}
                  >
                    <Text weight="bold">{I18n.t('Website')}</Text>
                  </Link>
                </Flex.Item>
              )}
              {product.privacy_policy_url && (
                <Flex.Item>
                  <Link
                    href={product.privacy_policy_url}
                    isWithinText={false}
                    renderIcon={<IconEyeLine />}
                  >
                    <Text weight="bold">{I18n.t('Privacy Policy')}</Text>
                  </Link>
                </Flex.Item>
              )}
              {product.terms_of_service_url && (
                <Flex.Item margin="0 0 0 large">
                  <Link
                    href={product.terms_of_service_url}
                    isWithinText={false}
                    renderIcon={<IconQuizTitleLine />}
                  >
                    <Text weight="bold">{I18n.t('Terms of Service')}</Text>
                  </Link>
                </Flex.Item>
              )}
              {product.accessibility_url && (
                <Flex.Item margin="0 0 0 large">
                  <Link
                    href={product.accessibility_url}
                    isWithinText={false}
                    renderIcon={<IconA11yLine />}
                  >
                    <Text weight="bold">{I18n.t('Accessibility')}</Text>
                  </Link>
                </Flex.Item>
              )}
              {product.support_link && (
                <Flex.Item margin="0 0 0 large">
                  <Link
                    href={product.support_link}
                    isWithinText={false}
                    renderIcon={<IconMessageLine />}
                  >
                    <Text weight="bold">{I18n.t('Contact')}</Text>
                  </Link>
                </Flex.Item>
              )}
            </Flex>
            <Flex>
              <Flex.Item margin="medium 0 small 0">
                <Text weight="bold" size="large">
                  {I18n.t('Resources and Documents')}
                </Text>
              </Flex.Item>
            </Flex>
            <Text weight="bold" size="medium">
              {I18n.t('Integrations')}
            </Text>
            <Flex direction="column" margin="small 0 0 0">
              {renderLtiTitle()}
            </Flex>
            {product.badges.length > 0 && <BadgeCarousel badges={product?.badges} />}
            {(excludeCurrentProduct?.length ?? 0) > 0 && (
              <ProductCarousel
                products={excludeCurrentProduct ?? []}
                companyName={product.company.name}
              />
            )}

            {hasIntegrationResources && (
              <>
                <Flex>
                  <Flex.Item margin="medium 0 0 0">
                    <Text weight="bold" size="x-large">
                      {I18n.t('Implementation Resources')}
                    </Text>
                  </Flex.Item>
                </Flex>
                <Flex direction="column">{renderIntegrationResources()}</Flex>
              </>
            )}
            <div style={{marginTop: '35px'}}>
              <Disclaimer />
            </div>
          </>
        )
      )}
      <LtiDetailModal
        ltiTitle={clickedLtiTitle}
        integrationData={product?.lti_configurations}
        isModalOpen={isModalOpen}
        setModalOpen={setModalOpen}
      />
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
