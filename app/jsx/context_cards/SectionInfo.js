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

const sectionShape = PropTypes.shape({
  name: PropTypes.string.isRequired
});
const enrollmentsShape = PropTypes.shape({
  section: sectionShape.isRequired
});
const userShape = PropTypes.shape({
  enrollments: PropTypes.arrayOf(enrollmentsShape).isRequired
});

  class SectionInfo extends React.Component {
    static propTypes = {
      user: userShape.isRequired
    }

    render () {
      const sections = this.props.user.enrollments
        .map(e => e.section)
        .filter(s => s != null);

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
