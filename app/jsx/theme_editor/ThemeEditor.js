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

import I18n from 'i18n!theme_editor'
import React from 'react'
import PropTypes from 'prop-types'
import $ from 'jquery'
import _ from 'lodash'
import preventDefault from 'compiled/fn/preventDefault'
import Progress from 'compiled/models/Progress'
import customTypes from './PropTypes'
import submitHtmlForm from './submitHtmlForm'
import SaveThemeButton from './SaveThemeButton'
import ThemeEditorAccordion from './ThemeEditorAccordion'
import ThemeEditorFileUpload from './ThemeEditorFileUpload'
import ThemeEditorModal from './ThemeEditorModal'
import ThemeEditorSidebar from './ThemeEditorSidebar'

/* eslint no-alert:0 */
const TABS = [
  {
    id: 'te-editor',
    label: I18n.t('Edit'),
    value: 'edit',
    selected: true
  },
  {
    id: 'te-upload',
    label: I18n.t('Upload'),
    value: 'upload',
    selected: false
  }
]

const OVERRIDE_FILE_KEYS = ['js_overrides', 'css_overrides', 'mobile_js_overrides', 'mobile_css_overrides'];

function findVarDef(variableSchema, variableName) {
  for (let i = 0; i < variableSchema.length; i++) {
    for (let j = 0; j < variableSchema[i].variables.length; j++) {
      const varDef = variableSchema[i].variables[j]
      if (varDef.variable_name === variableName) {
        return varDef
      }
    }
  }
}

function readSharedBrandConfigBeingEditedFromStorage() {
  try {
    const stored = sessionStorage.getItem('sharedBrandConfigBeingEdited')
    if (stored) return JSON.parse(stored)
  } catch (e) {
    console.error('Error reading sharedBrandConfigBeingEdited from sessionStore:', e)
  }
}

const notComplete = progress => progress.completion !== 100

export default class ThemeEditor extends React.Component {
  static propTypes = {
    brandConfig: customTypes.brandConfig,
    hasUnsavedChanges: PropTypes.bool.isRequired,
    variableSchema: customTypes.variableSchema,
    allowGlobalIncludes: PropTypes.bool,
    accountID: PropTypes.string,
    useHighContrast: PropTypes.bool
  }

  constructor(props) {
    super()
    const {variableSchema, brandConfig} = props
    const theme = _.flatMap(variableSchema, s => s.variables).reduce(
      (acc, next) => ({
        ...acc,
        ...{[next.variable_name]: next.default}
      }),
      {}
    )

    this.originalThemeProperties = {...theme, ...brandConfig.variables}
    this.originalThemeOverrides = _.pick(brandConfig, OVERRIDE_FILE_KEYS)

    this.state = {
      themeStore: {
        properties: {...this.originalThemeProperties},
        files: OVERRIDE_FILE_KEYS.map(key => ({
            customFileUpload: true,
            variable_name: key,
            value: this.originalThemeOverrides[key]
        }))
      },
      changedValues: {},
      showProgressModal: false,
      progress: 0,
      sharedBrandConfigBeingEdited: readSharedBrandConfigBeingEditedFromStorage(),
      showSubAccountProgress: false,
      activeSubAccountProgresses: []
    }
  }

  onProgress = data => {
    this.setState({progress: data.completion})
  }

  onSubAccountProgress = data => {
    const newSubAccountProgs = _.map(
      this.state.activeSubAccountProgresses,
      progress => (progress.tag == data.tag ? data : progress)
    )

    this.filterAndSetActive(newSubAccountProgs)

    if (_.isEmpty(this.state.activeSubAccountProgresses)) {
      this.closeSubAccountProgressModal()
      this.redirectToAccount()
    }
  }

  getDisplayValue = (variableName, opts) => {
    let val

    // try getting the modified value first, unless we're skipping it
    if (!opts || !opts.ignoreChanges) val = this.getChangedValue(variableName)

    // try getting the value from the active brand config next, but
    // distinguish "wasn't changed" from "was changed to '', meaning we want
    // to remove the brand config's value"
    if (!val && val !== '') val = this.getBrandConfig(variableName)

    // finally, resort to the default (which may recurse into looking up
    // another variable)
    if (!val) val = this.getSchemaDefault(variableName, opts)

    return val
  }

  getChangedValue = variableName =>
    this.state.changedValues[variableName] && this.state.changedValues[variableName].val

  getDefault = variableName => this.getDisplayValue(variableName, {ignoreChanges: true})

