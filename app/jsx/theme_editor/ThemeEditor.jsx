/** @jsx React.DOM */

define([
  'i18n!theme_editor',
  'react',
  'str/htmlEscape',
  'compiled/fn/preventDefault',
  './ThemeEditorAccordion',
  './SharedBrandConfigPicker'
], (I18n, React, htmlEscape, preventDefault, ThemeEditorAccordion, SharedBrandConfigPicker) => {

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
        val = this.props.brandConfig[variableName]
        if (val) return val
      }
      val = findVarDef(this.props.variableSchema, variableName).default
      if (val && val[0] === '$') return this.getDefault(val.slice(1))
      return val
    },

    resetToCanvasDefaults() {
      submitHtmlForm('/brand_configs', 'POST')
    },

    cancelChanges() {
      var msg = I18n.t('This will just cancel the unsaved changes you ' +
                       'have made in the Theme Editor. It will not affect ' +
                       'anyone else and you will now see canvas as everyone ' +
                       'else at your accout does.')

      if(confirm(msg)) submitHtmlForm('/brand_configs', 'DELETE')
    },

    saveToAccount() {
      var msg = I18n.t('This will apply the changes that you have made in ' +
                       'the Theme Editor so everyone else at your accout will ' +
                       'see Canvas as you are seeing it now. ' +
                       'Are you sure you want to do this?')

      if (confirm(msg)) submitHtmlForm('/brand_configs/save_to_account', 'POST')
    },

    render() {
      return (
        <form encType="multipart/form-data" acceptCharset="UTF-8" action="/brand_configs" method="POST" className="Theme__container">
          <input name="utf8" type="hidden" value="✓" />
          <input name="authenticity_token" type="hidden" value={$.cookie('_csrf_token')} />
          <div className="Theme__editor">
            <div className="Theme__editor-header">
              <h1 className="Theme__editor-header_title">Theme Editor</h1>
              <div className="Theme__editor-header_actions">
                <div className="al-dropdown__container">
                  <a className="al-trigger Button" role="button" href="#">
                    <i className="icon-more"></i>
                    <span className="screenreader-only">{I18n.t('Settings')}</span>
                  </a>
                  <ul
                    className="al-options"
                    role="menu"
                    tabIndex="0"
                    aria-hidden="true"
                    aria-expanded="false">
                    <li role="presentation" tabIndex="-1" role="menuitem">
                      <a
                        href="#"
                        className="icon-reset"
                        onClick={preventDefault(this.resetToCanvasDefaults)}
                      >
                        {I18n.t('Reset all to Canvas defaults')}
                      </a>
                    </li>
                    <li role="presentation" tabIndex="-1" role="menuitem">
                      <a
                        href="#"
                        className="icon-end"
                        onClick={preventDefault(this.cancelChanges)}
                      >
                        {I18n.t('Cancel Changes')}
                      </a>
                    </li>
                  </ul>
                </div>
                <button
                  type="button"
                  className="Theme__editor-header_button Button Button--success"
                  disabled={this.state.somethingChanged}
                  title={this.state.somethingChanged ?
                    I18n.t('"Preview Your Changes" before applying to everyone') :
                    null
                  }
                  onClick={this.saveToAccount}
                >
                  {I18n.t('Save')}
                </button>
              </div>
            </div>

            {this.props.sharedBrandConfigs.length ?
              <SharedBrandConfigPicker sharedBrandConfigs={this.props.sharedBrandConfigs} />
            :
              null
            }
            <div id="Theme__editor-tabs">
              <div id="te-editor">
                <div className="Theme__editor-tabs_panel">
                  <ThemeEditorAccordion
                    variableSchema={this.props.variableSchema}
                    brandConfig={this.props.brandConfig}
                    getDefault={this.getDefault}
                    changedValues={this.state.changedValues}
                    somethingChanged={this.somethingChanged}
                  />
                </div>
              </div>
            </div>
          </div>
          <div className="Theme__preview">
            <div
              hidden={!this.state.somethingChanged}
              className="Theme__preview-overlay"
            >
              <div
                style={{
                  width: 700,
                  textAlign: 'center',
                  height: '100vh',
                  margin: '0 auto'
                }}
              >
                <button type="submit" className="Button Button--primary" style={{margin: '40% auto'}}>
                  <i className="icon-refresh" />
                  {I18n.t('Preview Your Changes')}
                </button>
              </div>
            </div>
            <iframe src="/?editing_brand_config=1" style={{border: 'none', width: '100%', height: '100vh'}} />
          </div>
        </form>

      )
    }
  })
});
