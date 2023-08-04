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
import {ContentSelectionComponentProps} from '..'
import {defaultGradebookOptions} from '../../__tests__/fixtures'

export const defaultContentSelectionProps: ContentSelectionComponentProps = {
  courseId: '1',
  assignments: [],
  selectedStudentId: '1',
  selectedAssignmentId: null,
  gradebookOptions: defaultGradebookOptions,
  onStudentChange: () => {},
  onAssignmentChange: () => {},
}

export const defaultSortableStudents = [
  {
    id: '1',
    name: 'First Last',
    sortableName: 'Last, First',
    enrollments: {
      section: {
        name: '',
        id: '',
      },
    },
    email: '',
    loginId: '',
    sections: [],
    state: 'active',
  },
  {
    id: '2',
    name: 'First2 Last2',
    sortableName: 'Last2, First2',
    enrollments: {
      section: {
        name: '',
        id: '',
      },
    },
    email: '',
    loginId: '',
    sections: [],
    state: 'active',
  },
]

export function makeContentSelectionProps(
  props: Partial<ContentSelectionComponentProps> = {}
): ContentSelectionComponentProps {
  return {...defaultContentSelectionProps, ...props}
}
