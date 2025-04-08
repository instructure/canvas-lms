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
import {List} from '@instructure/ui-list'
import type {Lti, Product} from '../../models/Product'

const I18n = createI18nScope('lti_registrations')
interface LtiConfigurationDetailProps {
  integrationData: Lti | undefined
  badges: Product["integration_badges"]
}

const LtiConfigurationDetail = (props: LtiConfigurationDetailProps) => {
  const {isMobile} = useBreakpoints()
  const description = I18n.t('Description')
  const placements = I18n.t('Placements')
  const services = I18n.t('Services')
  const emptyDescription = <Text>{I18n.t('There is no integration description for this tool')}</Text>
  const emptyPlacements = <List.Item>{I18n.t('There are no placements for this tool')}</List.Item>
  const emptyServices = <List.Item>{I18n.t('There are no services for this tool')}</List.Item>

  const renderPlacements = () => {
    return props.integrationData?.lti_placements.map((placement) => {
      return <List.Item key={placement}>{placement}</List.Item>
    })
  }

  const renderServices = () => {
    return props.integrationData?.lti_services.map((service) => {
      return <List.Item key={service}>{service}</List.Item>
    })
  }

  const placementsArray = renderPlacements() ?? []
  const servicesArray = renderServices() ?? []

  const renderDetails = () => {
    return (
      <div>
        <Flex>
          <Flex.Item margin="medium 0 small 0">
            <Heading level="h2" themeOverride={{h2FontWeight: 700}}>
              {I18n.t('Integration Details')}
            </Heading>
          </Flex.Item>
        </Flex>
        <Flex direction="column" width={isMobile ? '70%' : '90%'}>
          <Badges badges={props.badges[0]} />
          <Flex direction="column" margin="x-small 0 0 0">
            <Flex.Item margin="0 0 0 x-small">
              <Heading level="h4" as="h3">
                {description}
              </Heading>
            </Flex.Item>
            <Flex.Item margin="x-small 0 x-small x-small">
              {props.integrationData?.description.length === undefined ? emptyDescription : <div dangerouslySetInnerHTML={{__html: props.integrationData.description}} />}
            </Flex.Item>
          </Flex>
            <Flex.Item margin="x-small 0 0 x-small">
              <Heading level="h4" as="h3">
                {placements}
              </Heading>
            </Flex.Item>
            <List margin="x-small 0 small 0">
              {placementsArray.length === 0 ? emptyPlacements : renderPlacements()}
            </List>
            <Flex.Item margin="0 0 0 x-small">
              <Heading level="h4" as="h3">
                {services}
              </Heading>
            </Flex.Item>
            <List margin="x-small 0 x-small 0">
              {servicesArray.length === 0 ? emptyServices : renderServices()}
            </List>
        </Flex>
      </div>
    )
  }

  return <div>{renderDetails()}</div>
}

export default LtiConfigurationDetail
