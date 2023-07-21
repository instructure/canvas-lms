/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import AlignmentSummaryHeader from './AlignmentSummaryHeader'

export default {
  title: 'Examples/Outcomes/AlignmentSummaryHeader',
  component: AlignmentSummaryHeader,
  args: {
    totalOutcomes: 100,
    alignedOutcomes: 25,
    totalAlignments: 200,
    totalArtifacts: 75,
    alignedArtifacts: 60,
    searchString: '',
    updateSearchHandler: () => {},
    clearSearchHandler: () => {},
  },
}

const Template = args => <AlignmentSummaryHeader {...args} />

export const Default = Template.bind({})

export const withNoOutcomes = Template.bind({})
withNoOutcomes.args = {
  totalOutcomes: 0,
  alignedOutcomes: 0,
}

export const withNoArtifacts = Template.bind({})
withNoArtifacts.args = {
  totalArtifacts: 0,
}
