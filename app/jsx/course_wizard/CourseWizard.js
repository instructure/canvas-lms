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
import React from 'react'
import PropTypes from 'prop-types'
import I18n from 'i18n!course_wizard'
import ReactModal from 'react-modal'
import InfoFrame from './InfoFrame'
import Checklist from './Checklist'
import userSettings from 'compiled/userSettings'
import 'compiled/jquery.rails_flash_notifications'

  const modalOverrides = {
    overlay : {
      backgroundColor: 'transparent'
    },
    content : {
      position: 'static',
      top: '0',
      left: '0',
      right: 'auto',
      bottom: 'auto',
      borderRadius: '0',
      border: 'none',
      padding: '0'
    }
  };

  var CourseWizard = React.createClass({
      displayName: 'CourseWizard',

      propTypes: {
        showWizard: PropTypes.bool,
        overlayClassName: PropTypes.string
      },

      getInitialState: function () {
        return {
          showWizard: this.props.showWizard,
          selectedItem: ''
        };
      },

      componentDidMount: function () {
        this.closeLink.focus();
        $(this.wizardBox).removeClass('ic-wizard-box--is-closed');
        $.screenReaderFlashMessageExclusive(I18n.t("Course Setup Wizard is showing."));
      },

      componentWillReceiveProps: function (nextProps) {
        this.setState({
          showWizard: nextProps.showWizard
        }, () => {
          $(this.wizardBox).removeClass('ic-wizard-box--is-closed');
          if (this.state.showWizard) {
            this.closeLink.focus();
          }
        });
      },

      /**
       * Handles what should happen when a checklist item is clicked.
       */
      checklistClickHandler: function (itemToShowKey) {
        this.setState({
          selectedItem: itemToShowKey
        });
      },

      closeModal: function (event) {
        if (event) {
          event.preventDefault()
        };

        var pathname = window.location.pathname;
        userSettings.set('hide_wizard_' + pathname, true);

        this.setState({
          showWizard: false
        })
      },

      render: function () {
        return (
          <ReactModal
            isOpen={this.state.showWizard}
            onRequestClose={this.closeModal}
            style={modalOverrides}
            overlayClassName={this.props.overlayClassName}
          >
            <main role='main'>
              <div ref={e => (this.wizardBox = e)} className='ic-wizard-box'>
                <div className='ic-wizard-box__header'>
                  <a href='/' className='ic-wizard-box__logo-link'>
                    <span className='screenreader-only'>{I18n.t('My dashboard')}</span>
                  </a>
                  <Checklist className='ic-wizard-box__nav'
                             selectedItem={this.state.selectedItem}
                             clickHandler={this.checklistClickHandler}
                  />
                </div>
                <div className='ic-wizard-box__main'>
                  <div className='ic-wizard-box__close'>
                    <div className='ic-Expand-link ic-Expand-link--from-right'>
                      <a ref={e => (this.closeLink = e)} href='#' className='ic-Expand-link__trigger' onClick={this.closeModal}>
                        <div className='ic-Expand-link__layout'>
                          <i className='icon-x ic-Expand-link__icon'></i>
                          <span className='ic-Expand-link__text'>{I18n.t('Close and return to Canvas')}</span>
                        </div>
                      </a>
                    </div>
                  </div>
                  <InfoFrame className='ic-wizard-box__content' itemToShow={this.state.selectedItem} closeModal={this.closeModal} />
                </div>
              </div>
            </main>
          </ReactModal>
          );
      }
  });

export default CourseWizard
