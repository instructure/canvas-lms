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

import React, {SyntheticEvent, useState} from 'react'
import {View} from '@instructure/ui-view'
import {Select} from '@instructure/ui-select'
import {Spinner} from '@instructure/ui-spinner'
import {Avatar} from '@instructure/ui-avatar'
import {Flex, FlexItem} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {useQuery} from '@canvas/query'
import useDebouncedSearchTerm from '@canvas/search-item-selector/react/hooks/useDebouncedSearchTerm'
import {useScope} from '@canvas/i18n'

import {ResponseSection, fetchSections} from './api'

const I18n = useScope('roster_section_input')

type SectionInputProps = {
  onSelect: (section: ResponseSection) => void
  courseId: number
  exclude: string[]
}

function renderSectionOption(section: ResponseSection, isHighlighted: boolean) {
  return (
    <Select.Option
      key={section.id}
      id={section.id}
      value={section.id}
      isHighlighted={isHighlighted}
    >
      <Flex gap="small">
        <Flex.Item>
          <Avatar name={section.name} src={section.avatar_url} size="small" />
        </Flex.Item>
        <FlexItem>
          <Flex direction="column">
            <FlexItem>{section.name}</FlexItem>
            <FlexItem>
              <Text size="small">{I18n.t('%{count} people', {count: section.user_count})}</Text>
            </FlexItem>
          </Flex>
        </FlexItem>
      </Flex>
    </Select.Option>
  )
}

const SectionInput: React.FC<SectionInputProps> = ({onSelect, courseId, exclude}) => {
  const [inputValue, setInputValue] = useState('')
  const [showOptions, setShowOptions] = useState(false)
  const [highlightedSectionId, setHighlightedSectionId] = useState('')
  const {searchTerm, setSearchTerm, searchTermIsPending} = useDebouncedSearchTerm('', {
    timeout: 500,
  })
  const {data, isLoading} = useQuery({
    queryKey: ['course_sections', {courseId, searchTerm, exclude}],
    queryFn: fetchSections,
    enabled: showOptions,
  })

  const handleOnSelect = (e: SyntheticEvent<Element, Event>, {id}: {id?: string}) => {
    setSearchTerm('')
    setInputValue('')
    setShowOptions(false)

    const selectedSection = data?.find(section => section.id === id)

    if (selectedSection) {
      onSelect(selectedSection)
    }
  }

  const showSpinner = isLoading || searchTermIsPending

  return (
    <View>
      <Select
        renderLabel=""
        isShowingOptions={showOptions}
        onInputChange={e => {
          setSearchTerm(e.target.value)
          setInputValue(e.target.value)
          setShowOptions(true)
        }}
        inputValue={inputValue}
        onRequestSelectOption={handleOnSelect}
        onRequestShowOptions={() => setShowOptions(true)}
        onRequestHideOptions={() => setShowOptions(false)}
        onRequestHighlightOption={(event, {id}) => setHighlightedSectionId(id || '')}
        placeholder={I18n.t('Enter a section name')}
      >
        {showSpinner && (
          <Select.Option id="loading">
            <Flex justifyItems="center">
              <FlexItem>
                <Spinner renderTitle={I18n.t('Loading sections')} />
              </FlexItem>
            </Flex>
          </Select.Option>
        )}
        {!showSpinner && data?.length === 0 && (
          <Select.Option id="not found">{I18n.t('No results found')}</Select.Option>
        )}
        {!showSpinner &&
          data?.map(section => renderSectionOption(section, highlightedSectionId === section.id))}
      </Select>
    </View>
  )
}

export default SectionInput
