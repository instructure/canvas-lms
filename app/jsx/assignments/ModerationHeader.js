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
import I18n from 'i18n!moderated_grading'

  var Header = React.createClass({
    displayName: 'Header',

    propTypes: {
      anonymousModeratedMarkingEnabled: PropTypes.bool.isRequired,
      muted: PropTypes.bool.isRequired,
      onPublishClick: PropTypes.func.isRequired,
      onReviewClick: PropTypes.func.isRequired,
      onUnmuteClick: PropTypes.func.isRequired,
      published: PropTypes.bool.isRequired,
      selectedStudentCount: PropTypes.number.isRequired,
      inflightAction: PropTypes.shape({
        review: PropTypes.bool.isRequired,
        publish: PropTypes.bool.isRequired,
        unmute: PropTypes.bool.isRequired
      }).isRequired,
      permissions: PropTypes.shape({
        editGrades: PropTypes.bool.isRequired
      }).isRequired
    },

    noStudentSelected () {
      return this.props.selectedStudentCount === 0;
    },
    handlePublishClick () {
      // TODO: Make a better looking confirm one day
      var confirmMessage = I18n.t('Are you sure you want to do this? It cannot be undone and will override existing grades in the gradebook.')
      if (window.confirm(confirmMessage)) {
        this.props.onPublishClick();
      }
    },
    renderPublishedMessage () {
      if (this.props.published) {
        return (

          <div className="ic-notification">
            <div className="ic-notification__icon" aria-hidden='true' role="presentation">
              <i className="icon-info"></i>
            </div>
            <div className="ic-notification__content">
              <div className="ic-notification__message">
                <div className="ic-notification__title">
                  {I18n.t('Attention!')}
                </div>
                <span className="notification_message">
                  {I18n.t('This page cannot be modified because grades have already been posted.')}
                </span>
              </div>
            </div>
          </div>
        );
      }
    },

    handleUnmuteClick () {
      const confirmMessage = I18n.t('Are you sure you want to display grades for this assignment to students?');
      if (window.confirm(confirmMessage)) {
        this.props.onUnmuteClick();
      }
    },

    renderUnmuteButton () {
      const {published, muted, inflightAction} = this.props;
      const allowUnmute = published && muted && !inflightAction.unmute;
      return (
        <button
          type="button"
          className="ModeratedGrading__Header-UnmuteBtn Button"
          onClick={this.handleUnmuteClick}
          disabled={!allowUnmute}
        >
          {I18n.t('Display to Students')}
        </button>
      );
    },

    renderPostButton () {
      return this.props.permissions.editGrades && (
        <button
          ref={(p) => { this.publishBtn = p; }}
          type="button"
          className="ModeratedGrading__Header-PublishBtn Button Button--primary"
          onClick={this.handlePublishClick}
          disabled={this.props.published || this.props.inflightAction.publish}
        >
          {I18n.t('Post')}
        </button>
      );
    },

    render () {
      const showUnmuteButton = this.props.anonymousModeratedMarkingEnabled && this.props.permissions.editGrades

      return (
        <div>
          {this.renderPublishedMessage()}
          <div className='ModeratedGrading__Header ic-Action-header'>
            <div className='ic-Action-header__Primary'>
              <div className='ic-Action-header__Heading ModeratedGrading__Header-Instructions'>
                {I18n.t('Select students for review')}
              </div>
            </div>
            <div className='ic-Action-header__Secondary ModeratedGrading__Header-Buttons '>
              <button
                ref='addReviewerBtn'
                type='button'
                className='ModeratedGrading__Header-AddReviewerBtn Button'
                onClick={this.props.onReviewClick}
                disabled={
                  this.props.published ||
                  this.noStudentSelected() ||
                  this.props.inflightAction.review
                }
              >
                <span className='screenreader-only'>{I18n.t('Add a reviewer for the selected students')}</span>
                <span aria-hidden='true'>
                  <i className='icon-plus' />
                  {I18n.t(' Reviewer')}
                </span>
              </button>
              {this.renderPostButton()}
              {showUnmuteButton && this.renderUnmuteButton()}
            </div>
          </div>
      </div>
      );
    }

  });

export default Header
