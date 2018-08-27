/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import $ from 'jquery'
import _ from 'underscore'
import React from 'react'
import PropTypes from 'prop-types'
import I18n from 'i18n!course_wizard'
import ListItems from './ListItems'

  var courseNotSetUpItem = {
    text: I18n.t("Great, so you've got a course. Now what? Well, before you go publishing it to the world, you may want to check and make sure you've got the basics laid out.  Work through the list on the left to ensure that your course is ready to use."),
    warning: I18n.t("This course is visible only to teachers until it is published."),
    iconClass: 'icon-instructure'
  };

  var checklistComplete = {
    text: I18n.t("Now that your course is set up and available, you probably won't need this checklist anymore. But we'll keep it around in case you realize later you want to try something new, or you just want a little extra help as you make changes to your course content."),
    iconClass: 'icon-instructure'
  };

  var InfoFrame = React.createClass({
      displayName: 'InfoFrame',

      propTypes: {
        closeModal: PropTypes.func.isRequired,
        className: PropTypes.string
      },

      getInitialState: function () {
        return {
          itemShown: courseNotSetUpItem,
        };
      },

      componentWillMount: function () {
        if (window.ENV.COURSE_WIZARD.checklist_states.publish_step) {
          this.setState({
            itemShown: checklistComplete
          });
        }
      },

      componentWillReceiveProps: function (newProps) {
        this.getWizardItem(newProps.itemToShow);
      },

      getWizardItem: function (key) {
        var item = _.findWhere(ListItems, {key: key});

        this.setState({
          itemShown: item
        }, function () {
          var $messageBox = $(this.messageBox);
          var $messageIcon = $(this.messageIcon);

          // I would use .toggle, but it has too much potential to get all out
          // of whack having to be called twice to force the animation.

          // Remove the animation classes in case they are there already.
          $messageBox.removeClass('ic-wizard-box__message-inner--is-fired');
          $messageIcon.removeClass('ic-wizard-box__message-icon--is-fired');

          // Add them back
          setTimeout(function () {
            $messageBox.addClass('ic-wizard-box__message-inner--is-fired');
            $messageIcon.addClass('ic-wizard-box__message-icon--is-fired');
          }, 100);

          // Set the focus to the call to action 'button' if it's there
          // otherwise the text.
          if (this.callToAction) {
            this.callToAction.focus();
          } else {
            this.messageBox.focus();
          }

        });
      },

      getHref: function () {
        return this.state.itemShown.url || '#';
      },

      chooseHomePage: function (event) {
        event.preventDefault();
        this.props.closeModal();
        $('.choose_home_page_link').click();
      },


      renderButton: function () {
        if (this.state.itemShown.key === 'home_page') {
          return (<a ref={e => (this.callToAction = e)} onClick={this.chooseHomePage} className="Button Button--primary" aria-label={"Start task: "+this.state.itemShown.title} aria-describedby="ic-wizard-box__message-text">
            {this.state.itemShown.title}
          </a>
          );
        }
        if (this.state.itemShown.key === 'publish_course') {
          if (window.ENV.COURSE_WIZARD.permissions.can_change_course_state) {
            return (
              <form acceptCharset='UTF-8' action={window.ENV.COURSE_WIZARD.publish_course} method='post'>
                <input name='utf8' type='hidden' value='✓' />
                <input name='_method' type='hidden' value='put' />
                <input name='authenticity_token' type='hidden' value={$.cookie('_csrf_token')} />
                <input type='hidden' name='course[event]' value='offer'/>
                <button ref={e => (this.callToAction = e)} type='submit' className='Button Button--success'>{this.state.itemShown.title}</button>
              </form>
            );
          } else {
            return (
                <b>{I18n.t("You do not have permission to publish this course.")}</b>
            );
          }
        }
        if (this.state.itemShown.hasOwnProperty('title')) {
          return (
            <a ref={e => (this.callToAction = e)} href={this.getHref()} className="Button Button--primary" aria-label={"Start task: "+this.state.itemShown.title} aria-describedby="ic-wizard-box__message-text">
              {this.state.itemShown.title}
            </a>
          );
        }
        else if (this.state.itemShown.hasOwnProperty('warning')) {
          return <b>{this.state.itemShown.warning}</b>
        }
        else {
          return null;
        }
      },

      render: function () {
        return (
          <div className={this.props.className}>
            <h1 className='ic-wizard-box__headline'>
               {I18n.t('Next Steps')}
            </h1>
            <div className='ic-wizard-box__message'>
              <div className='ic-wizard-box__message-layout'>
                <div ref={e => (this.messageIcon = e)} className='ic-wizard-box__message-icon ic-wizard-box__message-icon--is-fired'>
                  <i className={this.state.itemShown.iconClass}></i>
                </div>
                <div ref={e => (this.messageBox = e)} tabIndex='-1' className='ic-wizard-box__message-inner ic-wizard-box__message-inner--is-fired'>
                  <p className='ic-wizard-box__message-text' id='ic-wizard-box__message-text'>
                    {this.state.itemShown.text}
                  </p>
                  <div className='ic-wizard-box__message-button'>
                    {this.renderButton()}
                  </div>
                </div>
              </div>
            </div>
          </div>
        );
      }
  });

export default InfoFrame
