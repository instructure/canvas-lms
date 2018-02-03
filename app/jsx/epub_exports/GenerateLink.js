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
import PropTypes from 'prop-types'
import I18n from 'i18n!epub_exports'
import classnames from 'classnames'
import _ from 'underscore'
import CourseEpubExportStore from '../epub_exports/CourseStore'

  var GenerateLink = React.createClass({
    displayName: 'GenerateLink',
    propTypes: {
      course: PropTypes.object.isRequired
    },

    epubExport () {
      return this.props.course.epub_export || {};
    },
    showGenerateLink () {
      return _.isEmpty(this.epubExport()) || (
        _.isObject(this.epubExport().permissions) &&
        this.epubExport().permissions.regenerate
      );
    },

    //
    // Preparation
    //

    getInitialState: function() {
      return {
        triggered: false
      };
    },

    //
    // Rendering
    //

    render: function() {
      var text = {};

      if (!this.showGenerateLink() && !this.state.triggered)
        return null;

      text[I18n.t("Regenerate ePub")] =
        _.isObject(this.props.course.epub_export) &&
        !this.state.triggered;
      text[I18n.t("Generate ePub")] =
        !_.isObject(this.props.course.epub_export) &&
        !this.state.triggered;
      text[I18n.t("Generating...")] = this.state.triggered;

      if (this.state.triggered) {
        return (
          <span>
            <i className="icon-refresh" aria-hidden="true"></i>
            {classnames(text)}
          </span>
        );
      } else {
        return (
          <button className="Button Button--link" onClick={this._onClick}>
            <i className="icon-refresh" aria-hidden="true"></i>
            {classnames(text)}
          </button>
        );
      };
    },

    //
    // Event handling
    //

    _onClick: function(e) {
      e.preventDefault();
      this.setState({
        triggered: true
      });
      setTimeout(function() {
        this.setState({
          triggered: false
        });
      }.bind(this), 800);
      CourseEpubExportStore.create(this.props.course.id);
    }
  });

export default GenerateLink
