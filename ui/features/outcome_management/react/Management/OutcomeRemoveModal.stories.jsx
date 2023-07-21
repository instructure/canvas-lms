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
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'
import OutcomeRemoveModal from './OutcomeRemoveModal'

const outcomesGenerator = (startId, count, canUnlink = true, title = '') =>
  new Array(count).fill(0).reduce(
    (acc, _curr, idx) => ({
      ...acc,
      [`${startId + idx}`]: {
        _id: `${idx + 100}`,
        linkId: `${startId + idx}`,
        title: title || `Learning Outcome ${startId + idx}`,
        canUnlink,
      },
    }),
    {}
  )

export default {
  title: 'Examples/Outcomes/OutcomeRemoveModal',
  component: OutcomeRemoveModal,
  args: {
    outcomes: outcomesGenerator(1, 5),
    isOpen: true,
    onCloseHandler: () => {},
    onCleanupHandler: () => {},
  },
}

const withContext = (children, {contextType = 'Account', contextId = '1'} = {}) => (
  <OutcomesContext.Provider value={{env: {contextType, contextId}}}>
    {children}
  </OutcomesContext.Provider>
)

const Template = args => {
  return withContext(<OutcomeRemoveModal {...args} />)
}
export const Default = Template.bind({})

const TemplateCourse = args => {
  return withContext(<OutcomeRemoveModal {...args} />, {contextType: 'Course'})
}
export const inCourseContext = TemplateCourse.bind({})

export const withSingleOutcome = Template.bind({})
withSingleOutcome.args = {
  outcomes: outcomesGenerator(1, 1),
}

export const withMoreThan10Outcomes = Template.bind({})
withMoreThan10Outcomes.args = {
  outcomes: outcomesGenerator(1, 15),
}

export const withOnlyNonRemovableOutcomes = Template.bind({})
withOnlyNonRemovableOutcomes.args = {
  outcomes: outcomesGenerator(1, 5, false),
}

export const withRemovableAndNonRemovableOutcomes = Template.bind({})
withRemovableAndNonRemovableOutcomes.args = {
  outcomes: {
    ...outcomesGenerator(1, 3),
    ...outcomesGenerator(4, 2, false),
  },
}

export const withLongOutcomeTitles = Template.bind({})
withLongOutcomeTitles.args = {
  outcomes: outcomesGenerator(
    1,
    5,
    true,
    'This is a very long outcome title that needs to be truncated to fit the modal width'
  ),
}
