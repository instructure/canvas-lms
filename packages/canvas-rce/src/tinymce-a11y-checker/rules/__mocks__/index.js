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

export default [
  {
    test: jest.fn().mockReturnValue(false),
    data: jest.fn().mockReturnValue({
      select: 'a',
      checkbox: true,
      color: 'rgba(40, 100, 200, 0.6)',
      text: 'Text',
    }),
    form: jest.fn().mockReturnValue([
      {
        label: 'Select Field',
        dataKey: 'select',
        options: [
          ['a', 'A'],
          ['b', 'B'],
        ],
      },
      {
        label: 'Select Field',
        dataKey: 'checkbox',
        checkbox: true,
      },
      {
        label: 'Select Field',
        dataKey: 'color',
        color: true,
      },
      {
        label: 'Text Field',
        dataKey: 'text',
        disabledIf: () => true,
      },
      {
        label: 'Text Area',
        dataKey: 'textarea',
        textarea: true,
      },
    ]),
    rootNode: jest.fn(),
    update: jest.fn(),
    message: jest.fn().mockReturnValue('Error Message'),
    why: jest.fn().mockReturnValue('Why Text'),
    link: 'http://some-url',
    linkText: jest.fn().mockReturnValue('Link for learning more'),
  },
]
