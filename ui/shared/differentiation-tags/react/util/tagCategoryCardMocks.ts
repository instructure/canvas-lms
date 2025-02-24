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

import {TagCategoryCardProps} from '../DifferentiationTagTray/TagCategoryCard'

export const noTagsCategory: TagCategoryCardProps['category'] = {
  id: 1,
  name: 'Category with No Tags and long name',
  groups: [],
}

export const singleTagCategory: TagCategoryCardProps['category'] = {
  id: 2,
  name: 'Honors',
  groups: [
    {
      id: 101,
      name: 'Honors',
      members_count: 15,
    },
  ],
}

export const multipleTagsCategory: TagCategoryCardProps['category'] = {
  id: 3,
  name: 'Reading Groups',
  groups: [
    {
      id: 201,
      name: 'Variant A',
      members_count: 10,
    },
    {
      id: 202,
      name: 'Variant B',
      members_count: 20,
    },
    {
      id: 203,
      name: 'Variant C with a long name 123 321',
      members_count: 30,
    },
  ],
}

export const tagSetWithOneTag: TagCategoryCardProps['category'] = {
  id: 3,
  name: 'Reading Groups',
  groups: [
    {
      id: 201,
      name: 'Variant A',
      members_count: 15,
    },
  ],
}
