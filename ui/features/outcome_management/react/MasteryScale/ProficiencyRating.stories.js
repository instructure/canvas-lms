/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import ProficiencyRating from './ProficiencyRating'

export default {
  title: 'Examples/Outcomes/ProficiencyRating',
  component: ProficiencyRating,
  args: {
    color: '127A1B',
    description: 'Exceeds Mastery',
    descriptionError: undefined,
    disableDelete: false,
    focusField: 'description',
    mastery: true,
    onColorChange: () => {},
    onDelete: () => {},
    onDescriptionChange: () => {},
    onMasteryChange: () => {},
    onPointsChange: () => {},
    points: '5',
    pointsError: undefined,
    isMobileView: false,
    position: 0,
    canManage: true,
  },
}

const Template = args => <ProficiencyRating {...args} />

export const Default = Template.bind({})
