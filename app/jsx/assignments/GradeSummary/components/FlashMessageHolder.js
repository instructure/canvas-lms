/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import {Component} from 'react'
import {string} from 'prop-types'
import {connect} from 'react-redux'
import I18n from 'i18n!assignment_grade_summary'

import {showFlashAlert} from '../../../shared/FlashAlert'
import * as StudentActions from '../students/StudentActions'

class FlashMessageHolder extends Component {
  static propTypes = {
    loadStudentsStatus: string
  }

  static defaultProps = {
    loadStudentsStatus: null
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.loadStudentsStatus !== this.props.loadStudentsStatus) {
      if (nextProps.loadStudentsStatus === StudentActions.FAILURE) {
        showFlashAlert({
          message: I18n.t('There was a problem loading students.'),
          type: 'error'
        })
      }
    }
  }

  render() {
    return null
  }
}

function mapStateToProps(state) {
  return {
    loadStudentsStatus: state.students.loadStudentsStatus
  }
}

export default connect(mapStateToProps)(FlashMessageHolder)
