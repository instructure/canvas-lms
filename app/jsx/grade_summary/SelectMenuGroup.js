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

import PropTypes from 'prop-types';
import React from 'react';

import Button from '@instructure/ui-buttons/lib/components/Button';
import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex';
import PresentationContent from '@instructure/ui-a11y/lib/components/PresentationContent';
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent';
import Text from '@instructure/ui-elements/lib/components/Text';

import {showFlashError} from '../shared/FlashAlert';
import I18n from 'i18n!grade_summary';
import SelectMenu from '../grade_summary/SelectMenu';

export default class SelectMenuGroup extends React.Component {
  static propTypes = {
    assignmentSortOptions: PropTypes.arrayOf(PropTypes.array).isRequired,
    courses: PropTypes.arrayOf(PropTypes.shape({
      id: PropTypes.string.isRequired,
      nickname: PropTypes.string.isRequired,
      url: PropTypes.string.isRequired,
      gradingPeriodSetId: PropTypes.string
    })).isRequired,
    currentUserID: PropTypes.string.isRequired,
    displayPageContent: PropTypes.func.isRequired,
    goToURL: PropTypes.func.isRequired,
    gradingPeriods: PropTypes.arrayOf(PropTypes.shape({
      id: PropTypes.string.isRequired,
      title: PropTypes.string.isRequired,
    })).isRequired,
    saveAssignmentOrder: PropTypes.func.isRequired,
    selectedAssignmentSortOrder: PropTypes.string.isRequired,
    selectedCourseID: PropTypes.string.isRequired,
    selectedGradingPeriodID: PropTypes.string,
    selectedStudentID: PropTypes.string.isRequired,
    students: PropTypes.arrayOf(PropTypes.shape({
      id: PropTypes.string.isRequired,
      name: PropTypes.string.isRequired
    })).isRequired
  };

  static defaultProps = {
    selectedGradingPeriodID: null
  };

  constructor (props) {
    super(props);

    this.onSelectAssignmentSortOrder = this.onSelection.bind(this, 'assignmentSortOrder');
    this.onSelectCourse = this.onSelection.bind(this, 'courseID');
    this.onSelectStudent = this.onSelection.bind(this, 'studentID');
    this.onSelectGradingPeriod = this.onSelection.bind(this, 'gradingPeriodID');

    this.state = {
      assignmentSortOrder: props.selectedAssignmentSortOrder,
      courseID: props.selectedCourseID,
      gradingPeriodID: props.selectedGradingPeriodID,
      processing: false,
      studentID: props.selectedStudentID
    };
  }

  componentDidMount () {
    this.props.displayPageContent();
  }

  onSelection = (state, event) => {
    this.setState({ [state]: event.target.value });
  }

  onSubmit = () => {
    this.setState({ processing: true }, () => {
      if (this.state.assignmentSortOrder !== this.props.selectedAssignmentSortOrder) {
        this.props.saveAssignmentOrder(this.state.assignmentSortOrder)
          .then(this.reloadPage)
          .catch((error) => {
            showFlashError(I18n.t('An error occurred. Please try again.'))(error);
            this.setState({ processing: false });
          });
      } else {
        this.reloadPage();
      }
    });
  };

  anySelectMenuChanged (states) {
    const stateToProps = {
      assignmentSortOrder: 'selectedAssignmentSortOrder',
      courseID: 'selectedCourseID',
      gradingPeriodID: 'selectedGradingPeriodID',
      studentID: 'selectedStudentID',
    };

    return states.some(state => this.state[state] !== this.props[stateToProps[state]]);
  }

  gradingPeriodOptions () {
    return [{ id: '0', title: I18n.t('All Grading Periods') }].concat(this.props.gradingPeriods);
  }

  noSelectMenuChanged () {
    return !this.anySelectMenuChanged(['courseID', 'studentID', 'gradingPeriodID', 'assignmentSortOrder']);
  }

  reloadPage = () => {
    const { state: { courseID: currentlySelectedCourseId }, props: { selectedCourseID: initialCourseId } } = this;
    const initialCourse = this.props.courses.find(course => course.id === initialCourseId)
    const selectedCourse = this.props.courses.find(course => course.id === currentlySelectedCourseId)

    const baseURL = selectedCourse.url
    const studentURL = this.state.studentID === this.props.currentUserID ? '' : `/${this.state.studentID}`
    let params

    if (selectedCourse.gradingPeriodSetId && initialCourse.gradingPeriodSetId === selectedCourse.gradingPeriodSetId) {
      params = this.state.gradingPeriodID ? `?grading_period_id=${this.state.gradingPeriodID}` : ''
    } else {
      params = ''
    }

    this.props.goToURL(`${baseURL}${studentURL}${params}`)
  };

  render () {
    return (
      <Flex
        alignItems="end"
        wrapItems="true">

        <FlexItem>
          {this.props.students.length > 1 &&
            <SelectMenu
              defaultValue={this.props.selectedStudentID}
              disabled={this.anySelectMenuChanged(['courseID'])}
              id="student_select_menu"
              label={I18n.t('Student')}
              onChange={this.onSelectStudent}
              options={this.props.students}
              textAttribute="name"
              valueAttribute="id"
            />
          }

          {this.props.gradingPeriods.length > 0 &&
            <SelectMenu
              defaultValue={this.props.selectedGradingPeriodID}
              disabled={this.anySelectMenuChanged(['courseID'])}
              id="grading_period_select_menu"
              label={I18n.t('Grading Period')}
              onChange={this.onSelectGradingPeriod}
              options={this.gradingPeriodOptions()}
              textAttribute="title"
              valueAttribute="id"
            />
          }

          {this.props.courses.length > 1 &&
            <SelectMenu
              defaultValue={this.props.selectedCourseID}
              disabled={this.anySelectMenuChanged(['studentID', 'gradingPeriodID', 'assignmentSortOrder'])}
              id="course_select_menu"
              label={I18n.t('Course')}
              onChange={this.onSelectCourse}
              options={this.props.courses}
              textAttribute="nickname"
              valueAttribute="id"
            />
          }

          <SelectMenu
            defaultValue={this.props.selectedAssignmentSortOrder}
            disabled={this.anySelectMenuChanged(['courseID'])}
            id="assignment_sort_order_select_menu"
            label={I18n.t('Arrange By')}
            onChange={this.onSelectAssignmentSortOrder}
            options={this.props.assignmentSortOptions}
            textAttribute={0}
            valueAttribute={1}
          />
        </FlexItem>

        <FlexItem margin="0 0 0 small">
          <Button
            disabled={this.state.processing || this.noSelectMenuChanged()}
            id="apply_select_menus"
            onClick={this.onSubmit}
            type="submit"
            size="medium"
            variant="primary"
          >
            <PresentationContent><Text>{I18n.t('Apply')}</Text></PresentationContent>
            <ScreenReaderContent>
              {I18n.t('Apply filters. Note: clicking this button will cause the page to reload.')}
            </ScreenReaderContent>
          </Button>
        </FlexItem>
      </Flex>
    );
  }
}
