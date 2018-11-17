/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import Color from 'tinycolor2';

export const defaultColors = {
  salmon: '#FFE8E5',
  orange: '#FEF0E5',
  yellow: '#FEF7E5',
  brown: '#F3EFEA',
  green: '#E5F7E5',
  blue: '#E5F3FC',
  steel: '#E9EDF5', // (・3・)
  pink: '#F8EAF6',
  lavender: '#F0E8EF',
  white: '#FFFFFF'
};

const defaultStatusColors = {
  dropped: defaultColors.orange,
  excused: defaultColors.yellow,
  late: defaultColors.blue,
  missing: defaultColors.salmon,
  resubmitted: defaultColors.green
};

export function statusColors (userColors = {}) {
  return {
    ...defaultStatusColors,
    ...userColors
  };
}

export function darken (color, percent) {
  return Color(color).darken(percent);
}
