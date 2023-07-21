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

import $ from 'jquery'
import config from '../../../config'
import {useScope as useI18nScope} from '@canvas/i18n'
import quizStatistics from '../../../stores/statistics'
import React from 'react'

const I18n = useI18nScope('quiz_statistics')

const SectionLink = props => (
  <li
    role="presentation"
    onClick={e => {
      e.preventDefault()
      quizStatistics.filterForSection(props.sectionId)
    }}
  >
    <button type="button" className="btn-link" id="toolbar-2" role="menuitem">
      {props.name}
    </button>
  </li>
)

class SectionSelect extends React.Component {
  state = {
    sections: [],
  }

  componentDidMount() {
    $.ajax({
      url: config.courseSectionsUrl,
      data: {all: true},
      dataType: 'json',
      cache: false,
      success: sections => {
        this.setState({sections})
      },
    })
  }

  render() {
    let sectionTitle = I18n.t('Section Filter')
    if (config.section_ids && config.section_ids !== 'all') {
      sectionTitle = $.grep(this.state.sections, function (e) {
        return e.id == config.section_ids
      })[0].name
    }
    const sectionNodes = this.state.sections.map(function (section) {
      return (
        <SectionLink
          key={`${section.id}-${section.name}`}
          sectionId={section.id}
          name={section.name}
        />
      )
    })

    return (
      <div className="section_selector inline al-dropdown__container">
        <button className="al-trigger btn" type="button">
          {sectionTitle}
          <i className="icon-mini-arrow-down" aria-hidden="true" />
          <span className="screenreader-only">{I18n.t('Section Filter')}</span>
        </button>
        {/* eslint-disable-next-line jsx-a11y/role-supports-aria-props */}
        <ul
          id="toolbar-1"
          className="al-options"
          style={{maxHeight: '375px', overflowY: 'scroll'}}
          role="menu"
          tabIndex="0"
          aria-hidden="true"
          aria-expanded="false"
          aria-activedescendant="toolbar-2"
        >
          <SectionLink key="all" sectionId="all" name="All Sections" />
          {sectionNodes}
        </ul>
      </div>
    )
  }
}

export default SectionSelect
