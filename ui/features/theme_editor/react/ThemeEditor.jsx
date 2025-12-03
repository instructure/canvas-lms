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

import {useScope as createI18nScope} from '@canvas/i18n'
import React, {useRef, useState} from 'react'
import PropTypes from 'prop-types'
import useStateWithCallback from '@canvas/use-state-with-callback-hook'
import preventDefault from '@canvas/util/preventDefault'
import Progress from '@canvas/progress/backbone/models/Progress'
import customTypes from '@canvas/theme-editor/react/PropTypes'
import {submitHtmlForm} from '@canvas/theme-editor/submitHtmlForm'
import SaveThemeButton from './SaveThemeButton'
import ThemeEditorModal from './ThemeEditorModal'
import ThemeEditorSidebar from './ThemeEditorSidebar'
import getCookie from '@instructure/get-cookie'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {addFlashNoticeForNextPage} from '@canvas/rails-flash-notifications'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Modal} from '@instructure/ui-modal'
import {Heading} from '@instructure/ui-heading'
// eslint-disable-next-line no-redeclare
import {Text} from '@instructure/ui-text'
import {Alert} from '@instructure/ui-alerts'
import {View} from '@instructure/ui-view'
import doFetchApi from '@canvas/do-fetch-api-effect'

const I18n = createI18nScope('theme_editor')

const OVERRIDE_FILE_KEYS = [
  'js_overrides',
  'css_overrides',
  'mobile_js_overrides',
  'mobile_css_overrides',
]

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

ThemeEditor.propTypes = {
  brandConfig: customTypes.brandConfig,
  isDefaultConfig: PropTypes.bool,
  hasUnsavedChanges: PropTypes.bool,
  variableSchema: customTypes.variableSchema,
  allowGlobalIncludes: PropTypes.bool,
  accountID: PropTypes.string,
  useHighContrast: PropTypes.bool,
}

