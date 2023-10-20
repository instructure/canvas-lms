/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import PropTypes from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import {IconArrowOpenEndSolid} from '@instructure/ui-icons'
import {addZeroWidthSpace} from '@canvas/outcomes/addZeroWidthSpace'

const I18n = useI18nScope('OutcomeManagement')

const SearchBreadcrumb = ({groupTitle, searchString, loading}) => (
  <Heading level="h3">
    {searchString ? (
      <Flex>
        <Flex.Item shouldShrink={true}>
          <Flex>
            <Flex.Item>
              <bdi>{groupTitle}</bdi>
            </Flex.Item>
            <Flex.Item>
              <div
                style={{
                  display: 'inline-block',
                  transform: 'scale(0.6)',
                  height: '1em',
                }}
              >
                <IconArrowOpenEndSolid title={I18n.t('search results for')} />
              </div>
            </Flex.Item>
            <Flex.Item shouldShrink={true}>
              <div
                style={{
                  whiteSpace: 'nowrap',
                  overflow: 'hidden',
                  textOverflow: 'ellipsis',
                  padding: '0.375rem 0',
                }}
              >
                <bdi>{searchString}</bdi>
              </div>
            </Flex.Item>
          </Flex>
        </Flex.Item>
        <Flex.Item size="2.5rem">
          {loading && (
            <Spinner
              renderTitle={I18n.t('Loading')}
              size="x-small"
              margin="0 0 0 x-small"
              data-testid="search-loading"
            />
          )}
        </Flex.Item>
      </Flex>
    ) : (
      <View as="div" padding="x-small medium x-small 0">
        <Text wrap="break-word" size="medium" weight="bold">
          {I18n.t('All %{groupTitle} Outcomes', {
            groupTitle: addZeroWidthSpace(groupTitle),
          })}
        </Text>
      </View>
    )}
  </Heading>
)

SearchBreadcrumb.defaultProps = {
  searchString: '',
}

SearchBreadcrumb.propTypes = {
  groupTitle: PropTypes.string.isRequired,
  searchString: PropTypes.string,
  loading: PropTypes.bool.isRequired,
}

export default SearchBreadcrumb
