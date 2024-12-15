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
import React from 'react'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {IconExternalLinkLine} from '@instructure/ui-icons'
import type {Product} from '../../models/Product'

const I18n = createI18nScope('lti_registrations')

interface ExternalLinksProps {
  product: Product
}

const ExternalLinks = (props: ExternalLinksProps) => {
  const {product} = props

  return (
    <div>
      <Flex direction="column" gap="medium">
        <Flex direction="column">
          <Flex.Item margin="0 0 small 0">
            <Text weight="bold" size="x-large">
              {I18n.t('Privacy')}
            </Text>
          </Flex.Item>
          {product.privacy_policy_url ? (
            <Flex direction="column">
              <Flex.Item>
                <Link href={product.privacy_policy_url} isWithinText={false}>
                  <Text weight="bold">
                    {I18n.t('Partner Privacy Policy')} <IconExternalLinkLine />
                  </Text>
                </Link>
              </Flex.Item>
            </Flex>
          ) : (
            <Flex.Item>
              {I18n.t('The privacy information for this provider is not currently available.')}
            </Flex.Item>
          )}
        </Flex>
        <Flex direction="column">
          <Flex.Item margin="0 0 small 0">
            <Text weight="bold" size="x-large">
              {I18n.t('Terms of Service')}
            </Text>
          </Flex.Item>
          {product.terms_of_service_url ? (
            <Flex direction="column">
              <Flex.Item>
                <Link href={product.terms_of_service_url} isWithinText={false}>
                  <Text weight="bold">
                    {I18n.t('Terms of Service')} <IconExternalLinkLine />
                  </Text>
                </Link>
              </Flex.Item>
            </Flex>
          ) : (
            <Flex.Item>
              {I18n.t(
                'The terms of service documentation for this provider is not currently available.'
              )}
            </Flex.Item>
          )}
        </Flex>
        <Flex direction="column">
          <Flex.Item margin="0 0 small 0">
            <Text weight="bold" size="x-large">
              {I18n.t('Accessibility')}
            </Text>
          </Flex.Item>
          {product.accessibility_url ? (
            <Flex direction="column">
              <Flex.Item>
                <Link href={product.accessibility_url} isWithinText={false}>
                  <Text weight="bold">
                    {I18n.t('Accessibility Documentation')} <IconExternalLinkLine />
                  </Text>
                </Link>
              </Flex.Item>
            </Flex>
          ) : (
            <Flex.Item>
              {I18n.t(
                'The accessibility documentation for this provider is not currently available.'
              )}
            </Flex.Item>
          )}
        </Flex>
      </Flex>
    </div>
  )
}

export default ExternalLinks
