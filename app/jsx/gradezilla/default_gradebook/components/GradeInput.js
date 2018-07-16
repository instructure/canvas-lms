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
import { arrayOf, bool, func, number, oneOf, shape, string } from 'prop-types';
import Select from '@instructure/ui-core/lib/components/Select';
import TextInput from '@instructure/ui-forms/lib/components/TextInput';
import Text from '@instructure/ui-elements/lib/components/Text';
import I18n from 'i18n!gradebook';
import GradeFormatHelper from '../../../gradebook/shared/helpers/GradeFormatHelper';
import {parseTextValue} from '../../../grading/helpers/GradeInputHelper'
import {isUnusuallyHigh} from '../../../grading/helpers/OutlierScoreHelper'

function normalizeSubmissionGrade (props) {
  const { submission, assignment, enterGradesAs: formatType, gradingScheme } = props;
  const gradeToNormalize = submission.enteredGrade;

  if (props.pendingGradeInfo && props.pendingGradeInfo.excused) {
    return GradeFormatHelper.excused();
  } else if (props.pendingGradeInfo) {
    return GradeFormatHelper.formatGradeInfo(props.pendingGradeInfo, {defaultValue: ''})
  }

  if (!gradeToNormalize) {
    return '';
  }

  const formatOptions = {
    formatType,
    gradingScheme,
    pointsPossible: assignment.pointsPossible,
    version: 'entered'
  };

  return GradeFormatHelper.formatSubmissionGrade(submission, formatOptions)
}

function hasGradeChanged (props, state) {
  if (props.pendingGradeInfo) {
    if (props.pendingGradeInfo.valid) {
      return false
    }

    return state.grade !== props.pendingGradeInfo.grade
  }

  const normalizedEnteredGrade = normalizeSubmissionGrade(props);
  return (normalizedEnteredGrade !== state.grade) && (props.submission.enteredGrade !== state.grade)
}

function assignmentLabel (assignment, formatType) {
  switch (formatType) {
    case 'points': {
      const points = I18n.n(assignment.pointsPossible, { strip_insignificant_zeros: true, precision: 2 });
      return I18n.t('Grade out of %{points}', { points });
    }
    case 'percent': {
      const percentage = I18n.n(100, { percentage: true, precision: 2, strip_insignificant_zeros: true });
      return I18n.t('Grade out of %{percentage}', { percentage });
    }
    case 'gradingScheme': {
      return I18n.t('Letter Grade');
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

function stateFromProps (props) {
  let normalizedGrade;

  if (props.enterGradesAs === 'passFail') {
    normalizedGrade = props.assignment.anonymizeStudents ? null : props.submission.enteredGrade;
  } else {
    const propsCopy = { ...props };

    if (props.assignment.anonymizeStudents) {
      const submission = { ...props.submission, enteredScore: null };
      propsCopy.submission = submission;
    }

    normalizedGrade = normalizeSubmissionGrade(propsCopy);
  }

  return {
    formattedGrade: normalizedGrade,
    grade: normalizedGrade
  };
}

export default class GradeInput extends React.Component {
  static propTypes = {
    assignment: shape({
      anonymizeStudents: bool.isRequired,
      gradingType: oneOf(['gpa_scale', 'letter_grade', 'not_graded', 'pass_fail', 'points', 'percent']).isRequired,
      pointsPossible: number
    }).isRequired,
    disabled: bool,
    enterGradesAs: oneOf(['points', 'percent', 'passFail', 'gradingScheme']).isRequired,
    gradingScheme: arrayOf(Array).isRequired,
    onSubmissionUpdate: func,
    pendingGradeInfo: shape({
      excused: bool.isRequired,
      grade: string,
      valid: bool.isRequired
    }),
    submission: shape({
      enteredGrade: string,
      enteredScore: number,
      excused: bool.isRequired,
      id: string
    }).isRequired,
    submissionUpdating: bool
  };

  static defaultProps = {
    disabled: false,
    pendingGradeInfo: null,
    onSubmissionUpdate () {},
    submissionUpdating: false
  };

  constructor (props) {
    super(props);

    this.handleSelectChange = this.handleSelectChange.bind(this);
    this.handleTextChange = this.handleTextChange.bind(this);
    this.handleTextBlur = this.handleTextBlur.bind(this);
    this.handleGradeChange = this.handleGradeChange.bind(this);

    this.state = stateFromProps(props);
  }

  componentWillReceiveProps (nextProps) {
    const submissionChanged = this.props.submission.id !== nextProps.submission.id;
    const submissionUpdated = this.props.submissionUpdating && !nextProps.submissionUpdating;

    if (submissionChanged || submissionUpdated) {
      this.setState(stateFromProps(nextProps));
    }
  }

  handleTextBlur () {
    const enteredGrade = this.state.grade.trim();

    this.setState({
      formattedGrade: GradeFormatHelper.isExcused(enteredGrade) ? GradeFormatHelper.excused() : enteredGrade,
      grade: this.state.grade.trim()
    }, () => {
      if (hasGradeChanged(this.props, this.state)) {
        this.handleGradeChange();
      }
    });
  }

  handleTextChange (event) {
    this.setState({
      formattedGrade: event.target.value,
      grade: event.target.value
    });
  }

  handleSelectChange (event) {
    this.setState({
      grade: event.target.value
    }, this.handleGradeChange);
  }

  handleGradeChange () {
    const gradingData = parseTextValue(this.state.grade, {
      enterGradesAs: this.props.enterGradesAs,
      gradingScheme: this.props.gradingScheme,
      pointsPossible: this.props.assignment.pointsPossible
    })

    this.props.onSubmissionUpdate(this.props.submission, gradingData)
  }

  render() {
    if (this.props.assignment.gradingType === 'not_graded') {
      return <Text size="small" weight="bold">{ I18n.t('This assignment is not graded.') }</Text>
    }

    const inputProps = {
      disabled: this.props.disabled || this.props.submissionUpdating || this.props.submission.excused,
      id: 'grade-detail-tray--grade-input',
      label: assignmentLabel(this.props.assignment, this.props.enterGradesAs)
    };

    if (this.props.enterGradesAs === 'passFail') {
      if (this.props.submission.excused) {
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

    const messages = [];
    const score = this.props.submission.enteredScore;
    if (this.props.pendingGradeInfo && !this.props.pendingGradeInfo.valid) {
      messages.push({type: 'error', text: I18n.t('This is not a valid grade')})
    } else if (score < 0) {
      messages.push({type: 'hint', text: I18n.t('This grade has negative points')})
    } else if (isUnusuallyHigh(score, this.props.assignment.pointsPossible)) {
      messages.push({type: 'hint', text: I18n.t('This grade is unusually high')})
    }

    return (
      <TextInput
        {...inputProps}
        inline
        messages={messages}
        onChange={this.handleTextChange}
        onBlur={this.handleTextBlur}
        placeholder="–"
        value={this.state.formattedGrade}
        width="6em"
      />
    );
  }
}