export default function ThemeEditor({
  brandConfig,
  isDefaultConfig,
  hasUnsavedChanges,
  variableSchema,
  allowGlobalIncludes,
  accountID,
  useHighContrast,
}) {
  // Compute original theme values from props once on mount and never recompute.
  // We use useState instead of useMemo to avoid dependencies that would cause
  // recomputation when props change. These values represent the initial state
  // when the theme editor was opened and should remain constant for the lifetime
  // of the component (matching the original class component constructor behavior).
  const [originalThemeProperties] = useState(() => {
    const theme = variableSchema
      .flatMap(s => s.variables)
      .reduce(
        (acc, next) => ({
          ...acc,
          ...{[next.variable_name]: next.default},
        }),
        {},
      )
    return {...theme, ...brandConfig.variables}
  })

  const [originalThemeOverrides] = useState(() =>
    Object.fromEntries(OVERRIDE_FILE_KEYS.map(key => [key, brandConfig[key]])),
  )

  const [themeStore, setThemeStore] = useState(() => ({
    properties: {...originalThemeProperties},
    files: OVERRIDE_FILE_KEYS.map(key => ({
      customFileUpload: true,
      variable_name: key,
      value: originalThemeOverrides[key],
    })),
  }))

  const [changedValues, setChangedValues] = useState({})
  const [showProgressModal, setShowProgressModal] = useState(false)
  const [progress, setProgress] = useState(0)
  const [sharedBrandConfigBeingEdited, setSharedBrandConfigBeingEdited] = useState(
    readSharedBrandConfigBeingEditedFromStorage(),
  )
  const [showSubAccountProgress, setShowSubAccountProgress] = useState(false)
  const [activeSubAccountProgresses, setActiveSubAccountProgresses] = useStateWithCallback([])
  const [showApplyConfirmation, setShowApplyConfirmation] = useStateWithCallback(false)
  const [showCancelConfirmation, setShowCancelConfirmation] = useState(false)
  const [isApplying, setIsApplying] = useState(false)

  const themeEditorFormRef = useRef(null)

  function getSchemaDefault(variableName, opts) {
    const varDef = findVarDef(variableSchema, variableName)
    const val = varDef ? varDef.default : null

    if (val && val[0] === '$') return getDisplayValue(val.slice(1), opts)
    return val
  }

  function getDisplayValue(variableName, opts) {
    let val

    // try getting the modified value first, unless we're skipping it
    if (!opts || !opts.ignoreChanges) val = getChangedValue(variableName)

    // try getting the value from the active brand config next, but
    // distinguish "wasn't changed" from "was changed to '', meaning we want
    // to remove the brand config's value"
    if (!val && val !== '') val = getBrandConfig(variableName)

    // finally, resort to the default (which may recurse into looking up
    // another variable)
    if (!val) val = getSchemaDefault(variableName, opts)

    return val
  }

  const getChangedValue = name => changedValues[name] && changedValues[name].val
  const getBrandConfig = name => brandConfig[name] || brandConfig.variables[name]
  const getDefault = name => getDisplayValue(name, {ignoreChanges: true})
  const invalidForm = () => Object.keys(changedValues).some(key => changedValues[key].invalid)

  const somethingHasChanged = () =>
    Object.keys(changedValues).some(key => {
      const change = changedValues[key]
      // null means revert an unsaved change (should revert to saved brand config or fallback to default and not flag as a change)
      // '' means clear a brand config value (should set to schema default and flag as a change)
      return change.val === '' || (change.val !== getDefault(key) && change.val !== null)
    })

  function handleThemeStateChange(key, value, opts = {}) {
    let files = [...themeStore.files]
    let properties = {...themeStore.properties}
    if (value instanceof File) {
      const fileStorageObject = {
        variable_name: key,
        value,
      }
      if (opts.customFileUpload) {
        fileStorageObject.customFileUpload = true
      }
      const index = files.findIndex(x => x.variable_name === key)
      if (index !== -1) files[index] = fileStorageObject
      else files.push(fileStorageObject)
    } else properties = {...properties, ...{[key]: value}}

    if (opts.resetValue) {
      properties = {
        ...properties,
        ...{[key]: originalThemeProperties[key]},
      }
      const index = files.findIndex(x => x.variable_name === key)
      if (index !== -1)
        files = files.map((f, i) => (i === index ? {...f, value: originalThemeOverrides[key]} : f))
    }

    if (opts.useDefault) {
      properties[key] = getSchemaDefault(key)
      const index = files.findIndex(x => x.variable_name === key)
      if (index !== -1) files = files.map((f, i) => (i === index ? {...f, value: ''} : f))
    }

    setThemeStore({properties, files})
  }

  const displayedMatchesSaved = () =>
    sharedBrandConfigBeingEdited &&
    sharedBrandConfigBeingEdited.brand_config_md5 === brandConfig.md5

  function changeSomething(variableName, newValue, isInvalid) {
    const newChangedValues = {
      ...changedValues,
      [variableName]: {val: newValue, invalid: isInvalid},
    }
    setChangedValues(newChangedValues)
  }

  function updateSharedBrandConfigBeingEdited(updatedSharedConfig) {
    sessionStorage.setItem('sharedBrandConfigBeingEdited', JSON.stringify(updatedSharedConfig))
    setSharedBrandConfigBeingEdited(updatedSharedConfig)
  }

  function exitThemeEditor() {
    sessionStorage.removeItem('sharedBrandConfigBeingEdited')
    submitHtmlForm(`/accounts/${accountID}/brand_configs`, 'DELETE')
  }

  function handleCancelClicked() {
    if (somethingHasChanged() || !displayedMatchesSaved()) setShowCancelConfirmation(true)
    else exitThemeEditor()
  }

  function handleCancelCancel() {
    setShowCancelConfirmation(false)
  }

  function handleCancelProceed() {
    setShowCancelConfirmation(false)
    exitThemeEditor()
  }

  /**
   * Takes the themeStore state object and appends it to a FormData object
   * in preparation for sending to the server.
   *
   * @returns FormData
   */
  function processThemeStoreForSubmit() {
    const processedData = new FormData()
    const {properties, files} = themeStore
    Object.keys(properties).forEach(k => {
      const defaultVal = getSchemaDefault(k)
      if (properties[k] !== defaultVal && properties[k] && properties[k][0] !== '$') {
        // xsslint safeString.identifier k properties[k]
        // xsslint safeString.property k
        processedData.append(`brand_config[variables][${k}]`, properties[k])
      }
    })
    files.forEach(f => {
      const keyName = f.customFileUpload
        ? f.variable_name
        : `brand_config[variables][${f.variable_name}]`
      if (!f.customFileUpload || (f.customFileUpload && f.value != null)) {
        // xsslint safeString.identifier keyName
        // xsslint safeString.property value
        processedData.append(keyName, f.value)
      }
    })
    // We need to make sure that these are present with the upload
    OVERRIDE_FILE_KEYS.forEach(name => {
      if (
        !processedData.has(name) ||
        processedData.get(name) === 'undefined' ||
        processedData.get(name) === 'null'
      ) {
        // xsslint safeString.identifier name
        // xsslint safeString.property name
        processedData.append(name, brandConfig[name] || '')
      }
    })
    return processedData
  }

  async function handleFormSubmit() {
    function onProgress(data) {
      setProgress(data.completion)
    }

    setShowProgressModal(true)

    try {
      const {json} = await doFetchApi({
        path: `/accounts/${accountID}/brand_configs`,
        method: 'POST',
        body: processThemeStoreForSubmit(),
      })

      const newMd5 = json.brand_config.md5
      if (json.progress) await new Progress(json.progress).poll().progress(onProgress)
      submitHtmlForm(`/accounts/${accountID}/brand_configs/save_to_user_session`, 'POST', newMd5)
    } catch {
      showFlashError(I18n.t('An error occurred trying to generate this theme, please try again.'))()
      setShowProgressModal(false)
    }
  }

  function handleApplyCancel() {
    setShowApplyConfirmation(false)
  }

  function redirectToAccount() {
    addFlashNoticeForNextPage(
      'info',
      I18n.t(
        'Theme applied, but may take up to a few hours to propagate and be visible everywhere.',
      ),
    )
    window.location.replace(`/accounts/${accountID}/brand_configs`)
  }

  function onSubAccountProgress(data) {
    setActiveSubAccountProgresses(
      prevProgs => {
        const newSubAccountProgs = prevProgs.map(p => (p.tag == data.tag ? data : p))
        return newSubAccountProgs.filter(notComplete)
      },
      progsOutstanding => {
        // Callback runs after state update completes - only redirect when last progress finishes
        if (progsOutstanding.length === 0) redirectToAccount()
      },
    )
  }

  async function kickOffSubAccountCompilation() {
    setIsApplying(true)

    try {
      const {json} = await doFetchApi({
        path: `/accounts/${accountID}/brand_configs/save_to_account`,
        method: 'POST',
        body: processThemeStoreForSubmit(),
      })

      const progresses = json.subAccountProgresses

      if (!progresses || progresses.length === 0) redirectToAccount()
      else {
        setShowSubAccountProgress(true)
        setActiveSubAccountProgresses(progresses.filter(notComplete))
        progresses.forEach(prog => new Progress(prog).poll().progress(onSubAccountProgress))
      }
    } catch {
      setIsApplying(false)
      showFlashError(I18n.t('An error occurred trying to apply this theme, please try again.'))()
    }
  }

  function renderHeader(tooltipForWhyApplyIsDisabled) {
    return (
      <header className={`Theme__header ${!hasUnsavedChanges && 'Theme__header--is-active-theme'}`}>
        <div className="Theme__header-layout">
          <div className="Theme__header-primary">
            {/* HIDE THIS BUTTON IF THEME IS ACTIVE THEME */}
            {/* IF CHANGES ARE MADE, THIS BUTTON IS DISABLED UNTIL THEY ARE SAVED */}
            {hasUnsavedChanges ? (
              <span data-tooltip="right" title={tooltipForWhyApplyIsDisabled}>
                <Button
                  type="button"
                  color="success"
                  disabled={!!tooltipForWhyApplyIsDisabled}
                  onClick={() => setShowApplyConfirmation(true)}
                >
                  {I18n.t('Apply theme')}
                </Button>
              </span>
            ) : null}

            <h2 className="Theme__header-theme-name">
              {hasUnsavedChanges || somethingHasChanged() ? null : <i className="icon-check" />}
              &nbsp;&nbsp;
              {sharedBrandConfigBeingEdited ? sharedBrandConfigBeingEdited.name : null}
            </h2>
          </div>
          <div className="Theme__header-secondary">
            <SaveThemeButton
              userNeedsToPreviewFirst={somethingHasChanged()}
              sharedBrandConfigBeingEdited={sharedBrandConfigBeingEdited}
              accountID={accountID}
              brandConfigMd5={brandConfig.md5}
              isDefaultConfig={isDefaultConfig}
              onSave={updateSharedBrandConfigBeingEdited}
            />
            &nbsp;
            <Button type="button" onClick={handleCancelClicked}>
              {I18n.t('Exit')}
            </Button>
          </div>
        </div>
      </header>
    )
  }

  let tooltipForWhyApplyIsDisabled = null

  if (somethingHasChanged())
    tooltipForWhyApplyIsDisabled = I18n.t(
      'You need to "Preview Changes" before you can apply this to your account',
    )
  else if (!isDefaultConfig && !displayedMatchesSaved())
    tooltipForWhyApplyIsDisabled = I18n.t('You need to "Save" before applying to this account')
  else if (isApplying) tooltipForWhyApplyIsDisabled = I18n.t('Applying, please be patient')

  return (
    <div id="main" className="ic-Layout-columns">
      <h1 className="screenreader-only">{I18n.t('Theme Editor')}</h1>
      {useHighContrast && (
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
                  wrappers: ['<a href="/profile/settings">$1</a>'],
                },
              ),
            }}
          />
        </div>
      )}
      <form
        ref={themeEditorFormRef}
        onSubmit={preventDefault(handleFormSubmit)}
        encType="multipart/form-data"
        acceptCharset="UTF-8"
        action="'/accounts/'+accountID+'/brand_configs"
        method="POST"
        className="Theme__container"
      >
        <input name="utf8" type="hidden" value="✓" />
        <input name="authenticity_token" type="hidden" value={getCookie('_csrf_token')} />

        <div className={`Theme__layout ${!hasUnsavedChanges && 'Theme__layout--is-active-theme'}`}>
          <div className="Theme__editor">
            <ThemeEditorSidebar
              themeStore={themeStore}
              handleThemeStateChange={handleThemeStateChange}
              allowGlobalIncludes={allowGlobalIncludes}
              brandConfig={brandConfig}
              variableSchema={variableSchema}
              getDisplayValue={getDisplayValue}
              changeSomething={changeSomething}
              changedValues={changedValues}
            />
          </div>

          <div className="Theme__preview">
            {somethingHasChanged() ? (
              <div className="Theme__preview-overlay">
                <button
                  type="submit"
                  className="Button Button--primary Button--large"
                  disabled={invalidForm()}
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
              src={`/accounts/${accountID}/theme-preview/?editing_brand_config=1`}
              title={I18n.t('Preview')}
              aria-hidden={somethingHasChanged()}
              tabIndex={somethingHasChanged() ? '-1' : '0'}
            />
          </div>
        </div>
      </form>
      <Modal
        size="small"
        open={showApplyConfirmation}
        onDismiss={handleApplyCancel}
        shouldCloseOnDocumentClick={false}
        label={I18n.t('Apply Theme Confirmation')}
      >
        <Modal.Header>
          <CloseButton
            placement="end"
            offset="medium"
            onClick={handleApplyCancel}
            screenReaderLabel={I18n.t('Cancel')}
          />
          <Heading>{I18n.t('Apply Theme')}</Heading>
        </Modal.Header>
        <Modal.Body>
          <View as="div" margin="medium large">
            <Text as="p">
              {I18n.t(
                'This will apply this theme to your entire account. Would you like to proceed?',
              )}
            </Text>
            <Alert
              variant="info"
              margin="medium none none none"
              variantScreenReaderLabel={I18n.t('Note, ')}
            >
              {I18n.t(
                'Theme changes take time to propagate. This can take up to a few hours, so they may not be immediately visible.',
              )}
            </Alert>
          </View>
        </Modal.Body>
        <Modal.Footer>
          <Button margin="none buttons none none" onClick={handleApplyCancel}>
            {I18n.t('Cancel')}
          </Button>
          <Button
            color="primary"
            margin="none buttons none none"
            onClick={() => setShowApplyConfirmation(false, kickOffSubAccountCompilation)}
            data-testid="apply-theme-proceed-button"
          >
            {I18n.t('Proceed')}
          </Button>
        </Modal.Footer>
      </Modal>
      <Modal
        size="small"
        open={showCancelConfirmation}
        onDismiss={handleCancelCancel}
        shouldCloseOnDocumentClick={false}
        label={I18n.t('Exit Confirmation')}
      >
        <Modal.Header>
          <CloseButton
            placement="end"
            offset="medium"
            onClick={handleCancelCancel}
            screenReaderLabel={I18n.t('Cancel')}
          />
          <Heading>{I18n.t('Exit Theme Editor')}</Heading>
        </Modal.Header>
        <Modal.Body>
          <View as="div" margin="medium large">
            <Text as="p">
              {I18n.t(
                'You are about to lose any unsaved changes. Would you still like to exit the theme editor?',
              )}
            </Text>
          </View>
        </Modal.Body>
        <Modal.Footer>
          <Button margin="none buttons none none" onClick={handleCancelCancel}>
            {I18n.t('Cancel')}
          </Button>
          <Button
            color="primary"
            margin="none buttons none none"
            onClick={handleCancelProceed}
            data-testid="cancel-theme-editor-proceed-button"
          >
            {I18n.t('Exit')}
          </Button>
        </Modal.Footer>
      </Modal>
      {renderHeader(tooltipForWhyApplyIsDisabled)}

      <ThemeEditorModal
        showProgressModal={showProgressModal}
        showSubAccountProgress={showSubAccountProgress}
        activeSubAccountProgresses={activeSubAccountProgresses}
        progress={progress}
      />
    </div>
  )
}
