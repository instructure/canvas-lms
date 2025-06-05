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
import type {Result} from '../types'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import ResultCard from './ResultCard'
import Feedback from './Feedback'

const I18n = createI18nScope('SmartSearch')

interface Props {
  results: Result[]
  courseId: string
  searchTerm: string
}

export default function BestResults(props: Props) {
  if (props.results.length === 0) {
    return (
      <>
        <Flex direction="row" alignItems="start">
          <Flex.Item shouldGrow>
            <Heading level="h2">
              {I18n.t('No best matches for "%{searchTerm}"', {searchTerm: props.searchTerm})}
            </Heading>
            {/* TODO: determine what start over should do here*/}
            <Text>{I18n.t('Try a similar result below or start over.')}</Text>
          </Flex.Item>
          <Flex.Item>
            <Feedback courseId={props.courseId} searchTerm={props.searchTerm} />
          </Flex.Item>
        </Flex>
      </>
    )
  }
  return (
    <>
      <Flex direction="row" alignItems="start">
        <Flex.Item shouldGrow>
          <Heading level="h2">{I18n.t('Best Matches')}</Heading>
          <Text>
            {I18n.t(
              {one: '1 result for "%{searchTerm}"', other: '%{count} results for "%{searchTerm}"'},
              {count: props.results.length, searchTerm: props.searchTerm},
            )}
          </Text>
        </Flex.Item>
        <Flex.Item>
          <Feedback courseId={props.courseId} searchTerm={props.searchTerm} />
        </Flex.Item>
      </Flex>
      <Flex direction="column" gap="medium">
        {props.results.map(result => {
          return (
            <ResultCard
              key={`${result.content_id}-${result.content_type}`}
              result={result}
              searchTerm={props.searchTerm}
            />
          )
        })}
      </Flex>
    </>
  )
}
