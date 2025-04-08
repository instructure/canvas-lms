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

import {Heading} from '@instructure/ui-heading'
import {Result} from '../types'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import ResultCard from './ResultCard'

const I18n = createI18nScope('SmartSearch')

interface Props {
  results: Result[]
  searchTerm: string
}

export default function BestResults(props: Props) {
  // TODO: add feedback modal to the header of best matches
  if (props.results.length === 0) {
    return (
      <>
        <Heading level="h2">
          {I18n.t('No best matches for "%{searchTerm}"', {searchTerm: props.searchTerm})}
        </Heading>
        <Flex direction="column" gap="small">
          {/* TODO: determine what start over should do here*/}
          <Text>{I18n.t('Try a similar result below or start over.')}</Text>
        </Flex>
      </>
    )
  }
  return (
    <>
      <Flex direction="column" gap="small">
        <Flex.Item>
          <Heading level="h2">{I18n.t('Best Matches')}</Heading>
          <Text>
            {I18n.t(
              {one: '1 result for "%{searchTerm}"', other: '%{count} results for "%{searchTerm}"'},
              {count: props.results.length, searchTerm: props.searchTerm},
            )}
          </Text>
        </Flex.Item>
        {props.results.map(result => {
          return (
            <ResultCard key={result.content_id} result={result} searchTerm={props.searchTerm} />
          )
        })}
      </Flex>
    </>
  )
}
