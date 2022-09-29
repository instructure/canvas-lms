// Copyright (C) 2020 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import $ from 'jquery'
import React from 'react'
import page from 'page'
import {render, fireEvent} from '@testing-library/react'
import store from '../../lib/AppCenterStore'
import AppList from '../AppList'

jest.mock('page')

describe('AppList', () => {
  const originalGetJSON = $.getJSON
  const originalAJAX = $.ajax

  const defaultApps = () => [
    {
      app_type: null,
      average_rating: 0,
      banner_image_url:
        'https://edu-app-center.s3.amazonaws.com/uploads/production/lti_app/banner_image/acclaim_app.png',
      config_options: [],
      config_xml_url: 'https://www.eduappcenter.com/configurations/g7lthtepu68qhchz.xml',
      custom_tags: [
        'Assessment',
        'Community',
        'Content',
        'Media',
        '7th-12th Grade',
        'Postsecondary',
        'Open Content',
        'Web 2.0',
      ],
      description:
        '\n<p>Acclaim is the easiest way to organize and annotate videos for class.</p>\n\n<p>Instructors and students set up folders, upload recordings or embed relevant web videos, and then securely share access among each other. Moments in each video can then be highlighted and discussed using time-specific comments!</p>\n\n<p>To learn more about how to use Acclaim in your class(es), email Melinda at <a href="mailto:melinda@getacclaim.com">melinda@getacclaim.com</a>.</p>\n\n<p>For general information, please visit <a href="https://getacclaim.com">Acclaim</a>.</p>\n',
      icon_image_url: null,
      id: 289,
      is_certified: false,
      is_installed: true,
      logo_image_url: null,
      name: 'Acclaim',
      preview_url: '',
      requires_secret: true,
      short_description: 'Acclaim is the easiest way to organize and annotate videos.',
      short_name: 'acclaim_app',
      status: 'active',
      total_ratings: 0,
    },
    {
      app_type: null,
      average_rating: 5,
      banner_image_url:
        'https://edu-app-center.s3.amazonaws.com/uploads/production/lti_app/banner_image/aleks.png',
      config_options: [],
      config_xml_url: 'https://www.eduappcenter.com/configurations/fn4dnjhl0ot1ka4j.xml',
      custom_tags: ['Community', 'Content', 'K-6th Grade', '7th-12th Grade', 'Postsecondary'],
      description:
        '\n<p>ALEKS is an artificial intelligent assessment and learning system which uses adaptive questioning to quickly and accurately determine exactly what a student knows and doesn\u2019t know in a course.</p>\n\n<p>ALEKS\u2019s LTI support included external assignments that pass grades back to the LMS.</p>\n\n<p>Visit the <a href="http://www.aleks.com/highered/math/training_center">ALEKS Training Center</a> for directions on configuring your ALEKS Higher Education school account. Look for the \u2018LTI Integration\u2019 section.</p>\n',
      icon_image_url: null,
      id: 66,
      is_certified: true,
      is_installed: true,
      logo_image_url: 'http://www.edu-apps.org/tools/aleks/logo.png',
      name: 'ALEKS',
      preview_url: '',
      requires_secret: true,
      short_description:
        'ALEKS is an artificial intelligent assessment and learning system which uses adaptive questioning to quickly and accurately determine exactly what a student kno...',
      short_name: 'aleks',
      status: 'active',
      total_ratings: 2,
    },
    {
      app_type: 'custom',
      average_rating: 4,
      banner_image_url:
        'https://edu-app-center.s3.amazonaws.com/uploads/production/lti_app/banner_image/apprennet.png',
      config_options: [],
      config_xml_url: 'https://www.apprennet.com/lti-config.xml',
      custom_tags: ['Community', 'Postsecondary'],
      description:
        '\n<p>Integrate hands-on learning exercises into your course. With ApprenNet\u2019s LTI APP, you can add exercises to your course in which participants 1) submit video responses, 2) review their peers, 3) receive feedback and 4) engage with experts. Make e-learning interactive and social.</p>\n\n<p><a href="https://www.apprennet.com/users/sign_up_guide">Start a free trial!</a> and then, if you like what you see, request a key and secret by emailing contact@apprennet.com.</p>\n',
      icon_image_url: null,
      id: 127,
      is_certified: false,
      logo_image_url:
        'https://s3.amazonaws.com/assets01.apprennet.com/lti-bounty/apprennet-logo-2-72x72.png',
      name: 'ApprenNet',
      preview_url: 'https://www.youtube.com/embed/sJ81INPRNa0',
      requires_secret: true,
      short_description:
        "Integrate hands-on learning exercises into your course. With ApprenNet's LTI APP, you can add exercises to your course in which participants 1) submit video res...",
      short_name: 'apprennet',
      status: 'active',
      total_ratings: 1,
    },
  ]

  beforeAll(() => {
    $.getJSON = jest.fn()
    $.ajax = jest.fn()
  })

  beforeEach(() => {
    window.ENV = {context_asset_string: 'account_1'}
    store.setState({apps: defaultApps()})
  })

  afterEach(() => {
    store.reset()
  })

  afterAll(() => {
    window.ENV = {}
    $.getJSON = originalGetJSON
    $.ajax = originalAJAX
  })

  function renderAppList() {
    return render(<AppList baseUrl="/the/base/url" />)
  }

  it('renders loading indicator', () => {
    store.setState({isLoading: true})
    const {getByTestId} = renderAppList()
    expect(getByTestId(/Spinner/i)).toBeVisible()
  })

  it('does not apply focus to filter text input on render', () => {
    const {getByText} = renderAppList()
    expect(getByText('Filter by name')).not.toHaveFocus()
  })

  it('renders manage app list button if context type is account', () => {
    const stuff = renderAppList()
    const {getByText} = stuff
    expect(getByText('Manage App List')).toBeVisible()
  })

  it('does not render manage app list button if context type is not account', () => {
    window.ENV = {context_asset_string: 'course_1'}
    const {queryByText} = renderAppList()
    expect(queryByText('Manage App List')).not.toBeInTheDocument()
  })

  it('renders view app configurations link', () => {
    const {getByText} = renderAppList()
    expect(getByText('View App Configurations')).toBeVisible()
  })

  it('follows the app configurations button to the right place', () => {
    const {getByText} = renderAppList()
    fireEvent.click(getByText('View App Configurations'))
    expect(page.redirect).toHaveBeenCalledWith('/configurations')
  })

  it('renders app filters', () => {
    const {getByText} = renderAppList()
    expect(getByText('All')).toBeVisible()
    expect(getByText('Not Installed')).toBeVisible()
    expect(getByText('Installed')).toBeVisible()
  })
})
