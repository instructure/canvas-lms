// @vitest-environment jsdom
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

import {render} from '@testing-library/react'
import {StudentMasteryScoreSummary} from '../StudentMasteryScoreSummary'

describe('StudentMasteryScoreSummary', () => {
  const defaultProps = (props = {}) => ({
    studentName: 'John Doe',
    studentEmail: 'john.doe@example.com',
    studentAvatarUrl: 'https://example.com/avatar.jpg',
    ...props,
  })

  const masteryLevel = {
    score: 3.5,
    text: 'Mastery',
    iconUrl: '/images/outcomes/mastery.svg',
  }

  const buckets = {
    no_evidence: {
      name: 'No Evidence',
      iconURL: '/images/outcomes/no_evidence.svg',
      count: 2,
    },
    remediation: {
      name: 'Remediation',
      iconURL: '/images/outcomes/remediation.svg',
      count: 1,
    },
    near_mastery: {
      name: 'Near Mastery',
      iconURL: '/images/outcomes/near_mastery.svg',
      count: 3,
    },
    mastery: {
      name: 'Mastery',
      iconURL: '/images/outcomes/mastery.svg',
      count: 5,
    },
    exceeds_mastery: {
      name: 'Exceeds Mastery',
      iconURL: '/images/outcomes/exceeds_mastery.svg',
      count: 4,
    },
  }

  const renderStudentMasteryScoreSummary = (props = {}) =>
    render(<StudentMasteryScoreSummary {...defaultProps(props)} />)

  it('renders student name', () => {
    const wrapper = renderStudentMasteryScoreSummary()
    expect(wrapper.getByText('John Doe')).toBeInTheDocument()
  })

  it('renders student email as mailto link', () => {
    const wrapper = renderStudentMasteryScoreSummary()
    const emailLink = wrapper.getByText('john.doe@example.com')
    expect(emailLink).toBeInTheDocument()
    expect(emailLink.closest('a')).toHaveAttribute('href', 'mailto:john.doe@example.com')
  })

  it('renders student avatar', () => {
    const wrapper = renderStudentMasteryScoreSummary()
    const avatar = wrapper.getByTestId('student-mastery-avatar')
    expect(avatar).toBeInTheDocument()
  })

  it('does not render email when not provided', () => {
    const wrapper = renderStudentMasteryScoreSummary({studentEmail: undefined})
    expect(wrapper.container.querySelector('a[href^="mailto:"]')).not.toBeInTheDocument()
  })

  it('renders mastery level score and text', () => {
    const wrapper = renderStudentMasteryScoreSummary({masteryLevel})
    expect(wrapper.getByText('3.5')).toBeInTheDocument()
    // Use getAllByText since "Mastery" appears twice (once for screen readers, once visible)
    expect(wrapper.getAllByText('Mastery').length).toBeGreaterThan(0)
  })

  it('renders mastery level icon', () => {
    const wrapper = renderStudentMasteryScoreSummary({masteryLevel})
    const icon = wrapper.container.querySelector('img[alt="Mastery"]')
    expect(icon).toBeInTheDocument()
  })

  it('renders all mastery buckets with counts', () => {
    const wrapper = renderStudentMasteryScoreSummary({masteryLevel, buckets})
    expect(wrapper.getByText('2')).toBeInTheDocument() // No Evidence
    expect(wrapper.getByText('1')).toBeInTheDocument() // Remediation
    expect(wrapper.getByText('3')).toBeInTheDocument() // Near Mastery
    expect(wrapper.getByText('5')).toBeInTheDocument() // Mastery
    expect(wrapper.getByText('4')).toBeInTheDocument() // Exceeds Mastery
  })

  it('renders Traditional Grade Export text', () => {
    const wrapper = renderStudentMasteryScoreSummary({masteryLevel})
    expect(wrapper.getByText('Traditional Grade Export')).toBeInTheDocument()
  })

  it('does not render mastery section when masteryLevel is not provided', () => {
    const wrapper = renderStudentMasteryScoreSummary()
    expect(wrapper.queryByText('Traditional Grade Export')).not.toBeInTheDocument()
  })

  it('renders buckets in correct order (reversed)', () => {
    const wrapper = renderStudentMasteryScoreSummary({masteryLevel, buckets})
    const bucketCounts = wrapper.getAllByText(/^[0-9]+$/)

    expect(bucketCounts[0]).toHaveTextContent('4')
    expect(bucketCounts[1]).toHaveTextContent('5')
    expect(bucketCounts[2]).toHaveTextContent('3')
    expect(bucketCounts[3]).toHaveTextContent('1')
    expect(bucketCounts[4]).toHaveTextContent('2')
  })

  it('formats score to one decimal place', () => {
    const levelWithLongScore = {...masteryLevel, score: 3.456789}
    const wrapper = renderStudentMasteryScoreSummary({masteryLevel: levelWithLongScore})
    expect(wrapper.getByText('3.5')).toBeInTheDocument()
    expect(wrapper.queryByText('3.456789')).not.toBeInTheDocument()
  })

  it('has correct data-testid', () => {
    const {container} = renderStudentMasteryScoreSummary()
    expect(container.querySelector('[data-testid="student-mastery-header"]')).toBeInTheDocument()
  })
})
