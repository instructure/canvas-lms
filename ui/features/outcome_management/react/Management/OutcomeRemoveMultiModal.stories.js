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
import OutcomeRemoveMultiModal from './OutcomeRemoveMultiModal'

const outcomesGenerator = (num, canUnlink, title = '') =>
  new Array(num).fill(0).reduce(
    (acc, _curr, idx) => ({
      ...acc,
      [idx + 1]: {_id: `${idx + 1}`, title: title || `Learning Outcome ${idx + 1}`, canUnlink}
    }),
    {}
  )

export default {
  title: 'Examples/Outcomes/OutcomeRemoveMultiModal',
  component: OutcomeRemoveMultiModal,
  args: {
    outcomes: outcomesGenerator(5, true),
    isOpen: true,
    onCloseHandler: () => {}
  }
}

const Template = args => {
  return <OutcomeRemoveMultiModal {...args} />
}

export const Default = Template.bind({})

export const withMoreThan10Outcomes = Template.bind({})
withMoreThan10Outcomes.args = {
  outcomes: outcomesGenerator(15, true)
}

export const withNonRemovableOutcomes = Template.bind({})
withNonRemovableOutcomes.args = {
  outcomes: outcomesGenerator(5, false)
}

export const withLongOutcomeTitles = Template.bind({})
withLongOutcomeTitles.args = {
  outcomes: outcomesGenerator(
    5,
    false,
    'This is a very long outcome title that needs to be truncated in order to fit the modal width'
  )
}
