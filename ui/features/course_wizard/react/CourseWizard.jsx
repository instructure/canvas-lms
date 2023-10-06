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
import React, {useState, useRef} from 'react'
import PropTypes from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Mask, Overlay} from '@instructure/ui-overlays'
import InfoFrame from './InfoFrame'
import Checklist from './Checklist'
import '@canvas/rails-flash-notifications'

const I18n = useI18nScope('course_wizard')

export default function CourseWizard({onHideWizard}) {
  const [selectedItem, setSelectedItem] = useState('')
  const closeLink = useRef()
  return (
    <Overlay
      onOpen={() => {
        closeLink.current.focus()
        $.screenReaderFlashMessageExclusive(I18n.t('Course Setup Wizard is showing.'))
      }}
      open={true}
      onDismiss={onHideWizard}
      label={I18n.t('Course Wizard')}
      shouldContainFocus={true}
      shouldReturnFocus={true}
      unmountOnExit={true}
    >
      <Mask themeOverride={{background: 'transparent'}} fullscreen={true}>
        <main role="main">
          <div className="ic-wizard-box">
            <div className="ic-wizard-box__header">
              <a href="/" className="ic-wizard-box__logo-link">
                <span className="screenreader-only">{I18n.t('My dashboard')}</span>
              </a>
              <Checklist
                className="ic-wizard-box__nav"
                selectedItem={selectedItem}
                clickHandler={setSelectedItem}
              />
            </div>
            <div className="ic-wizard-box__main">
              <div className="ic-wizard-box__close">
                <div className="ic-Expand-link ic-Expand-link--from-right">
                  <button
                    type="button"
                    className="ic-Expand-link__trigger"
                    onClick={onHideWizard}
                    ref={closeLink}
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
                itemToShow={selectedItem}
                closeModal={onHideWizard}
              />
            </div>
          </div>
        </main>
      </Mask>
    </Overlay>
  )
}

CourseWizard.propTypes = {
  onHideWizard: PropTypes.func.isRequired,
}
