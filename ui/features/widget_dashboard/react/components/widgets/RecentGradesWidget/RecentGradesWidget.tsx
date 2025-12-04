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

import React, {useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Link} from '@instructure/ui-link'
import TemplateWidget from '../TemplateWidget/TemplateWidget'
import GradeItem from './GradeItem'
import type {BaseWidgetProps, RecentGradeSubmission} from '../../../types'

const I18n = createI18nScope('widget_dashboard')

const ITEMS_PER_PAGE = 5

const mockSubmissions: RecentGradeSubmission[] = [
  {
    _id: '1',
    submittedAt: '2025-11-28T10:00:00Z',
    gradedAt: '2025-11-30T14:30:00Z',
    score: 95,
    grade: 'A',
    state: 'graded',
    assignment: {
      _id: '101',
      name: 'Introduction to React Hooks',
      htmlUrl: '/courses/1/assignments/101',
      pointsPossible: 100,
      submissionTypes: ['online_text_entry'],
      quiz: null,
      discussion: null,
      course: {
        _id: '1',
        name: 'Advanced Web Development',
        courseCode: 'CS-401',
      },
    },
  },
  {
    _id: '2',
    submittedAt: '2025-11-27T09:00:00Z',
    gradedAt: '2025-11-29T16:45:00Z',
    score: 88,
    grade: 'B+',
    state: 'graded',
    assignment: {
      _id: '102',
      name: 'Data Structures Quiz',
      htmlUrl: '/courses/2/assignments/102',
      pointsPossible: 100,
      submissionTypes: ['online_quiz'],
      quiz: {_id: '102', title: 'Data Structures Quiz'},
      discussion: null,
      course: {
        _id: '2',
        name: 'Computer Science 101',
        courseCode: 'CS-101',
      },
    },
  },
  {
    _id: '3',
    submittedAt: '2025-11-26T11:30:00Z',
    gradedAt: '2025-11-28T10:15:00Z',
    score: 92,
    grade: 'A-',
    state: 'graded',
    assignment: {
      _id: '103',
      name: 'Essay on Modern Literature',
      htmlUrl: '/courses/3/assignments/103',
      pointsPossible: 100,
      submissionTypes: ['online_text_entry'],
      quiz: null,
      discussion: null,
      course: {
        _id: '3',
        name: 'English Literature 201',
        courseCode: 'ENG-201',
      },
    },
  },
  {
    _id: '4',
    submittedAt: '2025-11-25T15:00:00Z',
    gradedAt: '2025-11-27T09:00:00Z',
    score: 78,
    grade: 'C+',
    state: 'graded',
    assignment: {
      _id: '104',
      name: 'Calculus Problem Set 5',
      htmlUrl: '/courses/4/assignments/104',
      pointsPossible: 100,
      submissionTypes: ['online_text_entry'],
      quiz: null,
      discussion: null,
      course: {
        _id: '4',
        name: 'Mathematics 301',
        courseCode: 'MATH-301',
      },
    },
  },
  {
    _id: '5',
    submittedAt: '2025-11-24T13:00:00Z',
    gradedAt: '2025-11-26T11:30:00Z',
    score: 90,
    grade: 'A-',
    state: 'graded',
    assignment: {
      _id: '105',
      name: 'Lab Report: Chemical Reactions',
      htmlUrl: '/courses/5/assignments/105',
      pointsPossible: 100,
      submissionTypes: ['online_upload'],
      quiz: null,
      discussion: null,
      course: {
        _id: '5',
        name: 'Chemistry 202',
        courseCode: 'CHEM-202',
      },
    },
  },
  {
    _id: '6',
    submittedAt: '2025-11-23T10:00:00Z',
    gradedAt: '2025-11-25T14:00:00Z',
    score: 85,
    grade: 'B',
    state: 'graded',
    assignment: {
      _id: '106',
      name: 'History Presentation',
      htmlUrl: '/courses/6/assignments/106',
      pointsPossible: 100,
      submissionTypes: ['online_upload'],
      quiz: null,
      discussion: null,
      course: {
        _id: '6',
        name: 'World History 101',
        courseCode: 'HIST-101',
      },
    },
  },
  {
    _id: '7',
    submittedAt: '2025-11-22T12:00:00Z',
    gradedAt: '2025-11-24T15:30:00Z',
    score: 94,
    grade: 'A',
    state: 'graded',
    assignment: {
      _id: '107',
      name: 'Physics Lab 3',
      htmlUrl: '/courses/7/assignments/107',
      pointsPossible: 100,
      submissionTypes: ['online_upload'],
      quiz: null,
      discussion: null,
      course: {
        _id: '7',
        name: 'Physics 201',
        courseCode: 'PHYS-201',
      },
    },
  },
  {
    _id: '8',
    submittedAt: '2025-11-21T09:30:00Z',
    gradedAt: '2025-11-23T10:00:00Z',
    score: 82,
    grade: 'B',
    state: 'graded',
    assignment: {
      _id: '108',
      name: 'Spanish Vocabulary Test',
      htmlUrl: '/courses/8/assignments/108',
      pointsPossible: 100,
      submissionTypes: ['online_text_entry'],
      quiz: null,
      discussion: null,
      course: {
        _id: '8',
        name: 'Spanish 102',
        courseCode: 'SPAN-102',
      },
    },
  },
  {
    _id: '9',
    submittedAt: '2025-11-20T14:00:00Z',
    gradedAt: '2025-11-22T16:00:00Z',
    score: 96,
    grade: 'A',
    state: 'graded',
    assignment: {
      _id: '109',
      name: 'Psychology Midterm Quiz',
      htmlUrl: '/courses/9/assignments/109',
      pointsPossible: 100,
      submissionTypes: ['online_quiz'],
      quiz: {_id: '109', title: 'Psychology Midterm Quiz'},
      discussion: null,
      course: {
        _id: '9',
        name: 'Introduction to Psychology',
        courseCode: 'PSY-101',
      },
    },
  },
  {
    _id: '10',
    submittedAt: '2025-11-19T11:00:00Z',
    gradedAt: '2025-11-21T13:00:00Z',
    score: 87,
    grade: 'B+',
    state: 'graded',
    assignment: {
      _id: '110',
      name: 'Art History Period Quiz',
      htmlUrl: '/courses/10/assignments/110',
      pointsPossible: 100,
      submissionTypes: ['online_quiz'],
      quiz: {_id: '110', title: 'Art History Period Quiz'},
      discussion: null,
      course: {
        _id: '10',
        name: 'Art History 201',
        courseCode: 'ART-201',
      },
    },
  },
  {
    _id: '11',
    submittedAt: '2025-11-18T10:00:00Z',
    gradedAt: '2025-11-20T14:30:00Z',
    score: 91,
    grade: 'A-',
    state: 'graded',
    assignment: {
      _id: '111',
      name: 'Discussion: Cell Biology',
      htmlUrl: '/courses/11/assignments/111',
      pointsPossible: 100,
      submissionTypes: ['discussion_topic'],
      quiz: null,
      discussion: {_id: '111', title: 'Discussion: Cell Biology'},
      course: {
        _id: '11',
        name: 'Biology 101',
        courseCode: 'BIO-101',
      },
    },
  },
  {
    _id: '12',
    submittedAt: '2025-11-17T15:00:00Z',
    gradedAt: '2025-11-19T09:00:00Z',
    score: 89,
    grade: 'B+',
    state: 'graded',
    assignment: {
      _id: '112',
      name: 'Discussion: Statistical Methods',
      htmlUrl: '/courses/12/assignments/112',
      pointsPossible: 100,
      submissionTypes: ['discussion_topic'],
      quiz: null,
      discussion: {_id: '112', title: 'Discussion: Statistical Methods'},
      course: {
        _id: '12',
        name: 'Statistics 202',
        courseCode: 'STAT-202',
      },
    },
  },
]

