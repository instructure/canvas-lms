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
import PropTypes from 'prop-types'
import _ from 'underscore'
import I18n from 'i18n!student_context_tray'

  class SectionInfo extends React.Component {
    static propTypes = {
      course: PropTypes.object,
      user: PropTypes.object
    }

    static defaultProps = {
      course: {},
      user: {}
    }

    get sections () {
      if (
        typeof this.props.user.enrollments === 'undefined' ||
        typeof this.props.course.sections === 'undefined'
      ) {
        return []
      }

      const sectionIds = this.props.user.enrollments.map((enrollment) => {
        return enrollment.course_section_id
      })

      return this.props.course.sections.filter((section) => {
        return _.contains(sectionIds, section.id)
      })
    }

    render () {
      const sections = this.sections

      if (sections.length > 0) {
        const sectionNames = sections.map((section) => {
          return section.name
        }).sort()
        return (
          <span>{I18n.t("Section: %{section_names}", { section_names: sectionNames.join(', ') })}</span>
        )
      } else { return null }
    }
  }

export default SectionInfo