  getBrandConfig = variableName =>
    this.props.brandConfig[variableName] || this.props.brandConfig.variables[variableName]

  getSchemaDefault = (variableName, opts) => {
    const varDef = findVarDef(this.props.variableSchema, variableName)
    const val = varDef ? varDef.default : null

    if (val && val[0] === '$') return this.getDisplayValue(val.slice(1), opts)
    return val
  }

  handleThemeStateChange = (key, value, opts = {}) => {
    let {files, properties} = this.state.themeStore
    if (value instanceof File) {
      const fileStorageObject = {
        variable_name: key,
        value
      }
      if (opts.customFileUpload) {
        fileStorageObject.customFileUpload = true
      }
      const index = files.findIndex(x => x.variable_name === key);
      if (index !== -1) {
        files[index] = fileStorageObject;
      } else {
        files.push(fileStorageObject);
      }

    } else {
      properties = {
        ...properties,
        ...{[key]: value}
      }
    }

    if (opts.resetValue) {
      properties = {
        ...properties,
        ...{[key]: this.originalThemeProperties[key]}
      }
      const index = files.findIndex(x => x.variable_name === key)
      if (index !== -1) {
        files[index].value = this.originalThemeOverrides[key]
      }
    }

    if (opts.useDefault) {
      properties[key] = this.getSchemaDefault(key)
      const index = files.findIndex(x => x.variable_name === key)
      if (index !== -1) {
        files[index].value = ''
      }
    }

    this.setState({
      themeStore: {
        properties,
        files
      }
    })
  }

  somethingHasChanged = () =>
    _.some(
      this.state.changedValues,
      (change, key) =>
        // null means revert an unsaved change (should revert to saved brand config or fallback to default and not flag as a change)
        // '' means clear a brand config value (should set to schema default and flag as a change)
        change.val === '' || (change.val !== this.getDefault(key) && change.val !== null)
    )

  displayedMatchesSaved = () =>
    this.state.sharedBrandConfigBeingEdited &&
    this.state.sharedBrandConfigBeingEdited.brand_config_md5 === this.props.brandConfig.md5

  changeSomething = (variableName, newValue, isInvalid) => {
    const changedValues = {
      ...this.state.changedValues,
      [variableName]: {val: newValue, invalid: isInvalid}
    }
    this.setState({changedValues})
  }

  invalidForm = () =>
    Object.keys(this.state.changedValues).some(key => this.state.changedValues[key].invalid)

  updateSharedBrandConfigBeingEdited = updatedSharedConfig => {
    sessionStorage.setItem('sharedBrandConfigBeingEdited', JSON.stringify(updatedSharedConfig))
    this.setState({sharedBrandConfigBeingEdited: updatedSharedConfig})
  }

  handleCancelClicked = () => {
    if (this.somethingHasChanged() || !this.displayedMatchesSaved()) {
      const msg = I18n.t(
        'You are about to lose any unsaved changes.\n\n' + 'Would you still like to proceed?'
      )
      if (!window.confirm(msg)) return
    }
    sessionStorage.removeItem('sharedBrandConfigBeingEdited')
    submitHtmlForm(`/accounts/${this.props.accountID}/brand_configs`, 'DELETE')
  }

  saveToSession = md5 => {
    submitHtmlForm(
      `/accounts/${this.props.accountID}/brand_configs/save_to_user_session`,
      'POST',
      md5
    )
  }

  /**
   * Takes the themeStore state object and appends it to a FormData object
   * in preparation for sending to the server.
   *
   * @returns FormData
   * @memberof ThemeEditor
   */
  processThemeStoreForSubmit() {
    const processedData = new FormData()
    const {properties, files} = this.state.themeStore
    Object.keys(properties).forEach(k => {
      const defaultVal = this.getSchemaDefault(k)
      if (properties[k] !== defaultVal && properties[k] && properties[k][0] !== '$') {
        processedData.append(`brand_config[variables][${k}]`, properties[k])
      }
    })
    files.forEach(f => {
      const keyName = f.customFileUpload
        ? f.variable_name
        : `brand_config[variables][${f.variable_name}]`
      if (!f.customFileUpload || (f.customFileUpload && f.value != null)) {
        processedData.append(keyName, f.value)
      }
    });
    // We need to make sure that these are present with the upload
    OVERRIDE_FILE_KEYS.forEach(name => {
      if (!processedData.has(name) || processedData.get(name) === 'undefined' || processedData.get(name) === 'null') {
        processedData.append(name, this.props.brandConfig[name] || '');
      }
    })
    return processedData
  }

