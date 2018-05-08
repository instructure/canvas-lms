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

import React from 'react';
import themeable from '@instructure/ui-themeable/lib';
import {bool, string, arrayOf, shape} from 'prop-types';
import { courseShape } from '../plannerPropTypes';
import formatMessage from '../../format-message';
import ErrorAlert from '../ErrorAlert';

import View from '@instructure/ui-layout/lib/components/View';
import Heading from '@instructure/ui-elements/lib/components/Heading';
import Link from '@instructure/ui-elements/lib/components/Link';
import Spinner from '@instructure/ui-elements/lib/components/Spinner';
import Text from '@instructure/ui-elements/lib/components/Text';

import styles from './styles.css';
import theme from './theme.js';

export class GradesDisplay extends React.Component {
  static propTypes = {
    loading: bool,
    loadingError: string,
    courses: arrayOf(shape(courseShape)).isRequired,
  }

  static defaultProps = {
    loading: false,
  }

  scoreString (score) {
    const fixedScore = parseFloat(score);
    if (isNaN(fixedScore)) return formatMessage('No Grade');
    return `${fixedScore.toFixed(2)}%`;
  }

  renderSpinner () {
    return <View
      as="div"
      textAlign="center"
      margin="0 0 large 0"
    >
      <Spinner
        title={formatMessage("Grades are loading")}
        size="small"
      />
    </View>;
  }

  renderCaveat () {
    if (this.props.loading) return;
    if (this.props.courses.some(course => course.hasGradingPeriods)) {
      return <View as="div" textAlign="center">
        <Text size="x-small" fontStyle="italic">{
          formatMessage('*Only most recent grading period shown.')}
        </Text>
      </View>;
    }
  }

  renderGrades () {
    if (this.props.loadingError) return;
    return this.props.courses.map(course => {
      const courseNameStyles = {
        borderBottom: `solid thin`,
        borderBottomColor: course.color,
      };

      return <View key={course.id} as="div"
        margin="0 0 large 0"
      >
        <div className={styles.course} style={courseNameStyles}>
          <Link href={course.href}>
            <Text color="primary" size="small" transform="uppercase">
              {course.shortName}
            </Text>
          </Link>
        </div>
        <Text as="div" size="large" weight="light">{this.scoreString(course.score)}</Text>
      </View>;
    });
  }

  renderError () {
    if (this.props.loadingError) {
      return <ErrorAlert error={this.props.loadingError}>{formatMessage('Error loading grades')}</ErrorAlert>;
    }
  }

  render () {
    return <View>
      {this.renderError()}
      <View textAlign="center">
        <Heading level="h2" margin="0 0 large 0">
          <Text size="medium" weight="bold">{formatMessage('My Grades')}</Text>
        </Heading>
      </View>
      {this.props.loading ? this.renderSpinner() : this.renderGrades()}
      {this.renderCaveat()}
    </View>;
  }
}

export default themeable(theme, styles)(GradesDisplay);
