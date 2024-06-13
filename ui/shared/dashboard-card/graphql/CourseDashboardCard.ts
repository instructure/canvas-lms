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

import gql from 'graphql-tag'
import {arrayOf, bool, number, shape, string} from 'prop-types'

export const CourseDashboardCard = {
  fragment: gql`
    fragment CourseDashboardCard on CourseDashboardCard {
      longName
      shortName
      useClassicFont
      term {
        name
        id
      }
      subtitle
      published
      position
      pagesUrl
      originalName
      observee
      links {
        path
        label
        icon
        hidden
        cssClass
      }
      isK5Subject
      isHomeroom
      isFavorited
      image
      href
      frontPageTitle
      enrollmentType
      enrollmentState
      defaultView
      courseCode
      color
      canReadAnnouncements
      canManage
      canChangeCoursePublishState
      assetString
    }
  `,
  shape: shape({
    assetString: string,
    canChangeCoursePublishState: bool,
    canManage: bool,
    canReadAnnouncements: bool,
    color: string,
    courseCode: string,
    defaultView: string,
    enrollmentState: string,
    enrollmentType: string,
    frontPageTitle: string,
    href: string,
    image: string,
    isFavorited: bool,
    isHomeroom: bool,
    isK5Subject: bool,
    links: arrayOf(
      shape({
        path: string,
        label: string,
        icon: string,
        hidden: bool,
        cssClass: string,
      })
    ),
    longName: string,
    observee: string,
    originalName: string,
    pagesUrl: string,
    position: number,
    published: bool,
    shortName: string,
    subtitle: string,
    term: shape({
      name: string,
      id: string,
    }),
    useClassicFont: bool,
  }),
  mock: ({
    assetString = 'course_1',
    canChangeCoursePublishState = true,
    canManage = true,
    canReadAnnouncements = true,
    color = '#ff0000',
    courseCode = 'CS101',
    defaultView = 'syllabus',
    enrollmentState = 'active',
    enrollmentType = 'StudentEnrollment',
    frontPageTitle = 'Course Overview',
    href = '/courses/1',
    image = 'https://example.com/image.jpg',
    isFavorited = false,
    isHomeroom = false,
    isK5Subject = false,
    links = [
      {
        path: '/courses/1/assignments',
        label: 'Assignments',
        icon: 'icon-assignment',
        hidden: false,
        cssClass: 'assignments',
      },
      {
        path: '/courses/1/discussion_topics',
        label: 'Discussions',
        icon: 'icon-discussion',
        hidden: false,
        cssClass: 'discussions',
      },
    ],
    longName = 'Introduction to Computer Science',
    observee = null,
    originalName = 'CS101',
    pagesUrl = 'https://example.com/courses/1/pages',
    position = 1,
    published = true,
    shortName = 'Intro to CS',
    subtitle = 'Fall 2024',
    term = {
      name: 'Fall 2024',
      id: 'term_1',
    },
    useClassicFont = false,
  } = {}) => ({
    assetString,
    canChangeCoursePublishState,
    canManage,
    canReadAnnouncements,
    color,
    courseCode,
    defaultView,
    enrollmentState,
    enrollmentType,
    frontPageTitle,
    href,
    image,
    isFavorited,
    isHomeroom,
    isK5Subject,
    links,
    longName,
    observee,
    originalName,
    pagesUrl,
    position,
    published,
    shortName,
    subtitle,
    term,
    useClassicFont,
    __typename: 'CourseDashboardCard',
  }),
}
