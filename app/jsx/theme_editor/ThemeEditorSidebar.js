/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import I18n from 'i18n!theme_editor'
import React from 'react'
import {bool, func, object} from 'prop-types'
import TabList, {TabPanel} from '@instructure/ui-core/lib/components/TabList'
import Container from '@instructure/ui-core/lib/components/Container'
import types from './PropTypes'
import ThemeEditorAccordion from './ThemeEditorAccordion'
import ThemeEditorFileUpload from './ThemeEditorFileUpload'

export default function ThemeEditorSidebar(props) {
  if (props.allowGlobalIncludes) {
    return (
      <TabList variant="minimal" size="medium" padding="0">
        <TabPanel title={I18n.t('Edit')}>
          <ThemeEditorAccordion
            variableSchema={props.variableSchema}
            brandConfigVariables={props.brandConfig.variables}
            getDisplayValue={props.getDisplayValue}
            changedValues={props.changedValues}
            changeSomething={props.changeSomething}
            themeState={props.themeState}
            handleThemeStateChange={props.handleThemeStateChange}
          />
        </TabPanel>
        <TabPanel title={I18n.t('Upload')} padding="0">
          <div className="Theme__editor-upload-overrides">
            <div className="Theme__editor-upload-warning">
              <div className="Theme__editor-upload-warning_icon">
                <i className="icon-warning" />
              </div>
              <div>
                <p className="Theme__editor-upload-warning_text-emphasis">
                  {I18n.t(
                    'Custom CSS and Javascript may cause accessibility issues or conflicts with future Canvas updates!'
                  )}
                </p>
                <p
                  dangerouslySetInnerHTML={{
                    __html: I18n.t(
                      'Before implementing custom CSS or Javascript, please refer to *our documentation*.',
                      {
                        wrappers: [
                          '<a href="https://community.canvaslms.com/docs/DOC-3010" target="_blank">$1</a>'
                        ]
                      }
                    )
                  }}
                />
              </div>
            </div>

            <div className="Theme__editor-upload-overrides_header">
              {I18n.t('File(s) will be included on all pages in the Canvas desktop application.')}
            </div>

            <div className="Theme__editor-upload-overrides_form">
              <ThemeEditorFileUpload
                label={I18n.t('CSS file')}
                accept=".css"
                name="css_overrides"
                currentValue={props.brandConfig.css_overrides}
                userInput={props.changedValues.css_overrides}
                onChange={props.changeSomething.bind(null, 'css_overrides')}
                themeState={props.themeState}
                handleThemeStateChange={props.handleThemeStateChange}
              />

              <ThemeEditorFileUpload
                label={I18n.t('JavaScript file')}
                accept=".js"
                name="js_overrides"
                currentValue={props.brandConfig.js_overrides}
                userInput={props.changedValues.js_overrides}
                onChange={props.changeSomething.bind(null, 'js_overrides')}
                themeState={props.themeState}
                handleThemeStateChange={props.handleThemeStateChange}
              />
            </div>
          </div>
          <div className="Theme__editor-upload-overrides">
            <div className="Theme__editor-upload-overrides_header">
              {I18n.t(
                'File(s) will be included when user content is displayed within the Canvas iOS or Android apps, and in third-party apps built on our API.'
              )}
            </div>

            <div className="Theme__editor-upload-overrides_form">
              <ThemeEditorFileUpload
                label={I18n.t('Mobile app CSS file')}
                accept=".css"
                name="mobile_css_overrides"
                currentValue={props.brandConfig.mobile_css_overrides}
                userInput={props.changedValues.mobile_css_overrides}
                onChange={props.changeSomething.bind(null, 'mobile_css_overrides')}
                themeState={props.themeState}
                handleThemeStateChange={props.handleThemeStateChange}
              />

              <ThemeEditorFileUpload
                label={I18n.t('Mobile app JavaScript file')}
                accept=".js"
                name="mobile_js_overrides"
                currentValue={props.brandConfig.mobile_js_overrides}
                userInput={props.changedValues.mobile_js_overrides}
                onChange={props.changeSomething.bind(null, 'mobile_js_overrides')}
                themeState={props.themeState}
                handleThemeStateChange={props.handleThemeStateChange}
              />
            </div>
          </div>
        </TabPanel>
      </TabList>
    )
  }
  return (
    <Container padding="small" display="block">
      <ThemeEditorAccordion
        variableSchema={props.variableSchema}
        brandConfigVariables={props.brandConfig.variables}
        getDisplayValue={props.getDisplayValue}
        changedValues={props.changedValues}
        changeSomething={props.changeSomething}
        themeState={props.themeState}
        handleThemeStateChange={props.handleThemeStateChange}
      />
    </Container>
  )
}

ThemeEditorSidebar.propTypes = {
  allowGlobalIncludes: bool,
  brandConfig: types.brandConfig.isRequired,
  variableSchema: types.variableSchema.isRequired,
  getDisplayValue: func.isRequired,
  changeSomething: func.isRequired,
  changedValues: object,
  themeState: object.isRequired,
  handleThemeStateChange: func.isRequired
}

ThemeEditorSidebar.defaultProps = {
  allowGlobalIncludes: false,
  changedValues: {}
}
