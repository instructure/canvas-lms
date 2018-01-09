/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import React from 'react'
import CourseStore from '../epub_exports/CourseStore'
import CourseList from '../epub_exports/CourseList'

  var EpubExportApp = React.createClass({
    displayName: 'EpubExportApp',

    //
    // Preparation
    //

    getInitialState: function() {
      return CourseStore.getState();
    },
    handleCourseStoreChange () {
      this.setState(CourseStore.getState());
    },

    //
    // Lifecycle
    //

    componentDidMount () {
      CourseStore.addChangeListener(this.handleCourseStoreChange);
      CourseStore.getAll();
    },
    componentWillUnmount () {
      CourseStore.removeChangeListener(this.handleCourseStoreChange);
    },

    //
    // Rendering
    //

    render() {
      return (
        <CourseList courses={this.state} />
      );
    }
  });

export default EpubExportApp
