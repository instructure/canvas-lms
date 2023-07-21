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
import 'tinymce/tinymce'
import {render} from '@testing-library/react'
import CalendarConferenceWidget from '../CalendarConferenceWidget'

// we use RichContentEditor.preloadRemoteModule() to consolidate the import of
// tinymce in the code, but since dynamic loading takes time during tests, we do
// a static import here and mock out the dynamic
jest.mock('@canvas/rce/RichContentEditor')

describe('CalendarConferenceWidget', () => {
  const conferenceTypes = [
    {type: 'foo', name: 'Foo', contexts: ['course_1', 'group_2']},
    {type: 'bar', name: 'Bar', contexts: ['course_1']},
  ]

  const conference = {title: 'Meet Today!', conference_type: 'LtiConference'}

  function makeParams(overrides = {}) {
    return {
      context: 'course_1',
      conference,
      conferenceTypes,
      setConference: Function.prototype,
      ...overrides,
    }
  }

  it('shows a conference if one is present', () => {
    const {getByText} = render(<CalendarConferenceWidget {...makeParams()} />)
    expect(getByText('Meet Today!')).not.toBeNull()
  })

  it('shows a selector if no conference is present', () => {
    const {getByText} = render(<CalendarConferenceWidget {...makeParams({conference: null})} />)
    expect(getByText('Select Conference Provider')).not.toBeNull()
  })

  it('does not show a selector if conference is present and single types is available', () => {
    const {queryByText} = render(
      <CalendarConferenceWidget {...makeParams({conferenceTypes: conferenceTypes.slice(0, 1)})} />
    )
    expect(queryByText('Select Conference Provider')).toBeNull()
  })

  it('shows a selector if conference is present and multiple types are available', () => {
    const {getByText} = render(<CalendarConferenceWidget {...makeParams()} />)
    expect(getByText('Select Conference Provider')).not.toBeNull()
  })

  it('does not show a selector if setConference is not defined', () => {
    const {queryByText} = render(
      <CalendarConferenceWidget {...makeParams({setConference: null})} />
    )
    expect(queryByText('Select Conference Provider')).toBeNull()
  })
})