const RecentGradesWidget: React.FC<BaseWidgetProps> = ({
  widget,
  isLoading = false,
  error = null,
  onRetry,
  isEditMode = false,
  dragHandleProps,
}) => {
  const [currentPage, setCurrentPage] = useState(1)
  const [selectedCourse, setSelectedCourse] = useState<string>('all')

  const totalPages = Math.ceil(mockSubmissions.length / ITEMS_PER_PAGE)
  const startIndex = (currentPage - 1) * ITEMS_PER_PAGE
  const endIndex = startIndex + ITEMS_PER_PAGE
  const currentSubmissions = mockSubmissions.slice(startIndex, endIndex)

  const handlePageChange = (page: number) => {
    setCurrentPage(page)
  }

  const paginationProps = {
    currentPage,
    totalPages,
    onPageChange: handlePageChange,
    ariaLabel: I18n.t('Recent grades pagination'),
  }

  return (
    <TemplateWidget
      widget={widget}
      isEditMode={isEditMode}
      dragHandleProps={dragHandleProps}
      isLoading={isLoading}
      error={error}
      onRetry={onRetry}
      loadingText={I18n.t('Loading recent grades...')}
      pagination={paginationProps}
      footerActions={
        <View as="div" textAlign="center">
          <Link href="/grades" isWithinText={false} data-testid="view-all-grades-link">
            {I18n.t('View all grades')}
          </Link>
        </View>
      }
    >
      <View as="div" padding="0 0 small 0">
        <SimpleSelect
          renderLabel={I18n.t('Course filter')}
          value={selectedCourse}
          onChange={(_e, {value}) => setSelectedCourse(value as string)}
          disabled={true}
          data-testid="course-filter-select"
          width="100%"
        >
          <SimpleSelect.Option id="all" value="all">
            {I18n.t('All courses')}
          </SimpleSelect.Option>
        </SimpleSelect>
      </View>
      <View as="div" data-testid="recent-grades-list">
        {currentSubmissions.length > 0 ? (
          currentSubmissions.map(submission => (
            <GradeItem key={submission._id} submission={submission} />
          ))
        ) : (
          <View as="div" textAlign="center" padding="large">
            {I18n.t('No recent grades available')}
          </View>
        )}
      </View>
    </TemplateWidget>
  )
}

export default RecentGradesWidget
