/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {useCallback, useEffect, useState} from 'react'
import {debounce} from '@instructure/debounce'
import {CondensedButton, IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconSearchLine, IconTroubleLine, IconTrashLine} from '@instructure/ui-icons'
import {Link} from '@instructure/ui-link'
import {Tag} from '@instructure/ui-tag'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import {TruncateText} from '@instructure/ui-truncate-text'
import {View} from '@instructure/ui-view'
import useFetchApi from '@canvas/use-fetch-api-hook'
// import useDebouncedSearchTerm from '@canvas/search-item-selector/react/hooks/useDebouncedSearchTerm'
import type {CanvasRequirementType, CanvasRequirementSearchResultType} from '../../../../types'
import {CanvasRequirementTypes} from '../../../../types'
import {pluralize} from '../../../../shared/utils'

const MIN_SEARCH_TERM_LENGTH = 3
const SEARCH_DEBOUNCE_MS = 750
type RenderedResultVariant = 'search' | 'selected'

type CanvasRequirementProps = {
  type: CanvasRequirementType
  onChange: (requirements?: CanvasRequirementSearchResultType) => void
}
const CanvasRequirement = ({type, onChange}: CanvasRequirementProps) => {
  const [searchTerm, setSearchTerm] = useState<string>('')
  const [debouncedSearchterm, setDebouncedSearchTerm] = useState<string>('')
  const [searchResults, setSearchResults] = useState<CanvasRequirementSearchResultType[] | null>(
    null
  )
  const [selectedResult, setSelectedResult] = useState<
    CanvasRequirementSearchResultType | undefined
  >()

  // this will fetch when the component is first mounted, but
  // the controller will return immediately a 400 since debouncedSearchterm is empty
  useFetchApi(
    {
      path: `/users/${ENV.current_user.id}/passport/data/pathways/canvas_requirements`,
      success: useCallback((results: CanvasRequirementSearchResultType[]) => {
        if (results === undefined) {
          // there is no way to keep useFetchApi from firing when dependencies
          // aren't adequate for the search. This is probably the 204 response
          // the controller returns in the case of zero length search term
          setSearchResults(null)
        } else {
          setSearchResults(results || [])
        }
      }, []),
      params: {search_string: debouncedSearchterm, type},
      error: useCallback(() => {
        setSearchResults(null)
      }, []),
      loading: undefined,
      meta: undefined,
      convert: undefined,
      forceResult: undefined,
    },
    [debouncedSearchterm, type]
  )

  useEffect(() => {
    setDebouncedSearchTerm('')
    setSearchTerm('')
    setSearchResults(null)
  }, [type])

  const deferSetDebouncedSearchTerm = useCallback(
    debounce(
      (value: string) => {
        if (value.length < MIN_SEARCH_TERM_LENGTH) return
        setDebouncedSearchTerm(value)
      },
      SEARCH_DEBOUNCE_MS,
      {leading: false, trailing: true}
    ),
    []
  )

  const handleChangeSearchValue = useCallback(
    (_event, value) => {
      setSearchTerm(value)
      deferSetDebouncedSearchTerm(value)
    },
    [deferSetDebouncedSearchTerm]
  )

  const clearSearch = useCallback(() => {
    // search.cancel()
    setSearchTerm('')
    setSearchResults(null)
  }, [])

  const handleAddRequirement = useCallback(
    (newSelection: CanvasRequirementSearchResultType) => {
      setSelectedResult(newSelection)
      onChange(newSelection)
    },
    [onChange]
  )

  const handleRemoveRequirement = useCallback(() => {
    setSelectedResult(undefined)
    onChange(undefined)
  }, [onChange])

  const renderOneResult = (
    result: CanvasRequirementSearchResultType,
    variant: RenderedResultVariant
  ) => {
    return (
      <View
        key={result.id}
        as="div"
        background={variant === 'search' ? 'primary' : 'secondary'}
        margin="small 0"
        padding={variant === 'search' ? 'none' : 'small x-small small small'}
        borderRadius="medium"
        borderWidth={variant === 'search' ? 'none' : 'small'}
      >
        <Flex as="div" key={result.id} justifyItems="space-between" gap="x-small">
          <Flex.Item shouldGrow={true}>
            <Link href={result.url}>
              <Text size="small" lineHeight="fit">
                <TruncateText>{result.name}</TruncateText>
              </Text>
            </Link>
          </Flex.Item>
          {result.learning_outcome_count > 0 && (
            <Tag
              themeOverride={variant === 'search' ? undefined : {defaultBackground: 'white'}}
              text={`${result.learning_outcome_count} ${pluralize(
                result.learning_outcome_count,
                'outcome',
                'outcomes'
              )}`}
            />
          )}
          {variant === 'search' ? (
            <CondensedButton size="small" onClick={() => handleAddRequirement(result)}>
              Add
            </CondensedButton>
          ) : (
            <IconButton
              screenReaderLabel="remove"
              withBorder={false}
              withBackground={false}
              onClick={() => handleRemoveRequirement()}
            >
              <IconTrashLine size="x-small" color="secondary" />
            </IconButton>
          )}
        </Flex>
      </View>
    )
  }

  const renderSearchResults = () => {
    if (searchResults === null) return null

    const workingSearchResults = searchResults.filter(r => {
      return r.id !== selectedResult?.id
    })

    if (workingSearchResults.length === 0) {
      return (
        <View as="div" margin="small 0 0 0">
          <Text size="small" lineHeight="fit">
            {searchResults.length === 0 ? 'No results found' : 'No results remain'}
          </Text>
        </View>
      )
    }

    return (
      <View as="div" margin="small 0 0 0">
        <Text size="small" weight="bold" lineHeight="fit">
          {pluralize(
            workingSearchResults.length,
            `1 search result for Canvas ${CanvasRequirementTypes[type]}`,
            `${workingSearchResults.length} search results for Canvas ${CanvasRequirementTypes[type]}`
          )}
        </Text>
        {workingSearchResults.map((result: CanvasRequirementSearchResultType) =>
          renderOneResult(result, 'search')
        )}
      </View>
    )
  }

  return (
    <View as="div" margin="medium 0 0 0">
      {selectedResult ? (
        <View as="div" margin="medium 0 0 0">
          {renderOneResult(selectedResult, 'selected')}
        </View>
      ) : null}
      <TextInput
        renderLabel={
          <>
            <View as="div" margin="0 0 xx-small 0">
              <Text weight="bold">Link to Canvas content</Text>
            </View>
            <Text size="small" weight="normal">
              {`Add an existing ${type} to this requirement`}
            </Text>
          </>
        }
        placeholder={`Search for Canvas ${CanvasRequirementTypes[type]}`}
        renderBeforeInput={<IconSearchLine />}
        renderAfterInput={
          <IconButton
            screenReaderLabel="clear"
            withBorder={false}
            withBackground={false}
            onClick={clearSearch}
          >
            <IconTroubleLine size="x-small" color="secondary" />
          </IconButton>
        }
        value={searchTerm}
        onChange={handleChangeSearchValue}
      />
      {renderSearchResults()}
    </View>
  )
}

export default CanvasRequirement
