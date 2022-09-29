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

import gql from 'graphql-tag'
import {arrayOf, shape, string} from 'prop-types'
import {ChildTopic} from './ChildTopic'

export const RootTopic = {
  fragment: gql`
    fragment RootTopic on Discussion {
      id
      _id
      childTopics {
        ...ChildTopic
      }
    }
    ${ChildTopic.fragment}
  `,

  shape: shape({
    id: string,
    _id: string,
    childTopics: arrayOf(ChildTopic.shape),
  }),

  mock: ({id = 'QXNzaWdubWVu2323wewrwr', _id = '7', childTopics = [ChildTopic.mock()]} = {}) => ({
    id,
    _id,
    childTopics,
    __typename: 'Discussion',
  }),
}
