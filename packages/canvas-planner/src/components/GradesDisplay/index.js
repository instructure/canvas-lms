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
import {arrayOf, shape} from 'prop-types';
import { courseShape } from '../plannerPropTypes';
import formatMessage from '../../format-message';

import Container from '@instructure/ui-container/lib/components/Container';
import Text from '@instructure/ui-elements/lib/components/Text';

export class GradesDisplay extends React.Component {
  static propTypes = {
    courses: arrayOf(shape(courseShape)).isRequired,
  }

  renderGrades () {
    return this.props.courses.map(course => {
      const courseNameStyles = {
        borderBottom: `solid thin ${course.color}`
      };
      return <Container key={course.id} as="div"
        margin="0 0 large 0"
      >
        <div style={courseNameStyles}>
          <Text size="small" transform="uppercase">
            {course.shortName}
          </Text>
        </div>
        <Text as="div" size="large" weight="light">98.36%</Text>
      </Container>;
    });
  }

  render () {
    return <Container>
      <Container as="div" textAlign="center" margin="0 0 large 0">
        <Text size="medium" weight="bold">{formatMessage('My Grades')}</Text>
      </Container>
      {this.renderGrades()}
      <Container as="div" textAlign="center">
        <Text size="x-small" fontStyle="italic">{
          formatMessage('*Only most recent grading period shown.')}
        </Text>
      </Container>
    </Container>;
  }
}

export default GradesDisplay;
