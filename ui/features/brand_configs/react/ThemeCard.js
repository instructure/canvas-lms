/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import {string, func, bool} from 'prop-types'
import SVGWrapper from '@canvas/svg-wrapper'

import Modal from '@canvas/instui-bindings/react/InstuiModal'
import {Button} from '@instructure/ui-buttons'

const I18n = useI18nScope('theme_editor')

export default function ThemeCard(props) {
  const getVar = props.getVariable
  return (
    <div className={`ic-ThemeCard ${props.isActiveBrandConfig && 'ic-ThemeCard--is-active-theme'}`}>
      <div className="ic-ThemeCard-thumbnail" aria-hidden="true" onClick={props.open}>
        <div className="ic-ThemeCard-thumbnail__primary-content">
          <div className="ic-ThemeCard-fake-text" />
          <div
            className="ic-ThemeCard-fake-progressbar"
            style={{borderColor: getVar('ic-brand-primary')}}
          >
            <div
              className="ic-ThemeCard-fake-progressbar__inner"
              style={{backgroundColor: getVar('ic-brand-primary')}}
            />
          </div>
          <div className="ic-ThemeCard-fake-radio">
            <div
              className="ic-ThemeCard-fake-radio__inner"
              style={{
                backgroundColor: getVar('ic-brand-primary'),
                borderColor: getVar('ic-brand-primary'),
              }}
            />
          </div>
          <div className="ic-ThemeCard-fake-checkbox">
            <div
              className="ic-ThemeCard-fake-checkbox__inner"
              style={{backgroundColor: getVar('ic-brand-primary')}}
            >
              <i className="icon-check" />
            </div>
          </div>
        </div>
        <div className="ic-ThemeCard-thumbnail__secondary-content">
          <div
            className="ic-ThemeCard-fake-button"
            style={{backgroundColor: getVar('ic-brand-button--primary-bgd')}}
          />
          <div
            className="ic-ThemeCard-fake-button"
            style={{backgroundColor: getVar('ic-brand-button--secondary-bgd')}}
          />
        </div>
        <div
          className="ic-ThemeCard-thumbnail__nav"
          style={{backgroundColor: getVar('ic-brand-global-nav-bgd')}}
        >
          <div className="ic-ThemeCard-thumbnail__icon">
            <SVGWrapper
              url="/images/svg-icons/svg_icon_courses_new_styles.svg"
              fillColor={getVar('ic-brand-global-nav-ic-icon-svg-fill')}
            />
            <div
              className="ic-ThemeCard-thumbnail__icon-text"
              style={{backgroundColor: getVar('ic-brand-global-nav-menu-item__text-color')}}
            />
          </div>
          <div className="ic-ThemeCard-thumbnail__icon">
            <SVGWrapper
              url="/images/svg-icons/svg_icon_calendar_new_styles.svg"
              fillColor={getVar('ic-brand-global-nav-ic-icon-svg-fill')}
            />
            <div
              className="ic-ThemeCard-thumbnail__icon-text"
              style={{backgroundColor: getVar('ic-brand-global-nav-menu-item__text-color')}}
            />
          </div>
          <div className="ic-ThemeCard-thumbnail__icon">
            <SVGWrapper
              url="/images/svg-icons/svg_icon_inbox.svg"
              fillColor={getVar('ic-brand-global-nav-ic-icon-svg-fill')}
            />
            <div
              className="ic-ThemeCard-thumbnail__icon-text"
              style={{backgroundColor: getVar('ic-brand-global-nav-menu-item__text-color')}}
            />
          </div>
        </div>
        {!props.isBeingDeleted && (
          <div className="ic-ThemeCard-overlay">
            <div className="ic-ThemeCard-overlay__content">
              <div className="Button Button--primary">{I18n.t('Open in Theme Editor')}</div>
            </div>
          </div>
        )}
      </div>
      <div className="ic-ThemeCard-main">
        <div className="ic-ThemeCard-main__name">
          <button
            type="button"
            className="ic-ThemeCard-name-button"
            data-testid="themecard-name-button"
            onClick={props.open}
          >
            <span className="screenreader-only">
              {props.isActiveBrandConfig ? I18n.t('This is your current theme') : null}
              {I18n.t('Edit this theme in Theme Editor')}
            </span>
            {props.name}
          </button>
        </div>
        <div className="ic-ThemeCard-main__actions">
          {props.isDeletable && (
            <button
              type="button"
              className="Button Button--icon-action"
              data-testid="themecard-delete-button"
              onClick={props.startDeleting}
            >
              <span className="screenreader-only">{I18n.t('Delete theme')}</span>
              <i className="icon-trash" />
            </button>
          )}
        </div>
      </div>
      {props.isBeingDeleted && (
        <Modal
          as="form"
          open={true}
          onDismiss={props.cancelDeleting}
          onSubmit={props.onDelete}
          label={I18n.t('Delete Theme?')}
        >
          <Modal.Body>{I18n.t('Delete %{themeName}?', {themeName: props.name})}</Modal.Body>
          <Modal.Footer>
            <Button onClick={props.cancelDeleting}>{I18n.t('Cancel')}</Button>
            &nbsp;
            <Button color="primary" type="submit">
              {I18n.t('Delete')}
            </Button>
          </Modal.Footer>
        </Modal>
      )}
      {props.isActiveBrandConfig && (
        <div
          className="ic-ThemeCard-status ic-ThemeCard-status--is-active-theme"
          aria-hidden="true"
        >
          <i className="icon-check ic-ThemeCard-status__icon" />
          &nbsp;&nbsp;
          <span className="ic-ThemeCard-status__text">
            {I18n.t('Current theme')}
            {props.showMultipleCurrentThemesMessage && (
              <button
                type="button"
                className="Button Button--icon-action-rev"
                data-tooltip='{"tooltipClass":"popover popover-padded", "position":"right"}'
                title={I18n.t(
                  'Multiple are marked "Current theme" because the same values have been saved under multiple names—i.e., they\'re each the same as what\'s currently applied'
                )}
              >
                <i className="icon-question" aria-hidden="true" />
              </button>
            )}
          </span>
        </div>
      )}
    </div>
  )
}

ThemeCard.propTypes = {
  name: string.isRequired,
  isActiveBrandConfig: bool.isRequired,
  isDeletable: bool.isRequired,
  isBeingDeleted: bool.isRequired,
  showMultipleCurrentThemesMessage: bool.isRequired,
  startDeleting: func.isRequired,
  cancelDeleting: func.isRequired,
  onDelete: func.isRequired,
  open: func.isRequired,
  getVariable: func.isRequired,
}
