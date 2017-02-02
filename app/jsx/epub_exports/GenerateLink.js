import React from 'react'
import I18n from 'i18n!epub_exports'
import classnames from 'classnames'
import _ from 'underscore'
import CourseEpubExportStore from 'jsx/epub_exports/CourseStore'

  var GenerateLink = React.createClass({
    displayName: 'GenerateLink',
    propTypes: {
      course: React.PropTypes.object.isRequired
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
