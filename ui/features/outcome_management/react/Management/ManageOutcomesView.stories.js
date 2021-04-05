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

import React from 'react'
import ManageOutcomesView from './ManageOutcomesView'

export default {
  title: 'Examples/Outcomes/ManageOutcomesView',
  component: ManageOutcomesView,
  args: {
    outcomeGroup: {
      id: '1',
      title: 'Parent Outcome',
      description: 'Parent Outcome Description',
      children: [
        {
          id: '2',
          title: 'Outcome Child 1',
          description: 'Outcome Child 1 Description'
        },
        {
          id: '3',
          title: 'Outcome Child 2',
          description: 'Outcome Child 2 Description'
        },
        {
          id: '4',
          title: 'Outcome Child 2',
          description: 'Outcome Child 2 Description'
        }
      ]
    },
    selectedOutcomes: {2: false, 3: false, 4: true},
    searchString: '',
    onSelectOutcomesHandler: () => {},
    onOutcomeGroupMenuHandler: () => {},
    onOutcomeMenuHandler: () => {},
    onSearchChangeHandler: () => {},
    onSearchClearHandler: () => {}
  }
}

const Template = args => <ManageOutcomesView {...args} />

export const Default = Template.bind({})
