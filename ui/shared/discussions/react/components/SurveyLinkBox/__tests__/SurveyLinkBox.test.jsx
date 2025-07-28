/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import {SurveyLinkBox} from '../SurveyLinkBox'

const enableFeatureFlag = () => {
  window.ENV = {
    ...window.ENV,
    FEATURES: {
      discussion_ai_survey_link: true,
    },
  }
}

const setCurrentUserIsStudent = () => {
  window.ENV = {
    ...window.ENV,
    current_user_is_student: true,
  }
}

describe('SurveyLinkBox', () => {
  beforeEach(() => {
    window.ENV = {
      FEATURES: {
        discussion_ai_survey_link: false,
      },
      current_user_is_student: false,
    }
  })

  it('does not render when feature flag is disabled', () => {
    const {container} = render(<SurveyLinkBox text={{__html: 'Test content'}} />)
    expect(container).toBeEmptyDOMElement()
  })

  it('does not render when current user is a student', () => {
    enableFeatureFlag()
    setCurrentUserIsStudent()
    const {container} = render(<SurveyLinkBox text={{__html: 'Test content'}} />)
    expect(container).toBeEmptyDOMElement()
  })

  it('renders content and link when feature flag is enabled', () => {
    enableFeatureFlag()
    const {getByTestId, getByRole} = render(
      <SurveyLinkBox text={{__html: '<strong>Bold feedback</strong>'}} />,
    )

    expect(getByTestId('discussion-ai-survey-text')).toBeInTheDocument()
    expect(getByRole('link', {name: 'Please share your feedback'})).toHaveAttribute(
      'href',
      'https://inst.bid/ai/feedback/',
    )
  })

  it('applies default marginTop when none is provided', () => {
    enableFeatureFlag()
    const {container} = render(<SurveyLinkBox text={{__html: 'Default margin'}} />)
    const div = container.querySelector('div')
    expect(div).toHaveStyle('margin: 0 0 0 0')
  })

  it('applies custom marginTop when provided', () => {
    enableFeatureFlag()
    const {container} = render(<SurveyLinkBox text={{__html: 'Custom margin'}} marginTop="large" />)
    const div = container.querySelector('div')
    expect(div).toHaveStyle('margin: 2.25rem 0 0 0')
  })
})
