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

import React, {useRef} from 'react'
import PropTypes from 'prop-types'
import I18n from 'i18n!k5_dashboard'

import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'

import {createDashboardCards} from 'jsx/bundles/dashboard_card'

const HomeroomPage = ({announcements, cards, visible = false}) => {
  const dashboardCards = useRef(createDashboardCards(cards))

  return (
    <section
      id="dashboard_page_homeroom"
      style={{display: visible ? 'block' : 'none'}}
      aria-hidden={!visible}
    >
      {announcements && <View as="section">{/* Homeroom content will go here */}</View>}
      {cards && cards.length > 0 && (
        <View as="section">
          <Heading level="h2">{I18n.t('My Subjects')}</Heading>
          {dashboardCards.current}
        </View>
      )}
    </section>
  )
}

HomeroomPage.propTypes = {
  announcements: PropTypes.array,
  cards: PropTypes.array,
  visible: PropTypes.bool
}

export default HomeroomPage
