define([
  'i18n!theme_editor',
  'react',
  'jquery',
  'underscore',
  'str/htmlEscape',
  'compiled/fn/preventDefault',
  'compiled/models/Progress',
  './PropTypes',
  './submitHtmlForm',
  './SaveThemeButton',
  './ThemeEditorAccordion',
  './ThemeEditorFileUpload',
  './ThemeEditorModal'
], (I18n, React, $, _, htmlEscape, preventDefault, Progress, customTypes, submitHtmlForm, SaveThemeButton, ThemeEditorAccordion, ThemeEditorFileUpload, ThemeEditorModal) => {

/*eslint no-alert:0*/
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

  function findVarDef (variableSchema, variableName) {
    for (let i = 0; i < variableSchema.length; i++) {
      for (let j = 0; j < variableSchema[i].variables.length; j++) {
        let varDef = variableSchema[i].variables[j]
        if (varDef.variable_name === variableName){
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

  const notComplete = (progress) => progress.completion !== 100

  return React.createClass({

    displayName: 'ThemeEditor',

    propTypes: {
      brandConfig: customTypes.brandConfig,
      hasUnsavedChanges: React.PropTypes.bool.isRequired,
      variableSchema: customTypes.variableSchema,
      allowGlobalIncludes: React.PropTypes.bool,
      accountID: React.PropTypes.string,
      useHighContrast: React.PropTypes.bool,
    },

    getInitialState() {
      return {
        changedValues: {},
        showProgressModal: false,
        progress: 0,
        sharedBrandConfigBeingEdited: readSharedBrandConfigBeingEditedFromStorage(),
        showSubAccountProgress: false,
        activeSubAccountProgresses: []
      }
    },

    changeSomething(variableName, newValue, isInvalid) {
      const changedValues = {
        ...this.state.changedValues,
        [variableName]: { val: newValue, invalid: isInvalid },
      }
      this.setState({changedValues})
    },

    invalidForm() {
      return Object.keys(this.state.changedValues).some((key) => {
        return this.state.changedValues[key].invalid
      })
    },

    somethingHasChanged() {
      return _.any(this.state.changedValues, (change, key) => {
        // null means revert an unsaved change (should revert to saved brand config or fallback to default and not flag as a change)
        // '' means clear a brand config value (should set to schema default and flag as a change)
        return change.val === '' || (change.val !== this.getDefault(key) && change.val !== null)
      })
    },

    displayedMatchesSaved() {
      return this.state.sharedBrandConfigBeingEdited &&
             this.state.sharedBrandConfigBeingEdited.brand_config_md5 === this.props.brandConfig.md5
    },


    getDisplayValue(variableName, opts) {
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
    },

    getChangedValue(variableName) {
      return this.state.changedValues[variableName] && this.state.changedValues[variableName].val
    },

    getDefault(variableName) {
      return this.getDisplayValue(variableName, {ignoreChanges: true})
    },

    getBrandConfig(variableName) {
      return this.props.brandConfig[variableName] || this.props.brandConfig.variables[variableName]
    },

    getSchemaDefault(variableName, opts) {
      const varDef = findVarDef(this.props.variableSchema, variableName)
      const val = varDef ? varDef.default : null

      if (val && val[0] === '$') return this.getDisplayValue(val.slice(1), opts)
      return val
    },

    updateSharedBrandConfigBeingEdited (updatedSharedConfig) {
      sessionStorage.setItem('sharedBrandConfigBeingEdited', JSON.stringify(updatedSharedConfig))
      this.setState({sharedBrandConfigBeingEdited: updatedSharedConfig})
    },

    handleCancelClicked() {
      if (this.somethingHasChanged() || !this.displayedMatchesSaved()) {
        const msg = I18n.t('You are about to lose any unsaved changes.\n\n' +
                           'Would you still like to proceed?')
        if (!window.confirm(msg)) return
      }
      sessionStorage.removeItem('sharedBrandConfigBeingEdited')
      submitHtmlForm('/accounts/'+this.props.accountID+'/brand_configs', 'DELETE')
    },

    saveToSession(md5) {
      submitHtmlForm('/accounts/'+this.props.accountID+'/brand_configs/save_to_user_session', 'POST', md5)
    },

    handleFormSubmit() {
      let newMd5

      this.setState({showProgressModal: true})

      $.ajax({
        url: '/accounts/'+this.props.accountID+'/brand_configs',
        type: 'POST',
        data: new FormData(this.refs.ThemeEditorForm.getDOMNode()),
        processData: false,
        contentType: false,
        dataType: "json"
      })
      .pipe((resp) => {
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
    },

    onProgress(data) {
      this.setState({progress: data.completion})
    },

    handleApplyClicked() {
      const msg = I18n.t('This will apply this theme to your entire account. Would you like to proceed?')
      if (window.confirm(msg)) {
        this.kickOffSubAcountCompilation()
      }
    },

    redirectToAccount() {
      window.location.replace("/accounts/"+this.props.accountID+"/brand_configs?theme_applied=1")
    },

    kickOffSubAcountCompilation() {
      this.setState({isApplying: true})
      $.ajax({
        url: '/accounts/'+this.props.accountID+'/brand_configs/save_to_account',
        type: 'POST',
        data: new FormData(this.refs.ThemeEditorForm.getDOMNode()),
        processData: false,
        contentType: false,
        dataType: "json"
      })
      .pipe((resp) => {
        if (!resp.subAccountProgresses || _.isEmpty(resp.subAccountProgresses)) {
          this.redirectToAccount()
        } else {
          this.openSubAccountProgressModal()
          this.filterAndSetActive(resp.subAccountProgresses)
          return resp.subAccountProgresses.map( (prog) => {
            return new Progress(prog).poll().progress(this.onSubAccountProgress)
          })
        }
      })
      .fail(() => {
        this.setState({isApplying: false})
        window.alert(I18n.t('An error occurred trying to apply this theme, please try again.'))
      })
    },

    onSubAccountProgress(data) {
      const newSubAccountProgs = _.map(this.state.activeSubAccountProgresses, (progress) => {
        return progress.tag == data.tag ? data : progress
      })

      this.filterAndSetActive(newSubAccountProgs)

      if ( _.isEmpty(this.state.activeSubAccountProgresses)) {
        this.closeSubAccountProgressModal()
        this.redirectToAccount()
      }
    },

    filterAndSetActive(progresses) {
      this.setState({activeSubAccountProgresses: progresses.filter(notComplete)})
    },

    openSubAccountProgressModal() {
      this.setState({ showSubAccountProgress: true })
    },

    closeSubAccountProgressModal() {
      this.setState({ showSubAccountProgress: false })
    },

    renderTabInputs() {
      return this.props.allowGlobalIncludes ? TABS.map( (tab) => {
        return (
          <input type="radio"
            id={tab.id}
            key={tab.id}
            name="te-action"
            defaultValue={tab.value}
            className="Theme__editor-tabs_input"
            defaultChecked={tab.selected} />
        )
      }) : null
    },

    renderTabLabels() {
      return this.props.allowGlobalIncludes ? TABS.map( (tab) => {
        return (
          <label
            htmlFor={tab.id}
            key={`${tab.id}-tab`}
            className="Theme__editor-tabs_item"
            id={`${tab.id}-tab`}>
              {tab.label}
          </label>
        )
      }) : null
    },

    render() {
      let tooltipForWhyApplyIsDisabled = null
      if (this.somethingHasChanged()) {
        tooltipForWhyApplyIsDisabled = I18n.t('You need to "Preview Changes" before you can apply this to your account')
      } else if (this.props.brandConfig.md5 && !this.displayedMatchesSaved()) {
        tooltipForWhyApplyIsDisabled = I18n.t('You need to "Save" before applying to this account')
      } else if (this.state.isApplying) {
        tooltipForWhyApplyIsDisabled = I18n.t('Applying, please be patient')
      }

      return (
        <div id="main">
          { this.props.useHighContrast &&
            <div role="alert" className="ic-flash-static ic-flash-error">
              <h4 className="ic-flash__headline">
                <div className="ic-flash__icon" aria-hidden="true">
                  <i className="icon-warning"></i>
                </div>
                {I18n.t('You will not be able to preview your changes')}
              </h4>
              <p
                className="ic-flash__text"
                dangerouslySetInnerHTML={{
                  __html:
                    I18n.t('To preview Theme Editor branding, you will need to *turn off High Contrast UI*.', {
                      wrappers: ['<a href="/profile/settings">$1</a>']
                    })
                  }}
              />
            </div>
          }
          <form
            ref="ThemeEditorForm"
            onSubmit={preventDefault(this.handleFormSubmit)}
            encType="multipart/form-data"
            acceptCharset="UTF-8"
            action="'/accounts/'+this.props.accountID+'/brand_configs"
            method="POST"
            className="Theme__container">
            <input name="utf8" type="hidden" value="✓" />
            <input name="authenticity_token" type="hidden" value={$.cookie('_csrf_token')} />

            <header className={`Theme__header ${!this.props.hasUnsavedChanges && 'Theme__header--is-active-theme'}`}>

              <h1 className="screenreader-only">{I18n.t('Theme Editor')}</h1>
              <div className="Theme__header-layout">
                <div className="Theme__header-primary">

                  {/* HIDE THIS BUTTON IF THEME IS ACTIVE THEME */}
                  {/* IF CHANGES ARE MADE, THIS BUTTON IS DISABLED UNTIL THEY ARE SAVED */}
                  { this.props.hasUnsavedChanges ? (
                    <span
                      data-tooltip="right"
                      title={tooltipForWhyApplyIsDisabled}
                    >
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
                    {this.props.hasUnsavedChanges || this.somethingHasChanged() ?
                      null
                    :
                      <i className="icon-check"/>
                    }
                    &nbsp;&nbsp;
                    {this.state.sharedBrandConfigBeingEdited ? this.state.sharedBrandConfigBeingEdited.name : null }
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

            <div className={`Theme__layout ${!this.props.hasUnsavedChanges && 'Theme__layout--is-active-theme'}`} >
              <div className="Theme__editor">

                <div className="Theme__editor-tabs">
                  { this.renderTabInputs() }

                  <div className="Theme__editor-tab-label-layout">
                    { this.renderTabLabels() }
                  </div>

                  <div id="te-editor-panel" className="Theme__editor-tabs_panel">
                    <ThemeEditorAccordion
                      variableSchema={this.props.variableSchema}
                      brandConfigVariables={this.props.brandConfig.variables}
                      getDisplayValue={this.getDisplayValue}
                      changedValues={this.state.changedValues}
                      changeSomething={this.changeSomething}
                    />
                  </div>

                  { this.props.allowGlobalIncludes ?
                    <div id="te-upload-panel" className="Theme__editor-tabs_panel">
                      <div className="Theme__editor-upload-overrides">
                        <div className="Theme__editor-upload-warning">
                          <div className="Theme__editor-upload-warning_icon">
                            <i className="icon-warning" />
                          </div>
                          <div>
                            <p className="Theme__editor-upload-warning_text-emphasis">
                              {I18n.t('Custom CSS and Javascript may cause accessibility issues or conflicts with future Canvas updates!')}
                            </p>
                            <p
                              dangerouslySetInnerHTML={{
                                __html:
                                  I18n.t('Before implementing custom CSS or Javascript, please refer to *our documentation*.', {
                                    wrappers: ['<a href="https://community.canvaslms.com/docs/DOC-3010" target="_blank">$1</a>']
                                  })
                                }}
                            />
                          </div>
                        </div>

                        <div className="Theme__editor-upload-overrides_header">
                          { I18n.t('File(s) will be included on all pages in the Canvas desktop application.') }
                        </div>

                        <div className="Theme__editor-upload-overrides_form">

                          <ThemeEditorFileUpload
                            label={I18n.t('CSS file')}
                            accept=".css"
                            name="css_overrides"
                            currentValue={this.props.brandConfig.css_overrides}
                            userInput={this.state.changedValues.css_overrides}
                            onChange={this.changeSomething.bind(null, 'css_overrides')}
                          />

                          <ThemeEditorFileUpload
                            label={I18n.t('JavaScript file')}
                            accept=".js"
                            name="js_overrides"
                            currentValue={this.props.brandConfig.js_overrides}
                            userInput={this.state.changedValues.js_overrides}
                            onChange={this.changeSomething.bind(null, 'js_overrides')}
                          />

                        </div>
                      </div>
                      <div className="Theme__editor-upload-overrides">

                        <div className="Theme__editor-upload-overrides_header">
                          { I18n.t('File(s) will be included when user content is displayed within the Canvas iOS or Android apps, and in third-party apps built on our API.') }
                        </div>

                        <div className="Theme__editor-upload-overrides_form">

                          <ThemeEditorFileUpload
                            label={I18n.t('Mobile app CSS file')}
                            accept=".css"
                            name="mobile_css_overrides"
                            currentValue={this.props.brandConfig.mobile_css_overrides}
                            userInput={this.state.changedValues.mobile_css_overrides}
                            onChange={this.changeSomething.bind(null, 'mobile_css_overrides')}
                          />

                          <ThemeEditorFileUpload
                            label={I18n.t('Mobile app JavaScript file')}
                            accept=".js"
                            name="mobile_js_overrides"
                            currentValue={this.props.brandConfig.mobile_js_overrides}
                            userInput={this.state.changedValues.mobile_js_overrides}
                            onChange={this.changeSomething.bind(null, 'mobile_js_overrides')}
                          />

                        </div>
                      </div>
                    </div>
                  : null}

                </div>

              </div>

              <div className="Theme__preview">
                { this.somethingHasChanged() ?
                  <div className="Theme__preview-overlay">
                    <button
                      type="submit"
                      className="Button Button--primary Button--large"
                      disabled={this.invalidForm()}>
                      <i className="icon-refresh" />
                      <span className="Theme__preview-button-text">
                        {I18n.t('Preview Your Changes')}
                      </span>
                    </button>
                  </div>
                : null }
                <iframe id="previewIframe" ref="previewIframe" src={"/accounts/"+this.props.accountID+"/theme-preview/?editing_brand_config=1"} title={I18n.t('Preview')} />
              </div>

            </div>
            {/* Workaround to avoid corrupted XHR2 request body in IE10 / IE11,
                needs to be last element in <form>. see:
                https://blog.yorkxin.org/posts/2014/02/06/ajax-with-formdata-is-broken-on-ie10-ie11/ */}
            <input type="hidden" name="_workaround_for_IE_10_and_11_formdata_bug" />
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
  })
});
