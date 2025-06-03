/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {useScope as createI18nScope} from '@canvas/i18n'
import {Billboard} from '@instructure/ui-billboard'
import {Alert} from '@instructure/ui-alerts'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {List} from '@instructure/ui-list'
import {Flex} from '@instructure/ui-flex'
import EmptyDesert from '@canvas/images/react/EmptyDesert'
import getLiveRegion from '@canvas/instui-bindings/react/liveRegion'

const I18n = createI18nScope('files_v2')

interface NoResultsFoundProps {
  searchTerm: string
}

export const NoResultsFound = ({searchTerm}: NoResultsFoundProps) => {
  return (
    <>
      <Billboard
        size="medium"
        heading={I18n.t('No results found')}
        headingLevel="h3"
        message={I18n.t('We could not find anything that matches "%{searchTerm}" in files.', {
          searchTerm,
        })}
        hero={<EmptyDesert />}
      />
      <Flex as="div" direction="column" alignItems="center">
        <Flex.Item as="div" padding="0 0 0 small" textAlign="start" size="20rem">
          <Heading level="h4" margin="small">
            {I18n.t('Suggestions:')}
          </Heading>
          <List as="ul" margin="0 0 medium">
            <List.Item>
              <Text>{I18n.t('Check spelling')}</Text>
            </List.Item>
            <List.Item>
              <Text>{I18n.t('Try different keywords')}</Text>
            </List.Item>
            <List.Item>
              <Text>{I18n.t('Enter at least 3 letters in the search box')}</Text>
            </List.Item>
          </List>
        </Flex.Item>
      </Flex>
      <Alert
        liveRegion={getLiveRegion}
        liveRegionPoliteness="assertive"
        screenReaderOnly
        data-testid="search-announcement"
      >
        {I18n.t('No results found')}
      </Alert>
    </>
  )
}
