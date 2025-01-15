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
import {Heading} from '@instructure/ui-heading'
import {List} from '@instructure/ui-list'
import type {LtiDetailProps} from '../../models/Product'

const I18n = createI18nScope('lti_registrations')
interface LtiConfigurationDetailProps {
  integrationData: LtiDetailProps | undefined
}

const LtiConfigurationDetail = (props: LtiConfigurationDetailProps) => {
  const placements = I18n.t('Placements')
  const services = I18n.t('Services')
  const emptyPlacements = <List.Item>{I18n.t('There are no placements for this tool')}</List.Item>
  const emptyServices = <List.Item>{I18n.t('There are no services for this tool')}</List.Item>

  const renderPlacements = () => {
    return props.integrationData?.placements.map(placement => {
      return <List.Item>{placement}</List.Item>
    })
  }

  const renderServices = () => {
    return props.integrationData?.services.map(service => {
      return <List.Item>{service}</List.Item>
    })
  }
  const placementsArray = renderPlacements() ?? []
  const servicesArray = renderServices() ?? []

  const renderDetails = () => {
    return (
      <div>
        <Flex>
          <Flex.Item margin="medium 0 0 0">
            <Heading level="h2" themeOverride={{h2FontWeight: 700}}>
              {I18n.t('Integration Details')}
            </Heading>
          </Flex.Item>
        </Flex>
        <Flex direction="column">
          <div>
            <Flex.Item margin="0 0 0 x-small">
              <Heading level="h4" as="h3">
                {placements}
              </Heading>
            </Flex.Item>
            <List margin="x-small 0 0 0">
              {placementsArray.length === 0 ? emptyPlacements : renderPlacements()}
            </List>
          </div>
          <div>
            <Flex.Item margin="0 0 0 x-small">
              <Heading level="h4" as="h3">
                {services}
              </Heading>
            </Flex.Item>
            <List margin="x-small 0 small 0">
              {servicesArray.length === 0 ? emptyServices : renderServices()}
            </List>
          </div>
        </Flex>
      </div>
    )
  }

  return <div>{renderDetails()}</div>
}

export default LtiConfigurationDetail
