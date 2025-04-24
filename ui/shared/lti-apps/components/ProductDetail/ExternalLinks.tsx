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
import useBreakpoints from '@canvas/lti-apps/hooks/useBreakpoints'
import Badges from './Badges'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
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
  const {isMobile} = useBreakpoints()

  return (
    <div>
      <Flex direction="column" gap="medium">
        <Flex direction="column" width={isMobile ? '70%' : '90%'}>
          <Flex.Item margin="0 0 medium 0">
            <Heading level="h2" themeOverride={{h2FontWeight: 700}}>
              {I18n.t('Privacy')}
            </Heading>
          </Flex.Item>
          {product.privacy_policy_url ? (
            <Flex
              margin={product.privacy_and_security_badges.length > 0 ? '0 0 large 0' : '0 0 0 0'}
            >
              <Flex.Item>
                <Link href={product.privacy_policy_url} isWithinText={false} target="_blank">
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
          <Badges badges={product.privacy_and_security_badges[0]} />
        </Flex>
        <Flex direction="column">
          <Flex.Item margin="0 0 small 0">
            <Heading level="h2" themeOverride={{h2FontWeight: 700}}>
              {I18n.t('Terms of Service')}
            </Heading>
          </Flex.Item>
          {product.terms_of_service_url ? (
            <Flex direction="column">
              <Flex.Item>
                <Link href={product.terms_of_service_url} isWithinText={false} target="_blank">
                  <Text weight="bold">
                    {I18n.t('Terms of Service')} <IconExternalLinkLine />
                  </Text>
                </Link>
              </Flex.Item>
            </Flex>
          ) : (
            <Flex.Item margin={product.privacy_and_security_badges.length > 0 ? '0 0 large 0' : '0 0 0 0'}>
              {I18n.t(
                'The terms of service documentation for this provider is not currently available.',
              )}
            </Flex.Item>
          )}
        </Flex>
        <Flex direction="column" width={isMobile ? '70%' : '90%'}>
          <Flex.Item margin="0 0 small 0">
            <Heading level="h2" themeOverride={{h2FontWeight: 700}}>
              {I18n.t('Accessibility')}
            </Heading>
          </Flex.Item>
          {product.accessibility_url ? (
            <Flex
              direction="column"
              margin={product.accessibility_badges.length > 0 ? '0 0 large 0' : '0 0 0 0'}
            >
              <Flex.Item>
                <Link href={product.accessibility_url} isWithinText={false} target="_blank">
                  <Text weight="bold">
                    {I18n.t('Accessibility Documentation')} <IconExternalLinkLine />
                  </Text>
                </Link>
              </Flex.Item>
            </Flex>
          ) : (
            <Flex.Item margin={product.accessibility_badges.length > 0 ? '0 0 large 0' : '0 0 0 0'}>
              {I18n.t(
                'The accessibility documentation for this provider is not currently available.',
              )}
            </Flex.Item>
          )}
          <Badges badges={product.accessibility_badges[0]} />
        </Flex>
      </Flex>
    </div>
  )
}

export default ExternalLinks
