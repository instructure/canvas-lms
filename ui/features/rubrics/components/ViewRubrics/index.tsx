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

import React from 'react'
import {useNavigate} from 'react-router-dom'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {IconAddLine, IconSearchLine} from '@instructure/ui-icons'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'
import {RubricTable} from './RubricTable'

const {Item: FlexItem} = Flex

type Rubric = {
  id: string
  name: string
  points: number
  criterion: number
  locations: string[]
}

export const ViewRubrics = () => {
  const navigate = useNavigate()

  // Temporary setup data
  const mainRubricProps: Rubric[] = [
    {
      id: '1',
      criterion: 3,
      name: 'Quizzes Rubric',
      points: 30,
      locations: ['GD101', 'ART220', 'CS220', 'MS230'],
    },
    {id: '2', criterion: 5, name: 'ART 101 Rubric', points: 100, locations: []},
    {id: '3', criterion: 1, name: 'Test 1', points: 0, locations: []},
  ]
  const archivedRubricProps: Rubric[] = [
    {
      id: '4',
      criterion: 3,
      name: 'Old Rubric 1',
      points: 30,
      locations: ['GD101', 'ART220', 'CS220', 'MS230'],
    },
  ]

  return (
    <View as="div">
      <Flex>
        <FlexItem shouldShrink={true} shouldGrow={true}>
          <Heading level="h1" themeOverride={{h1FontWeight: 700}} margin="medium 0 0 0">
            Rubrics
          </Heading>
        </FlexItem>
        <FlexItem>
          <TextInput
            renderLabel={<ScreenReaderContent>Search Rubrics</ScreenReaderContent>}
            placeholder="Search..."
            value=""
            width="17"
            renderBeforeInput={<IconSearchLine inline={false} />}
          />
        </FlexItem>
        <FlexItem>
          <Button
            renderIcon={IconAddLine}
            color="primary"
            margin="small"
            onClick={() => navigate('./create')}
          >
            Create New Rubric
          </Button>
        </FlexItem>
      </Flex>

      <View as="div" margin="large 0 0 0">
        <Heading level="h2" themeOverride={{h1FontWeight: 700}}>
          Saved
        </Heading>
      </View>
      <View as="div" margin="medium 0">
        <RubricTable rubrics={mainRubricProps} />
      </View>

      <View as="div" margin="large 0 0 0">
        <Heading level="h2" themeOverride={{h1FontWeight: 700}}>
          Archived
        </Heading>
      </View>
      <View as="div" margin="medium 0">
        <RubricTable rubrics={archivedRubricProps} />
      </View>
    </View>
  )
}
