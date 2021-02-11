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

import React, {useEffect, useState} from 'react'
import {connect} from 'react-redux'
import PropTypes from 'prop-types'
import I18n from 'i18n!k5_dashboard'
import moment from 'moment-timezone'

import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'

import K5DashboardContext from '../K5DashboardContext'
import K5DashboardCard from '../cards/K5DashboardCard'
import {createDashboardCards} from 'jsx/bundles/dashboard_card'
import {countByCourseId, fetchLatestAnnouncement, fetchMissingAssignments} from '../utils'

export const fetchHomeroomAnnouncements = cards =>
  Promise.all(
    cards
      .filter(c => c.isHomeroom)
      .map(course =>
        fetchLatestAnnouncement(course.id).then(announcement => {
          if (!announcement) {
            return null
          }
          return {
            id: announcement.id,
            title: announcement.title,
            message: announcement.message,
            url: announcement.html_url,
            courseName: course.shortName,
            courseUrl: course.href
          }
        })
      )
  ).then(announcements => announcements.filter(a => a))

export const HomeroomPage = props => {
  const {assignmentsDueToday, cards, isStudent, requestTabChange, responsiveSize, visible} = props
  const [dashboardCards] = useState(() =>
    createDashboardCards(
      cards.filter(c => !c.isHomeroom),
      K5DashboardCard,
      {
        headingLevel: 'h3',
        requestTabChange
      }
    )
  )
  const [homeroomAnnouncements, setHomeroomAnnouncements] = useState([])
  const [assignmentsMissing, setAssignmentsMissing] = useState([])

  useEffect(() => {
    fetchHomeroomAnnouncements(cards).then(setHomeroomAnnouncements)
    fetchMissingAssignments().then(countByCourseId).then(setAssignmentsMissing)
    // Cards are only ever loaded once on the page, so this only runs on mount
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  return (
    <section
      id="dashboard_page_homeroom"
      style={{display: visible ? 'block' : 'none'}}
      aria-hidden={!visible}
    >
      {homeroomAnnouncements?.length > 0 && (
        <View as="section">{/* Homeroom content will go here */}</View>
      )}
      {cards?.length > 0 && (
        <View as="section">
          <Heading level="h2" margin="medium 0 0 0">
            {I18n.t('My Subjects')}
          </Heading>
          <K5DashboardContext.Provider
            value={{assignmentsDueToday, assignmentsMissing, isStudent, responsiveSize}}
          >
            {dashboardCards}
          </K5DashboardContext.Provider>
        </View>
      )}
    </section>
  )
}

HomeroomPage.propTypes = {
  assignmentsDueToday: PropTypes.object.isRequired,
  cards: PropTypes.array.isRequired,
  isStudent: PropTypes.bool.isRequired,
  requestTabChange: PropTypes.func.isRequired,
  responsiveSize: PropTypes.string.isRequired,
  visible: PropTypes.bool.isRequired
}

export const mapStateToProps = ({days, timeZone}) => {
  const todaysDate = moment.tz(timeZone).format('YYYY-MM-DD')
  const today = days?.length > 0 && days.find(([date]) => date === todaysDate)
  if (today?.length === 2 && today[1]?.length > 0) {
    const assignmentsDueToday = countByCourseId(
      today[1].filter(({status, type}) => type === 'Assignment' && !status.submitted)
    )
    return {assignmentsDueToday}
  }
  return {assignmentsDueToday: {}}
}

export default connect(mapStateToProps)(HomeroomPage)