  handleFormSubmit = () => {
    let newMd5

    this.setState({showProgressModal: true})

    $.ajax({
      url: `/accounts/${this.props.accountID}/brand_configs`,
      type: 'POST',
      data: this.processThemeStoreForSubmit(),
      processData: false,
      contentType: false,
      dataType: 'json'
    })
      .pipe(resp => {
        newMd5 = resp.brand_config.md5
        if (resp.progress) {
          return new Progress(resp.progress).poll().progress(this.onProgress)
        }
      })
      .pipe(() => this.saveToSession(newMd5))
      .fail(() => {
        window.alert(I18n.t('An error occurred trying to generate this theme, please try again.'))
        this.setState({showProgressModal: false})
      })
  }

  handleApplyClicked = () => {
    const msg = I18n.t(
      'This will apply this theme to your entire account. Would you like to proceed?'
    )
    if (window.confirm(msg)) {
      this.kickOffSubAcountCompilation()
    }
  }

  redirectToAccount = () => {
    window.location.replace(`/accounts/${this.props.accountID}/brand_configs?theme_applied=1`)
  }

  kickOffSubAcountCompilation = () => {
    this.setState({isApplying: true})
    $.ajax({
      url: `/accounts/${this.props.accountID}/brand_configs/save_to_account`,
      type: 'POST',
      data: this.processThemeStoreForSubmit(),
      processData: false,
      contentType: false,
      dataType: 'json'
    })
      .pipe(resp => {
        if (!resp.subAccountProgresses || _.isEmpty(resp.subAccountProgresses)) {
          this.redirectToAccount()
        } else {
          this.openSubAccountProgressModal()
          this.filterAndSetActive(resp.subAccountProgresses)
          return resp.subAccountProgresses.map(prog =>
            new Progress(prog).poll().progress(this.onSubAccountProgress)
          )
        }
      })
      .fail(() => {
        this.setState({isApplying: false})
        window.alert(I18n.t('An error occurred trying to apply this theme, please try again.'))
      })
  }

  filterAndSetActive = progresses => {
    this.setState({activeSubAccountProgresses: progresses.filter(notComplete)})
  }

  openSubAccountProgressModal = () => {
    this.setState({showSubAccountProgress: true})
  }

  closeSubAccountProgressModal = () => {
    this.setState({showSubAccountProgress: false})
  }

  renderTabInputs = () =>
    this.props.allowGlobalIncludes
      ? TABS.map(tab => (
          <input
            type="radio"
            id={tab.id}
            key={tab.id}
            name="te-action"
            defaultValue={tab.value}
            className="Theme__editor-tabs_input"
            defaultChecked={tab.selected}
          />
        ))
      : null

  renderTabLabels = () =>
    this.props.allowGlobalIncludes
      ? TABS.map(tab => (
          <label
            htmlFor={tab.id}
            key={`${tab.id}-tab`}
            className="Theme__editor-tabs_item"
            id={`${tab.id}-tab`}
          >
            {tab.label}
          </label>
        ))
      : null

  renderHeader(tooltipForWhyApplyIsDisabled) {
    return (
      <header
        className={`Theme__header ${!this.props.hasUnsavedChanges &&
          'Theme__header--is-active-theme'}`}
      >
        <div className="Theme__header-layout">
          <div className="Theme__header-primary">
            {/* HIDE THIS BUTTON IF THEME IS ACTIVE THEME */}
            {/* IF CHANGES ARE MADE, THIS BUTTON IS DISABLED UNTIL THEY ARE SAVED */}
            {this.props.hasUnsavedChanges ? (
              <span data-tooltip="right" title={tooltipForWhyApplyIsDisabled}>
                <button
                  type="button"
                  className="Button Button--success"
                  disabled={!!tooltipForWhyApplyIsDisabled}
                  onClick={this.handleApplyClicked}
                >
                  {I18n.t('Apply theme')}
                </button>
              </span>
            ) : null}

            <h2 className="Theme__header-theme-name">
              {this.props.hasUnsavedChanges || this.somethingHasChanged() ? null : (
                <i className="icon-check" />
              )}
              &nbsp;&nbsp;
              {this.state.sharedBrandConfigBeingEdited
                ? this.state.sharedBrandConfigBeingEdited.name
                : null}
            </h2>
          </div>
          <div className="Theme__header-secondary">
            <SaveThemeButton
              userNeedsToPreviewFirst={this.somethingHasChanged()}
              sharedBrandConfigBeingEdited={this.state.sharedBrandConfigBeingEdited}
              accountID={this.props.accountID}
              brandConfigMd5={this.props.brandConfig.md5}
              onSave={this.updateSharedBrandConfigBeingEdited}
            />
            &nbsp;
            <button type="button" className="Button" onClick={this.handleCancelClicked}>
              {I18n.t('Exit')}
            </button>
          </div>
        </div>
      </header>
    )
  }

