/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import {render, fireEvent} from '@testing-library/react'
import '@testing-library/jest-dom/extend-expect' // for the additional matchers
import SwitchEditorControl from '../SwitchEditorControl'
import RichContentEditor from '@canvas/rce/RichContentEditor'
import sinon from 'sinon'

describe('SwitchEditorControl', () => {
  beforeEach(() => {
    sinon.stub(RichContentEditor, 'callOnRCE')
  })

  afterEach(() => {
    RichContentEditor.callOnRCE.restore()
  })

  test('changes text on each click', () => {
    const textarea = {}
    const {getByRole} = render(<SwitchEditorControl textarea={textarea} />)
    const link = getByRole('link')

    expect(link).toHaveClass('switch-views__link switch-views__link__html')
    fireEvent.click(link)
    expect(link).toHaveClass('switch-views__link switch-views__link__rce')
  })

  test('passes textarea through to editor for toggling', () => {
    const textarea = {id: 'the text area'}
    const {getByRole} = render(<SwitchEditorControl textarea={textarea} />)
    const link = getByRole('link')

    fireEvent.click(link)
    expect(RichContentEditor.callOnRCE.calledWith(textarea)).toBeTruthy()
  })
})
