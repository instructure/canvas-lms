/** @jsx React.DOM */

define([
  'i18n!theme_editor',
  'react',
  'jquery',
  'react-modal',
  'underscore',
  'str/htmlEscape',
  'compiled/fn/preventDefault',
  'compiled/models/Progress',
  'jsx/shared/ProgressBar',
  './PropTypes',
  './ThemeEditorAccordion',
  './SharedBrandConfigPicker',
  './ThemeEditorFileUpload'
], (I18n, React, $, Modal, _, htmlEscape, preventDefault, Progress, ProgressBar, customTypes, ThemeEditorAccordion, SharedBrandConfigPicker, ThemeEditorFileUpload) => {

/*eslint no-alert:0*/

  Modal.setAppElement(document.body)

  var TABS = [
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
  ];

  function findVarDef (variableSchema, variableName) {
    for (var i = 0; i < variableSchema.length; i++) {
      for (var j = 0; j < variableSchema[i].variables.length; j++) {
        var varDef = variableSchema[i].variables[j]
        if (varDef.variable_name === variableName){
          return varDef
        }
      }
    }
  }

  function submitHtmlForm(action, method, md5) {
    $(`
      <form hidden action="${htmlEscape(action)}" method="POST">
        <input name="_method" type="hidden" value="${htmlEscape(method)}" />
        <input name="authenticity_token" type="hidden" value="${htmlEscape($.cookie('_csrf_token'))}" />
        <input name="brand_config_md5" value="${htmlEscape(md5 ? md5 : '')}" />
      </form>
    `).appendTo('body').submit()
  }

  return React.createClass({

    displayName: 'ThemeEditor',

    propTypes: {
      brandConfig: customTypes.brandConfig,
      hasUnsavedChanges: React.PropTypes.bool.isRequired,
      variableSchema: customTypes.variableSchema,
      sharedBrandConfigs: customTypes.sharedBrandConfigs,
      allowGlobalIncludes: React.PropTypes.bool,
      accountID: React.PropTypes.string
    },

    getInitialState() {
      return {
        changedValues: {},
        showProgressModal: false,
        progress: 0
      }
    },

    invalidForm() {
      return Object.keys(this.state.changedValues).some((key) => {
        return this.state.changedValues[key].invalid
      })
    },

    changeSomething(variableName, newValue, isInvalid) {
      var change = { val: newValue, invalid: isInvalid }
      this.state.changedValues[variableName] = change
      this.setState({
        changedValues: this.state.changedValues
      })
    },

    onProgress(data) {
      this.setState({progress: data.completion})
    },

    somethingHasChanged() {
      return _.any(this.state.changedValues, (change, key) => {
        // null means revert an unsaved change (should revert to saved brand config or fallback to default and not flag as a change)
        // '' means clear a brand config value (should set to schema default and flag as a change)
        return change.val === '' || (change.val !== this.getDefault(key) && change.val !== null)
      })
    },

    getDisplayValue(variableName, opts) {
      var val

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
      var varDef = findVarDef(this.props.variableSchema, variableName)
      var val = varDef ? varDef.default : null

      if (val && val[0] === '$') return this.getDisplayValue(val.slice(1), opts)
      return val
    },

    saveToSession(md5) {
      submitHtmlForm('/accounts/'+this.props.accountID+'/brand_configs/save_to_user_session', 'POST', md5)
    },

    handleCancelClicked() {
      if (this.props.hasUnsavedChanges || this.somethingHasChanged()) {
        var msg = I18n.t('You are about to lose any changes that you have not yet applied to your account.\n\n' +
                         'Would you still like to proceed?')
        if (!window.confirm(msg)) {
          return;
        }
      }
      submitHtmlForm('/accounts/'+this.props.accountID+'/brand_configs', 'DELETE');
    },

    handleApplyClicked() {
      var msg = I18n.t('This will apply these changes to your entire account. Would you like to proceed?')
      if (window.confirm(msg)) submitHtmlForm('/accounts/'+this.props.accountID+'/brand_configs/save_to_account', 'POST')
    },

    handleFormSubmit() {
      var newMd5

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
        );
      }) : null;
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
        );
      }) : null;
    },

    render() {
      return (
        <div id="main">
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

            <div className="Theme__layout">

              <div className="Theme__editor">

                <div className="Theme__editor-header">
                  <div className="Theme__editor-header_title">
                    <i className="Theme__editor-header_title-icon icon-instructure" aria-hidden="true" />
                    <h1 className="Theme__editor-header_title-text">
                      {I18n.t('Theme Editor')}
                    </h1>
                  </div>

                  <div className="Theme__editor-header_actions">
                    <span
                      data-tooltip="bottom"
                      title={this.somethingHasChanged() ?
                        I18n.t('You need to "Preview Your Changes" before applying to everyone.') :
                        null
                      }
                    >
                      <button
                        type="button"
                        className="Theme__editor-header_button Button Button--small Button--success"
                        disabled={!this.props.hasUnsavedChanges || this.somethingHasChanged()}
                        onClick={this.handleApplyClicked}
                      >
                        {I18n.t('Apply')}
                      </button>

                    </span>
                    <button
                      type="button"
                      className="Theme__editor-header_button Button Button--small"
                      onClick={this.handleCancelClicked}
                    >
                      {I18n.t('Cancel')}
                    </button>
                  </div>
                </div>

                <div className="Theme__editor-tabs">

                  { this.renderTabInputs() }

                  { this.renderTabLabels() }

                  <div id="te-editor-panel" className="Theme__editor-tabs_panel">
                    <SharedBrandConfigPicker
                      sharedBrandConfigs={this.props.sharedBrandConfigs}
                      activeBrandConfigMd5={this.props.brandConfig.md5}
                      saveToSession={this.saveToSession}
                      hasUnsavedChanges={this.props.hasUnsavedChanges}
                      somethingChanged={this.somethingHasChanged()}
                    />
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

                        <div className="Theme__editor-upload-overrides_header">
                          { I18n.t('Upload CSS and JavaScript files to include on all page loads for your account') }
                        </div>

                        <div className="Theme__editor-upload-overrides_form">

                          <ThemeEditorFileUpload
                            label={I18n.t('Upload a CSS file...')}
                            accept=".css"
                            name="css_overrides"
                            currentValue={this.props.brandConfig.css_overrides}
                            userInput={this.state.changedValues.css_overrides}
                            onChange={this.changeSomething.bind(null, 'css_overrides')}
                          />

                          <ThemeEditorFileUpload
                            label={I18n.t('Upload a JS file...')}
                            accept=".js"
                            name="js_overrides"
                            currentValue={this.props.brandConfig.js_overrides}
                            userInput={this.state.changedValues.js_overrides}
                            onChange={this.changeSomething.bind(null, 'js_overrides')}
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
                      className="Button Button--primary"
                      disabled={this.invalidForm()}>
                      <i className="icon-refresh" />
                      <span className="Theme__preview-button-text">
                        {I18n.t('Preview Your Changes')}
                      </span>
                    </button>
                  </div>
                : null }
                <iframe id="previewIframe" ref="previewIframe" src="/theme-preview/?editing_brand_config=1" />
              </div>

            </div>
            {/* Workaround to avoid corrupted XHR2 request body in IE10 / IE11,
                needs to be last element in <form>. see:
                https://blog.yorkxin.org/posts/2014/02/06/ajax-with-formdata-is-broken-on-ie10-ie11/ */}
            <input type="hidden" name="_workaround_for_IE_10_and_11_formdata_bug" />
          </form>

          <Modal
            isOpen={this.state.showProgressModal}
            className='ReactModal__Content--canvas ReactModal__Content--mini-modal'
            overlayClassName='ReactModal__Overlay--Theme__editor_progress'>
            <div className="Theme__editor_progress">
              <h4>{I18n.t('Generating Preview...')}</h4>
              <ProgressBar
                progress={this.state.progress}
                title={I18n.t('%{percent} complete', {
                  percent: I18n.toPercentage(this.state.progress, {precision: 0})
                })}
              />
            </div>
          </Modal>

        </div>
      )
    }
  })
});
