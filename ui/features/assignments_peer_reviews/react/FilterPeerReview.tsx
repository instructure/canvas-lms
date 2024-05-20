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

import React, {useState, useEffect} from 'react'
import {TextInput} from '@instructure/ui-text-input'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Flex} from '@instructure/ui-flex'
import {Button} from '@instructure/ui-buttons'

export default () => {
  const [searchTerm, setSearchTerm] = useState('')
  const [selectedOption, setSelectedOption] = useState('')

  useEffect(() => {
    const queryParams = new URLSearchParams(window.location.search)
    const getSelectedOption = queryParams.get('selected_option')
    const getSearchTerm = queryParams.get('search_term')
    const searchTerm = getSearchTerm != null ? getSearchTerm : ''
    const selectedOption =
      getSelectedOption != null && getSearchTerm != null ? getSelectedOption : 'all'
    setSelectedOption(selectedOption)
    setSearchTerm(searchTerm)
  }, [])

  const submitChange = () => {
    const queryParams = new URLSearchParams({
      selected_option: selectedOption,
    })

    if (searchTerm.trim() !== '') {
      queryParams.append('search_term', searchTerm)
    }

    const peerReviewUrl = `${window.location.origin}/courses/${ENV.COURSE_ID}/assignments/${ENV.ASSIGNMENT_ID}/peer_reviews`
    const fullUrl = `${peerReviewUrl}?${queryParams.toString()}`
    window.location.href = fullUrl
  }

  const onFilterChange = (e: React.SyntheticEvent, data: {value?: string | number | undefined}) => {
    if (typeof data.value === 'string') {
      setSelectedOption(data.value)
    }
  }

  const onSearchChange = (e: React.SyntheticEvent, value: string) => {
    setSearchTerm(value)
  }

  return (
    <>
      <Flex margin="0 0 small 0">
        <Flex.Item margin="0 small 0 0" shouldGrow={true}>
          <TextInput
            data-testid="peer-review-search"
            renderLabel=""
            type="text"
            value={searchTerm}
            placeholder="Search"
            onChange={onSearchChange}
          />
        </Flex.Item>
        <Flex.Item margin="0 small 0 0">
          <SimpleSelect
            data-testid="peer-review-select"
            value={selectedOption}
            renderLabel=""
            onChange={onFilterChange}
          >
            <SimpleSelect.Option id="all" value="all">
              All
            </SimpleSelect.Option>
            <SimpleSelect.Option id="reviewer" value="reviewer">
              Search by Reviewer
            </SimpleSelect.Option>
            <SimpleSelect.Option id="student" value="student">
              Search by Peer Review
            </SimpleSelect.Option>
          </SimpleSelect>
        </Flex.Item>
        <Flex.Item>
          <Button data-testid="peer-review-submit" onClick={submitChange} color="primary">
            Submit
          </Button>
        </Flex.Item>
      </Flex>
    </>
  )
}
