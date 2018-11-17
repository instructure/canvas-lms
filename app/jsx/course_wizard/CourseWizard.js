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
import Mask from '@instructure/ui-overlays/lib/components/Mask'
import Overlay from '@instructure/ui-overlays/lib/components/Overlay'
import InfoFrame from './InfoFrame'
import Checklist from './Checklist'
import userSettings from 'compiled/userSettings'
import 'compiled/jquery.rails_flash_notifications'

class CourseWizard extends React.Component {
  static displayName = 'CourseWizard'

  static propTypes = {
    showWizard: PropTypes.bool.isRequired
  }

  state = {
    showWizard: this.props.showWizard,
    selectedItem: ''
  }

  componentWillReceiveProps(nextProps) {
    this.setState({showWizard: nextProps.showWizard})
  }

  overlayMounted() {
    $(this.wizardBox)
      .addClass('ic-wizard-box--is-open')
      .removeClass('ic-wizard-box--is-closed')
    $(this.closeLink).focus()
    $.screenReaderFlashMessageExclusive(I18n.t('Course Setup Wizard is showing.'))
  }

  /**
   * Handles what should happen when a checklist item is clicked.
   */
  checklistClickHandler = itemToShowKey => {
    this.setState({selectedItem: itemToShowKey})
  }

  closeModal = event => {
    if (event) {
      event.preventDefault()
    }

    const pathname = window.location.pathname
    userSettings.set(`hide_wizard_${pathname}`, true)

    $(this.wizardBox)
      .removeClass('ic-wizard-box--is-open')
      .addClass('ic-wizard-box--is-closed')

    // Wait until the animation transition is complete before unmounting
    // TODO: Replace with InstUI transitions directly on the <Overlay>
    // when the slide animations are fixed
    setTimeout(() => this.setState({showWizard: false}), 1000)
  }

  render() {
    return (
      <Overlay
        onOpen={() => this.overlayMounted()}
        open={this.state.showWizard}
        onDismiss={() => this.closeModal()}
        label={I18n.t('Course Wizard')}
        defaultFocusElement={() => this.closeLink}
        shouldContainFocus
        shouldReturnFocus
        unmountOnExit
      >
        <Mask theme={{background: 'transparent'}} fullscreen>
          <main role="main">
            <div ref={e => (this.wizardBox = e)} className="ic-wizard-box">
              <div className="ic-wizard-box__header">
                <a href="/" className="ic-wizard-box__logo-link">
                  <span className="screenreader-only">{I18n.t('My dashboard')}</span>
                </a>
                <Checklist
                  className="ic-wizard-box__nav"
                  selectedItem={this.state.selectedItem}
                  clickHandler={this.checklistClickHandler}
                />
              </div>
              <div className="ic-wizard-box__main">
                <div className="ic-wizard-box__close">
                  <div className="ic-Expand-link ic-Expand-link--from-right">
                    <button
                      ref={e => (this.closeLink = e)}
                      className="ic-Expand-link__trigger"
                      onClick={this.closeModal}
                    >
                      <div className="ic-Expand-link__layout">
                        <i className="icon-x ic-Expand-link__icon" />
                        <span className="ic-Expand-link__text">
                          {I18n.t('Close and return to Canvas')}
                        </span>
                      </div>
                    </button>
                  </div>
                </div>
                <InfoFrame
                  className="ic-wizard-box__content"
                  itemToShow={this.state.selectedItem}
                  closeModal={this.closeModal}
                />
              </div>
            </div>
          </main>
        </Mask>
      </Overlay>
    )
  }
}

export default CourseWizard
