/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {bool, number, shape, string} from 'prop-types'
import gql from 'graphql-tag'

export const ProficiencyRating = {
  fragment: gql`
    fragment ProficiencyRating on ProficiencyRating {
      _id
      color
      description
      mastery
      points
    }
  `,

  shape: shape({
    _id: string.isRequired,
    color: string,
    description: string,
    mastery: bool,
    points: number,
  }),
}

export const DefaultMocks = {
  ProficiencyRating: () => ({}),
}
