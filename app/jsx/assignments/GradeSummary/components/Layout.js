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

import React, {Component} from 'react'
import {arrayOf, func, shape, string} from 'prop-types'
import {connect} from 'react-redux'
import Spinner from '@instructure/ui-elements/lib/components/Spinner'
import View from '@instructure/ui-layout/lib/components/View'
import I18n from 'i18n!assignment_grade_summary'

import '../../../context_cards/StudentContextCardTrigger'
import {loadStudents} from '../students/StudentActions'
import FlashMessageHolder from './FlashMessageHolder'
import GradesGrid from './GradesGrid'
import Header from './Header'

class Layout extends Component {
  static propTypes = {
    graders: arrayOf(
      shape({
        graderId: string.isRequired
      })
    ).isRequired,
    loadStudents: func.isRequired,
    provisionalGrades: shape({}).isRequired,
    students: arrayOf(
      shape({
        id: string.isRequired
      })
    ).isRequired
  }

  componentDidMount() {
    if (this.props.graders.length) {
      this.props.loadStudents()
    }
  }

  render() {
    return (
      <div>
        <FlashMessageHolder />

        <Header />

        {this.props.graders.length > 0 && (
          <View as="div" margin="large 0 0 0">
            {this.props.students.length > 0 ? (
              <GradesGrid
                graders={this.props.graders}
                grades={this.props.provisionalGrades}
                students={this.props.students}
              />
            ) : (
              <Spinner title={I18n.t('Students are loading')} />
            )}
          </View>
        )}
      </div>
    )
  }
}

function mapStateToProps(state) {
  return {
    graders: state.context.graders,
    provisionalGrades: state.grades.provisionalGrades,
    students: state.students.list
  }
}

function mapDispatchToProps(dispatch) {
  return {
    loadStudents() {
      dispatch(loadStudents())
    }
  }
}

export default connect(mapStateToProps, mapDispatchToProps)(Layout)
