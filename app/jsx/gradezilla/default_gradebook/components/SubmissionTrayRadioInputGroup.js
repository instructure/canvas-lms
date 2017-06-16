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
import { bool, number, shape, string } from 'prop-types';
import FormFieldGroup from 'instructure-ui/lib/components/FormFieldGroup';
import ScreenReaderContent from 'instructure-ui/lib/components/ScreenReaderContent';
import SubmissionTrayRadioInput from 'jsx/gradezilla/default_gradebook/components/SubmissionTrayRadioInput';
import { statusesTitleMap } from 'jsx/gradezilla/default_gradebook/constants/statuses';
import I18n from 'i18n!gradebook';

function checkedValue (submission) {
  if (submission.excused) {
    return 'excused';
  } else if (submission.missing) {
    return 'missing';
  } else if (submission.late) {
    return 'late';
  }

  return 'none';
}

export default class SubmissionTrayRadioInputGroup extends React.Component {
  constructor (props) {
    super(props);
    this.state = { checkedValue: checkedValue(props.submission) };
  }

  handleRadioInputChanged = ({ target: { value } }) => {
    this.setState({ checkedValue: value });
  }

  render () {
    const description = <ScreenReaderContent>{I18n.t('Submission status')}</ScreenReaderContent>;
    const radioOptions = ['none', 'late', 'missing', 'excused'].map(status =>
      <SubmissionTrayRadioInput
        key={status}
        checked={this.state.checkedValue === status}
        color={this.props.colors[status]}
        latePolicy={this.props.latePolicy}
        locale={this.props.locale}
        onChange={this.handleRadioInputChanged}
        submission={this.props.submission}
        text={statusesTitleMap[status] || I18n.t('None')}
        value={status}
      />
    );

    return <FormFieldGroup description={description} rowSpacing="none">{radioOptions}</FormFieldGroup>;
  }
}

SubmissionTrayRadioInputGroup.propTypes = {
  colors: shape({
    late: string.isRequired,
    missing: string.isRequired,
    excused: string.isRequired
  }).isRequired,
  latePolicy: shape({
    lateSubmissionInterval: string.isRequired
  }).isRequired,
  locale: string.isRequired,
  submission: shape({
    excused: bool.isRequired,
    late: bool.isRequired,
    missing: bool.isRequired,
    secondsLate: number.isRequired
  }).isRequired
};
