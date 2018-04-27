/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import PopoverMenu from '@instructure/ui-core/lib/components/PopoverMenu'
import { MenuItem, MenuItemSeparator, MenuItemGroup } from '@instructure/ui-core/lib/components/Menu'
import Text from '@instructure/ui-core/lib/components/Text'
import I18n from 'i18n!edit_rubric'
import $ from 'jquery'

class Rubric extends React.Component {
  static propTypes = {
    rubricId: PropTypes.string,
    rubricAssessmentId: PropTypes.string,
    rubric: PropTypes.object,
    rubricAssessment: PropTypes.object
  }

  render () {
    return (
      <span>I'm a dummy rubric {JSON.stringify(this.props.rubric)}</span>
    );
  }
}

export default Rubric
