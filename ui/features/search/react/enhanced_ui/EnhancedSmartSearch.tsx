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

import {useRef, useState} from 'react'
import SmartSearchHeader from './SmartSearchHeader'
import type {IndexProgress, Result} from '../types'
import BestResults from './BestResults'
import SimilarResults from './SimilarResults'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as createI18nScope} from '@canvas/i18n'
import IndexingProgress from '../IndexingProgress'
import {Alert} from '@instructure/ui-alerts'

const RELEVANCE_THRESHOLD = 0.5
const MAX_NUMBER_OF_RESULTS = 25

const I18n = createI18nScope('SmartSearch')

interface Props {
  courseId: string
}

export default function EnhancedSmartSearch(props: Props) {
  const previousSearch = useRef('')
  const [searchResults, setSearchResults] = useState<Result[]>([])
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState('')
  const [indexingProgress, setIndexingProgress] = useState<IndexProgress | null>(null)

  const renderResults = () => {
    if (error) {
      return <Alert variant="error">{error}</Alert>
    } else if (isLoading) {
      return (
        <Flex justifyItems="center">
          <Spinner renderTitle={I18n.t('Searching')} />
        </Flex>
      )
    } else if (searchResults == null) {
      return <Alert variant="error">{I18n.t('Failed to execute search')}</Alert>
    } else if (indexingProgress !== null) {
      return <IndexingProgress progress={indexingProgress?.progress} />
    } else if (previousSearch.current === '' && searchResults.length === 0) {
      // no search has been performed yet
      return null
    } else {
      // only grab the first 25 results, then split into best and similar
      const results =
        searchResults.length > MAX_NUMBER_OF_RESULTS
          ? searchResults.slice(0, MAX_NUMBER_OF_RESULTS)
          : searchResults
      const bestResults = results.filter(result => result.relevance >= RELEVANCE_THRESHOLD)
      const similarResults = results.filter(result => result.relevance < RELEVANCE_THRESHOLD)
      return (
        <>
          <BestResults
            searchTerm={previousSearch.current}
            results={bestResults}
            courseId={props.courseId}
          />
          <SimilarResults searchTerm={previousSearch.current} results={similarResults} />
        </>
      )
    }
  }

  return (
    <Flex direction="column" gap="medium">
      <SmartSearchHeader
        onSearch={query => {
          previousSearch.current = query
          setIsLoading(true)
        }}
        onSuccess={results => {
          setSearchResults(results)
          setIsLoading(false)
        }}
        onError={error => {
          setError(error)
          setIsLoading(false)
        }}
        onIndexingProgress={progress => {
          setIndexingProgress(progress)
        }}
        courseId={props.courseId}
        isLoading={isLoading || indexingProgress !== null}
      />
      {renderResults()}
    </Flex>
  )
}
