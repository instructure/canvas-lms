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
import { number, shape, string } from 'prop-types';
import Typography from 'instructure-ui/lib/components/Typography';
import I18n from 'i18n!gradebook';
import GradeFormatHelper from 'jsx/gradebook/shared/helpers/GradeFormatHelper';

export default function LatePolicyGrade (props) {
  const { grade } = props.submission;
  const pointsDeducted = I18n.n(-props.submission.pointsDeducted);
  let finalGrade;

  if (isNaN(grade)) {
    finalGrade = GradeFormatHelper.formatGrade(props.submission.grade);
  } else {
    finalGrade = GradeFormatHelper.formatGrade(props.submission.grade, { precision: 2 });
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'row' }}>
      <span style={{ flex: 1 }}>
        <Typography color="error" as="span">
          { I18n.t('Late Penalty: %{pointsDeducted}', { pointsDeducted }) }
        </Typography>
      </span>

      <span style={{ flex: 1 }}>
        <Typography color="secondary" as="span">
          { I18n.t('Final Grade: %{finalGrade}', { finalGrade }) }
        </Typography>
      </span>
    </div>
  );
}

LatePolicyGrade.propTypes = {
  submission: shape({
    grade: string,
    pointsDeducted: number
  }).isRequired
};
