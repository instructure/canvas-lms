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

import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'
import useRatings, {
  createRating,
  defaultOutcomesManagementRatings,
} from '@canvas/outcomes/react/hooks/useRatings'
import React from 'react'
import Ratings from './Ratings'

const ControledRatings = ({initialRatings, canManage}) => {
  const {ratings, setRatings, hasError} = useRatings({initialRatings})

  return (
    <>
      {hasError && <p>Fix your form, there are errors</p>}

      <Ratings ratings={ratings} onChangeRatings={setRatings} canManage={canManage} />
      {hasError && <p>Fix your form, there are errors</p>}
    </>
  )
}

export default {
  title: 'Examples/Outcomes/Ratings',
  component: ControledRatings,
  args: {
    isMobileView: false,
    canManage: true,
    initialRatings: defaultOutcomesManagementRatings,
  },
}

const Template = args => {
  return (
    <OutcomesContext.Provider value={{env: {isMobileView: args.isMobileView}}}>
      <ControledRatings {...args} />
    </OutcomesContext.Provider>
  )
}
export const Default = Template.bind({})

export const WithErrors = Template.bind({})
WithErrors.args = {
  initialRatings: [
    createRating('Exceeds Mastery', 4, '127A1B'),
    createRating('Mastery', 3, '0B874B', true),
    createRating('', 2, 'FAB901'),
    createRating('Below Mastery', 1, 'FD5D10'),
    createRating('Well Below Mastery', 0, 'E0061F'),
  ],
}

export const Mobile = Template.bind({})
Mobile.args = {
  isMobileView: true,
}

export const ReadOnly = Template.bind({})
ReadOnly.args = {
  canManage: false,
}

export const ReadOnlyMobile = Template.bind({})
ReadOnlyMobile.args = {
  canManage: false,
  isMobileView: true,
}
