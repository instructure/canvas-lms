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

import {Flex} from '@instructure/ui-flex'
import type {Result} from '../types'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import ResultCard from './ResultCard'
import {Heading} from '@instructure/ui-heading'

const I18n = createI18nScope('SmartSearch')

interface Props {
  results: Result[]
  searchTerm: string
}

export default function SimilarResults(props: Props) {
  if (props.results.length === 0) {
    return null
  }
  return (
    <Flex gap="small" direction="column">
      <Flex.Item>
        <Heading variant="titleSection">{I18n.t('Similar Results')}</Heading>
        <Text>
          {I18n.t(
            'While not a direct match, these results could still provide useful information.',
          )}
        </Text>
      </Flex.Item>
      {props.results.map((result, index) => (
        <ResultCard key={index} result={result} searchTerm={props.searchTerm} />
      ))}
    </Flex>
  )
}
