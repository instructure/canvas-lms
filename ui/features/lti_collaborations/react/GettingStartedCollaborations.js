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
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('react_collaborations')

class GettingStartedCollaborations extends React.Component {
  renderContent() {
    let header, content, link

    if (this.props.ltiCollaborators.ltiCollaboratorsData.length === 0) {
      if (ENV.current_user_roles.indexOf('teacher') !== -1) {
        header = I18n.t('No Collaboration Apps')
        content = I18n.t(
          'Collaborations are web-based tools to work collaboratively on tasks like taking notes or grouped papers. Get started by adding a collaboration app.'
        )
        link = (
          <a rel="external" href={I18n.t('#community.basics_collaborations')}>
            {I18n.t('Learn more about collaborations')}
          </a>
        )
      } else {
        header = I18n.t('No Collaboration Apps')
        content = I18n.t(
          'You have no Collaboration apps configured. Talk to your teacher to get some set up.'
        )
        link = null
      }
    } else {
      header = I18n.t('Getting started with Collaborations')
      content = I18n.t(
        'Collaborations are web-based tools to work collaboratively on tasks like taking notes or grouped papers. Talk to your teacher to get started.'
      )
      if (ENV.CREATE_PERMISSION) {
        content = I18n.t(
          'Collaborations are web-based tools to work collaboratively on tasks like taking notes or grouped papers. Get started by clicking on the "+ Collaboration" button.'
        )
      }
      link = (
        <a href={I18n.t('#community.basics_collaborations')}>
          {I18n.t('Learn more about collaborations')}
        </a>
      )
    }
    return (
      <div>
        <h2 className="ic-Action-header__Heading">{header}</h2>
        <p>{content}</p>
        {link}
      </div>
    )
  }

  render() {
    return (
      <div className="GettingStartedCollaborations">
        <div className="image-collaborations-container">
          <img
            aria-hidden={true}
            alt=""
            className="image-collaborations"
            src="/images/svg-icons/icon-collaborations.svg"
          />
        </div>
        <div className="Collaborations--GettingStarted">{this.renderContent()}</div>
      </div>
    )
  }
}

export default GettingStartedCollaborations
