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
import type {Result} from './types'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import ResultCard from './ResultCard'
import Feedback from './Feedback'
import {Link} from '@instructure/ui-link'

const I18n = createI18nScope('SmartSearch')

interface Props {
  results: Result[]
  courseId: string
  searchTerm: string
  resetSearch: () => void
}

export default function BestResults(props: Props) {
  const startOverMsg = I18n.t('Try a similar result below or %{startover_btn}', {
    startover_btn: 'ZZZZ_STARTOVER',
  })
  const splitTranslated = startOverMsg.split('ZZZZ_STARTOVER')
  return (
    <Flex
      direction="column"
      gap={props.results.length > 0 ? 'sectionElements' : 'space0'}
      width="100%"
    >
      <Flex direction="row-reverse" alignItems="start" width="100%">
        <Flex.Item>
          <Feedback courseId={props.courseId} searchTerm={props.searchTerm} />
        </Flex.Item>
        <Flex.Item shouldGrow shouldShrink>
          <Heading variant="titleSection" level="h2">
            {I18n.t(
              {
                zero: 'No results',
                one: '1 result',
                other: '%{count} results',
              },
              {count: props.results.length},
            )}
          </Heading>
        </Flex.Item>
      </Flex>
      {props.results.length < 1 && (
        <Flex.Item>
          <Text>
            {splitTranslated[0]}
            <Link as="button" onClick={props.resetSearch}>
              {I18n.t('start over')}
            </Link>
            {splitTranslated[1]}
          </Text>
        </Flex.Item>
      )}
      {props.results.map(result => {
        return (
          <ResultCard
            key={`${result.content_id}-${result.content_type}`}
            result={result}
            resultType="best"
            searchTerm={props.searchTerm}
          />
        )
      })}
    </Flex>
  )
}
