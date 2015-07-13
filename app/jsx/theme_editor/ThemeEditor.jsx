/** @jsx React.DOM */

define([
  'i18n!theme_editor',
  'react',
  'str/htmlEscape',
  'compiled/fn/preventDefault',
  './PropTypes',
  './ThemeEditorAccordion',
  './SharedBrandConfigPicker'
], (I18n, React, htmlEscape, preventDefault, customTypes, ThemeEditorAccordion, SharedBrandConfigPicker) => {

  var ReactCSSTransitionGroup = React.addons.CSSTransitionGroup;

  function findVarDef (variableSchema, variableName) {
    for (var i = 0; i < variableSchema.length; i++) {
      for (var j = 0; j < variableSchema[i].variables.length; j++) {
        var varDef =  variableSchema[i].variables[j]
        if (varDef.variable_name === variableName){
          return varDef
        }
      }
    }
  }

  function submitHtmlForm(action, method) {
    $(`
      <form hidden action="${htmlEscape(action)}" method="POST">
        <input name="_method" type="hidden" value="${htmlEscape(method)}" />
        <input name="authenticity_token" type="hidden" value="${htmlEscape($.cookie('_csrf_token'))}" />
        <input name="brand_config" value="" />
      </form>
    `).appendTo('body').submit()
  }

  return React.createClass({

    displayName: 'ThemeEditor',

    propTypes: {
      brandConfig: customTypes.brandConfig,
      hasUnsavedChanges: React.PropTypes.bool.isRequired,
      variableSchema: customTypes.variableSchema,
      sharedBrandConfigs: customTypes.sharedBrandConfigs
    },

    getInitialState() {
      return {
        somethingChanged: false,
        changedValues: {}
      }
    },

    somethingChanged(variableName, newValue) {
      this.state.changedValues[variableName] = newValue
      this.setState({
        somethingChanged: true,
        changedValues: this.state.changedValues
      })
    },

    getDefault(variableName) {
      var val = this.state.changedValues[variableName]
      if (val) return val
      if (val !== '') {
        val = this.props.brandConfig.variables[variableName]
        if (val) return val
      }
      val = findVarDef(this.props.variableSchema, variableName).default
      if (val && val[0] === '$') return this.getDefault(val.slice(1))
      return val
    },

    resetToCanvasDefaults() {
      submitHtmlForm('/brand_configs', 'POST')
    },

    redirectToWhatIframeIsShowing() {
      window.top.location = this.refs.previewIframe.getDOMNode().contentWindow.location
    },

    exit() {
      if (this.props.hasUnsavedChanges || this.state.somethingChanged) {
        var msg = I18n.t('You are about to lose any unsaved changes.\n\n' +
                         'Would you still like to proceed?')
        if (confirm(msg)) {
          $.ajax('/brand_configs', {type: 'DELETE'})
            .then(this.redirectToWhatIframeIsShowing)
            .then(null, () => alert(I18n.t('Something went wrong, please try again.')))
        }
      } else {
        this.redirectToWhatIframeIsShowing()
      }
    },

    saveToAccount() {
      var msg = I18n.t('This will apply these changes to your entire account. Would you like to proceed?')
      if (confirm(msg)) submitHtmlForm('/brand_configs/save_to_account', 'POST')
    },

    render() {
      return (
        <div id="main">
        <form encType="multipart/form-data" acceptCharset="UTF-8" action="/brand_configs" method="POST" className="Theme__container">
          <input name="utf8" type="hidden" value="✓" />
          <input name="authenticity_token" type="hidden" value={$.cookie('_csrf_token')} />
          <div className="Theme__editor">
            <div className="Theme__editor-header">
              <h1 className="Theme__editor-header_title">
                <button
                  type='button'
                  className="Theme__editor-header_title-icon btn-link pull-left"
                  onClick={this.exit}
                >
                  <i className="icon-x" />
                  <span className="screenreader-only">{I18n.t('Exit Theme Editor')}</span>
                </button>

                {I18n.t('Theme Editor')}
              </h1>
              <div className="Theme__editor-header_actions">
                <span
                  data-tooltip="bottom"
                  title={this.state.somethingChanged ?
                    I18n.t('you need to "Preview Your Changes" before applying to everyone') :
                    null
                  }
                >
                  <button
                    type="button"
                    className="Theme__editor-header_button Button Button--success"
                    disabled={!this.props.hasUnsavedChanges || this.state.somethingChanged}
                    onClick={this.saveToAccount}
                  >
                    {I18n.t('Apply')}
                  </button>
                </span>
              </div>
            </div>

            {this.props.sharedBrandConfigs.length ?
              <SharedBrandConfigPicker sharedBrandConfigs={this.props.sharedBrandConfigs} activeBrandConfigMd5={this.props.brandConfig.md5} />
            :
              null
            }
            <div id="Theme__editor-tabs">
              <div id="te-editor">
                <div className="Theme__editor-tabs_panel">
                  <ThemeEditorAccordion
                    variableSchema={this.props.variableSchema}
                    brandConfigVariables={this.props.brandConfig.variables}
                    getDefault={this.getDefault}
                    changedValues={this.state.changedValues}
                    somethingChanged={this.somethingChanged}
                  />
                </div>
              </div>
            </div>
          </div>

          <div className="Theme__preview">
            { this.state.somethingChanged ?
              <div className="Theme__preview-overlay">
                <div className="Theme__preview-overlay__container">
                  <button type="submit" className="Button Button--primary">
                    <i className="icon-refresh" />
                    {I18n.t('Preview Your Changes')}
                  </button>
                </div>
              </div>
            : null }
            <iframe ref="previewIframe" src="/?editing_brand_config=1" />
          </div>
        </form>
        </div>
      )
    }
  })
});
