/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {shallow} from 'enzyme'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {Spinner} from '@instructure/ui-spinner'
import {Link} from '@instructure/ui-link'
import GradesDisplay from '../index'
import ErrorAlert from '../../ErrorAlert'

describe('GradesDisplay', () => {
  const mockCourses = [
    {
      id: '1',
      shortName: 'Ticket to Ride 101',
      color: 'blue',
      href: '/courses/1',
      score: null,
      grade: null,
      hasGradingPeriods: true,
    },
    {
      id: '2',
      shortName: 'Ingenious 101',
      color: 'green',
      href: '/courses/2',
      score: 42.34,
      grade: 'D',
      hasGradingPeriods: false,
    },
    {
      id: '3',
      shortName: 'Settlers of Catan 201',
      color: 'red',
      href: '/courses/3',
      score: 'blahblah',
      grade: null,
      hasGradingPeriods: false,
    },
  ]

  it('renders course grades with proper heading and structure', () => {
    const wrapper = shallow(<GradesDisplay courses={mockCourses} />)

    // Check for "My Grades" heading component
    const heading = wrapper.find(Heading)
    expect(heading).toHaveLength(1)

    // Check that all courses are rendered as links
    const links = wrapper.find(Link)
    expect(links).toHaveLength(3)

    // Check course links have correct hrefs
    expect(links.at(0).prop('href')).toBe('/courses/1/grades')
    expect(links.at(1).prop('href')).toBe('/courses/2/grades')
    expect(links.at(2).prop('href')).toBe('/courses/3/grades')
  })

  it('displays proper grade scores and handles invalid scores', () => {
    const wrapper = shallow(<GradesDisplay courses={mockCourses} />)

    const scoreTexts = wrapper.find('[data-testid="my-grades-score"]')
    expect(scoreTexts).toHaveLength(3)

    // Check props instead of rendered text since shallow doesn't render children
    expect(scoreTexts.at(0).prop('children')).toBe('No Grade')
    expect(scoreTexts.at(1).prop('children')).toBe('42.34%')
    expect(scoreTexts.at(2).prop('children')).toBe('No Grade')
  })

  it('renders grading period caveat when courses have grading periods', () => {
    const wrapper = shallow(<GradesDisplay courses={mockCourses} />)

    // Look for caveat text by checking Text components with italic style
    const italicTexts = wrapper.find(Text).filterWhere(text => text.prop('fontStyle') === 'italic')
    expect(italicTexts).toHaveLength(1)
    expect(italicTexts.at(0).prop('children')).toBe('*Only most recent grading period shown.')
  })

  it('does not render caveat if no courses have grading periods', () => {
    const coursesWithoutGradingPeriods = [
      {
        id: '1',
        shortName: 'Ticket to Ride 101',
        color: 'blue',
        href: '/courses/1',
        score: null,
        grade: null,
        hasGradingPeriods: false,
        enrollmentType: 'StudentEnrollment',
      },
    ]
    const wrapper = shallow(<GradesDisplay courses={coursesWithoutGradingPeriods} />)

    const caveatText = wrapper.find(Text).filterWhere(text => text.prop('fontStyle') === 'italic')
    expect(caveatText).toHaveLength(0)
  })

  it('renders a loading spinner when loading', () => {
    const wrapper = shallow(<GradesDisplay loading={true} courses={mockCourses} />)

    const spinner = wrapper.find(Spinner)
    expect(spinner).toHaveLength(1)
    expect(spinner.prop('size')).toBe('small')

    // Should not render course grades when loading
    const links = wrapper.find(Link)
    expect(links).toHaveLength(0)

    // Should not render caveat when loading
    const caveatText = wrapper.find(Text).filterWhere(text => text.prop('fontStyle') === 'italic')
    expect(caveatText).toHaveLength(0)
  })

  it('renders an ErrorAlert if there is an error loading grades', () => {
    const mockCoursesSimple = [
      {id: '1', shortName: 'Ticket to Ride 101', color: 'blue', href: '/courses/1'},
    ]
    const wrapper = shallow(
      <GradesDisplay courses={mockCoursesSimple} loadingError="There was an error" />,
    )

    const errorAlert = wrapper.find(ErrorAlert)
    expect(errorAlert).toHaveLength(1)
    expect(errorAlert.prop('error')).toBe('There was an error')
    expect(errorAlert.prop('children')).toBe('Error loading grades')

    // Should still render heading when there's an error
    const heading = wrapper.find(Heading)
    expect(heading).toHaveLength(1)

    // Should not render grades when there's an error
    const scoreTexts = wrapper.find('[data-testid="my-grades-score"]')
    expect(scoreTexts).toHaveLength(0)
  })

  it('applies course color to border styling', () => {
    const wrapper = shallow(<GradesDisplay courses={mockCourses} />)

    // Check that course styling divs have the proper border colors
    const styledDivs = wrapper
      .find('div')
      .filterWhere(div => div.prop('style') && div.prop('style').borderBottomColor)

    expect(styledDivs.at(0).prop('style').borderBottomColor).toBe('blue')
    expect(styledDivs.at(1).prop('style').borderBottomColor).toBe('green')
    expect(styledDivs.at(2).prop('style').borderBottomColor).toBe('red')
  })
})
