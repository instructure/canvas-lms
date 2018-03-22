/*
 * Copyright (C) 2018 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that they will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */


import PropTypes from 'prop-types';

export const userShape = {
  id: PropTypes.string,
  displayName: PropTypes.string,
  avatarUrl: PropTypes.string
};

export const badgeShape = {
  text: PropTypes.string,
  variant: PropTypes.string
};

export const courseShape = {
  id: PropTypes.string,
  longName: PropTypes.string,
};

export const itemShape = {
  context: PropTypes.shape({
    inform_students_of_overdue_submissions: PropTypes.bool
  })
};

export const opportunityShape = {
  items: PropTypes.arrayOf(PropTypes.object),
  nextUrl: PropTypes.string,
};

export default {
  badgeShape,
  userShape,
  courseShape,
  itemShape,
  opportunityShape
};