  render() {
    let tooltipForWhyApplyIsDisabled = null
    if (this.somethingHasChanged()) {
      tooltipForWhyApplyIsDisabled = I18n.t(
        'You need to "Preview Changes" before you can apply this to your account'
      )
    } else if (this.props.brandConfig.md5 && !this.displayedMatchesSaved()) {
      tooltipForWhyApplyIsDisabled = I18n.t('You need to "Save" before applying to this account')
    } else if (this.state.isApplying) {
      tooltipForWhyApplyIsDisabled = I18n.t('Applying, please be patient')
    }

    return (
      <div id="main" className="ic-Layout-columns">
        <h1 className="screenreader-only">{I18n.t('Theme Editor')}</h1>
        {this.props.useHighContrast && (
          <div role="alert" className="ic-flash-static ic-flash-error">
            <h4 className="ic-flash__headline">
              <div className="ic-flash__icon" aria-hidden="true">
                <i className="icon-warning" />
              </div>
              {I18n.t('You will not be able to preview your changes')}
            </h4>
            <p
              className="ic-flash__text"
              dangerouslySetInnerHTML={{
                __html: I18n.t(
                  'To preview Theme Editor branding, you will need to *turn off High Contrast UI*.',
                  {
                    wrappers: ['<a href="/profile/settings">$1</a>']
                  }
                )
              }}
            />
          </div>
        )}
        <form
          ref={c => (this.ThemeEditorForm = c)}
          onSubmit={preventDefault(this.handleFormSubmit)}
          encType="multipart/form-data"
          acceptCharset="UTF-8"
          action="'/accounts/'+this.props.accountID+'/brand_configs"
          method="POST"
          className="Theme__container"
        >
          <input name="utf8" type="hidden" value="✓" />
          <input name="authenticity_token" type="hidden" value={$.cookie('_csrf_token')} />

          <div
            className={`Theme__layout ${!this.props.hasUnsavedChanges &&
              'Theme__layout--is-active-theme'}`}
          >
            <div className="Theme__editor">
              <ThemeEditorSidebar
                themeStore={this.state.themeStore}
                handleThemeStateChange={this.handleThemeStateChange}
                allowGlobalIncludes={this.props.allowGlobalIncludes}
                brandConfig={this.props.brandConfig}
                variableSchema={this.props.variableSchema}
                getDisplayValue={this.getDisplayValue}
                changeSomething={this.changeSomething}
                changedValues={this.state.changedValues}
              />
            </div>

            <div className="Theme__preview">
              {this.somethingHasChanged() ? (
                <div className="Theme__preview-overlay">
                  <button
                    type="submit"
                    className="Button Button--primary Button--large"
                    disabled={this.invalidForm()}
                  >
                    <i className="icon-refresh" />
                    <span className="Theme__preview-button-text">
                      {I18n.t('Preview Your Changes')}
                    </span>
                  </button>
                </div>
              ) : null}
              <iframe
                id="previewIframe"
                ref="previewIframe"
                src={`/accounts/${this.props.accountID}/theme-preview/?editing_brand_config=1`}
                title={I18n.t('Preview')}
                aria-hidden={this.somethingHasChanged()}
                tabIndex={this.somethingHasChanged() ? '-1' : '0'}
              />
            </div>
          </div>
          {/* Workaround to avoid corrupted XHR2 request body in IE10 / IE11,
                needs to be last element in <form>. see:
                https://blog.yorkxin.org/posts/2014/02/06/ajax-with-formdata-is-broken-on-ie10-ie11/ */}
          <input type="hidden" name="_workaround_for_IE_10_and_11_formdata_bug" />
          {this.renderHeader(tooltipForWhyApplyIsDisabled)}
        </form>

        <ThemeEditorModal
          showProgressModal={this.state.showProgressModal}
          showSubAccountProgress={this.state.showSubAccountProgress}
          activeSubAccountProgresses={this.state.activeSubAccountProgresses}
          progress={this.state.progress}
        />
      </div>
    )
  }
}
