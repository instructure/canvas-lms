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

import PropTypes from 'prop-types'

export const outcomeGroupShape = PropTypes.shape({
  _id: PropTypes.string.isRequired,
  title: PropTypes.string.isRequired,
  description: PropTypes.string,
  contextId: PropTypes.string,
  contextType: PropTypes.string,
})

export const outcomeShape = PropTypes.shape({
  _id: PropTypes.string.isRequired,
  linkId: PropTypes.string.isRequired,
  title: PropTypes.string.isRequired,
  canUnlink: PropTypes.bool.isRequired,
})

export const groupCollectionShape = PropTypes.shape({
  collections: PropTypes.arrayOf(PropTypes.string),
  descriptor: PropTypes.string,
  isRootGroup: PropTypes.bool,
  name: PropTypes.string,
  outcomesCount: PropTypes.number,
  parentGroupId: PropTypes.string,
})

export const outcomeEdgesNodeShape = PropTypes.shape({
  _id: PropTypes.string.isRequired,
  title: PropTypes.string.isRequired,
  isImported: PropTypes.bool,
  description: PropTypes.string,
  displayName: PropTypes.string,
})

export const outcomeEdgeShape = PropTypes.shape({
  node: outcomeEdgesNodeShape,
})

export const outcomePageInfoShape = PropTypes.shape({
  endCursor: PropTypes.string,
  hasNextPage: PropTypes.bool.isRequired,
})

export const ratingsShape = PropTypes.arrayOf(
  PropTypes.shape({
    description: PropTypes.string,
    points: PropTypes.number.isRequired,
  })
)

export const outcomeEditShape = PropTypes.shape({
  _id: PropTypes.string.isRequired,
  title: PropTypes.string.isRequired,
  description: PropTypes.string,
  displayName: PropTypes.string,
  contextId: PropTypes.string,
  contextType: PropTypes.string,
  calculationMethod: PropTypes.string,
  calculationInt: PropTypes.number,
  friendlyDescription: PropTypes.shape({
    description: PropTypes.string.isRequired,
  }),
  masteryPoints: PropTypes.number,
  pointsPossible: PropTypes.number,
  ratings: ratingsShape,
})
