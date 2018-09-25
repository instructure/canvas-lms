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
import { bool, shape, string } from 'prop-types';
import $ from 'jquery';
import 'jquery.instructure_date_and_time'
import environment from '../gradebook-history/environment';
import GradeFormatHelper from '../gradebook/shared/helpers/GradeFormatHelper';
import NumberHelper from '../shared/helpers/numberHelper';
import I18n from 'i18n!gradebook_history';
import IconOffLine from '@instructure/ui-icons/lib/Line/IconOff';
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent';
import Tooltip from '@instructure/ui-overlays/lib/components/Tooltip';

function anonymouslyGraded (gradedAnonymously) {
  return gradedAnonymously ? (
    <div>
      <Tooltip tip={I18n.t('Anonymously graded')} on={['focus', 'hover']}>
        <span role="presentation" tabIndex="0">
          <IconOffLine />
          <ScreenReaderContent>{I18n.t('Anonymously graded')}</ScreenReaderContent>
        </span>
      </Tooltip>
    </div>
  ) : (
    <ScreenReaderContent>{I18n.t('Not anonymously graded')}</ScreenReaderContent>
  );
}

function displayGrade (grade, possible, displayAsPoints) {
  // show the points possible if the assignment is set to display grades as
  // "points" and the grade can be parsed as a number
  if (displayAsPoints && NumberHelper.validate(grade)) {
    return `${GradeFormatHelper.formatGrade(grade, { defaultValue: '–' })}/${GradeFormatHelper.formatGrade(possible)}`;
  }

  return GradeFormatHelper.formatGrade(grade, { defaultValue: '–' });
}

function displayStudentName (studentName, assignment) {
  if (assignment.anonymousGrading && assignment.muted) {
    return I18n.t('Not available; assignment is anonymous');
  }

  if (!studentName) {
    return I18n.t('Not available');
  }

  return studentName;
}

function SearchResultsRow (props) {
  const {
    assignment,
    date,
    displayAsPoints,
    gradedAnonymously,
    grader,
    gradeAfter,
    gradeBefore,
    gradeCurrent,
    pointsPossibleAfter,
    pointsPossibleBefore,
    pointsPossibleCurrent,
    student
  } = props.item;

  return (
    <tr>
      <td>{$.datetimeString(new Date(date), { format: 'medium', timezone: environment.timezone() })}</td>
      <td>{anonymouslyGraded(gradedAnonymously)}</td>
      <td>{displayStudentName(student, assignment)}</td>
      <td>{grader || I18n.t('Not available')}</td>
      <td>{assignment.name || I18n.t('Not available')}</td>
      <td>{displayGrade(gradeBefore, pointsPossibleBefore, displayAsPoints)}</td>
      <td>{displayGrade(gradeAfter, pointsPossibleAfter, displayAsPoints)}</td>
      <td>{displayGrade(gradeCurrent, pointsPossibleCurrent, displayAsPoints)}</td>
    </tr>
  );
}

SearchResultsRow.propTypes = {
  item: shape({
    assignment: shape({
      anonymousGrading: bool.isRequired,
      muted: bool.isRequired,
      name: string.isRequired
    }),
    date: string.isRequired,
    displayAsPoints: bool.isRequired,
    gradedAnonymously: bool.isRequired,
    grader: string.isRequired,
    gradeAfter: string.isRequired,
    gradeBefore: string.isRequired,
    gradeCurrent: string.isRequired,
    pointsPossibleAfter: string.isRequired,
    pointsPossibleBefore: string.isRequired,
    pointsPossibleCurrent: string.isRequired,
    student: string.isRequired
  }).isRequired
};

export default SearchResultsRow;
