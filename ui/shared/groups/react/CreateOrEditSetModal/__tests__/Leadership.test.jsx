/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {render, screen, fireEvent} from '@testing-library/react'
import '@testing-library/jest-dom'
import {Leadership} from '../Leadership'
import {GroupContext, SPLIT} from '../context'

const providerState = {
  enableAutoLeader: true,
  autoLeaderType: 'FIRST',
  selfSignup: true,
  splitGroups: SPLIT.on,
}

const Wrapper = ({state, props}) => {
  return (
    <GroupContext.Provider value={state}>
      <Leadership {...props} />
    </GroupContext.Provider>
  )
}

const defaultProps = {onChange: Function.prototype}

const helpText = 'Group leaders can manage members and edit the group name but not the group size.'

describe('CreateOrEditSetModal::Leadership::', () => {
  it('displays the tooltip on icon button click', () => {
    render(<Wrapper state={providerState} props={defaultProps} />)

    const iconButton = screen.getByTestId('group-leadership-icon-button')
    fireEvent.click(iconButton)

    expect(screen.getByTestId('group-leadership-help-text')).toBeInTheDocument()
  })

  it('displays the tooltip on icon button hover', () => {
    render(<Wrapper state={providerState} props={defaultProps} />)

    const iconButton = screen.getByTestId('group-leadership-icon-button')
    fireEvent.mouseOver(iconButton)

    expect(screen.getByTestId('group-leadership-help-text')).toBeInTheDocument()
  })

  it('displays the tooltip on icon button focus', () => {
    render(<Wrapper state={providerState} props={defaultProps} />)

    const iconButton = screen.getByTestId('group-leadership-icon-button')
    fireEvent.focus(iconButton)

    expect(screen.getByTestId('group-leadership-help-text')).toBeInTheDocument()
  })
})
