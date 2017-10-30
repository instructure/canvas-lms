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

import React from 'react';
import { bool, func, number, oneOf, shape, string } from 'prop-types';
import Select from 'instructure-ui/lib/components/Select';
import TextInput from 'instructure-ui/lib/components/TextInput';
import Typography from 'instructure-ui/lib/components/Typography';
import I18n from 'i18n!gradebook';
import GradeFormatHelper from 'jsx/gradebook/shared/helpers/GradeFormatHelper';

function normalizeGrade (grade) {
  return GradeFormatHelper.formatGrade(grade, { defaultValue: null });
}

function normalizeSubmissionGrade (submission) {
  if (submission.excused) {
    return GradeFormatHelper.excused();
  }
  return normalizeGrade(submission.enteredGrade);
}

function gradeHasChanged (props, state) {
  return normalizeGrade(props.submission.enteredGrade) !== normalizeGrade(state.grade);
}

function assignmentLabel (assignment) {
  switch (assignment.gradingType) {
    case 'points': {
      const points = I18n.n(assignment.pointsPossible, { strip_insignificant_zeros: true, precision: 2 });
      return I18n.t('Grade out of %{points}', { points });
    }
    case 'percent': {
      const percentage = I18n.n(100, { percentage: true, precision: 2, strip_insignificant_zeros: true });
      return I18n.t('Grade out of %{percentage}', { percentage });
    }
    case 'letter_grade': {
      return I18n.t('Letter Grade');
    }
    case 'gpa_scale': {
      return I18n.t('Grade Point Average');
    }
    default: {
      return I18n.t('Grade');
    }
  }
}

function ExcusedSelect (props) {
  return (
    <Select {...props}>
      <option value="">{ I18n.t('Excused') }</option>
    </Select>
  );
}

function CompleteIncompleteSelect (props) {
  return (
    <Select {...props}>
      <option value="">{ I18n.t('Ungraded') }</option>
      <option value="complete">{ I18n.t('Complete') }</option>
      <option value="incomplete">{ I18n.t('Incomplete') }</option>
    </Select>
  );
}

export default class GradeInput extends React.Component {
  static propTypes = {
    assignment: shape({
      gradingType: oneOf(['gpa_scale', 'letter_grade', 'not_graded', 'pass_fail', 'points', 'percent']).isRequired,
      pointsPossible: number
    }).isRequired,
    disabled: bool,
    onSubmissionUpdate: func,
    submission: shape({
      enteredGrade: string,
      excused: bool.isRequired,
      id: string
    }).isRequired,
    submissionUpdating: bool
  };

  static defaultProps = {
    disabled: false,
    onSubmissionUpdate () {},
    submissionUpdating: false
  };

  constructor (props) {
    super(props);

    this.state = {
      excused: props.submission.excused,
      grade: normalizeSubmissionGrade(props.submission)
    };

    this.handleSelectChange = this.handleSelectChange.bind(this);
    this.handleTextChange = this.handleTextChange.bind(this);
    this.handleTextBlur = this.handleTextBlur.bind(this);
    this.handleGradeChange = this.handleGradeChange.bind(this);
  }

  componentWillReceiveProps (nextProps) {
    const submissionChanged = this.props.submission.id !== nextProps.submission.id;
    const submissionUpdated = this.props.submissionUpdating && !nextProps.submissionUpdating;

    if (submissionChanged || submissionUpdated) {
      this.setState({
        excused: nextProps.submission.excused,
        grade: normalizeSubmissionGrade(nextProps.submission)
      });
    }
  }

  handleTextBlur () {
    const enteredGrade = this.state.grade.trim();
    const excused = GradeFormatHelper.isExcused(enteredGrade);

    this.setState({
      excused,
      grade: excused ? GradeFormatHelper.excused() : enteredGrade
    }, () => {
      if (gradeHasChanged(this.props, this.state)) {
        this.handleGradeChange();
      }
    });
  }

  handleTextChange (event) {
    this.setState({
      grade: event.target.value
    });
  }

  handleSelectChange (event) {
    this.setState({
      grade: event.target.value
    }, this.handleGradeChange);
  }

  handleGradeChange () {
    const submission = { ...this.props.submission };

    if (this.state.excused) {
      submission.excused = true;
      submission.enteredGrade = null;
    } else {
      submission.excused = false;
      submission.enteredGrade = this.state.grade;
    }

    this.props.onSubmissionUpdate(submission);
  }

  render () {
    if (this.props.assignment.gradingType === 'not_graded') {
      return <Typography size="small" weight="bold">{ I18n.t('This assignment is not graded.') }</Typography>
    }

    const inputProps = {
      disabled: this.props.disabled || this.props.submissionUpdating || this.state.excused,
      id: 'grade-detail-tray--grade-input',
      label: assignmentLabel(this.props.assignment)
    };

    if (this.props.assignment.gradingType === 'pass_fail') {
      if (this.state.excused) {
        return <ExcusedSelect {...inputProps} />;
      }

      return (
        <CompleteIncompleteSelect
          {...inputProps}
          onChange={this.handleSelectChange}
          value={this.state.grade == null ? '' : this.state.grade}
        />
      );
    }

    return (
      <TextInput
        {...inputProps}
        inline
        onChange={this.handleTextChange}
        onBlur={this.handleTextBlur}
        value={this.state.grade == null ? '–' : this.state.grade}
        width="6em"
      />
    );
  }
}
