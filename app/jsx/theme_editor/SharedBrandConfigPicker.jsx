/** @jsx React.DOM */

define([
  'react',
  'underscore',
  'i18n!theme_editor',
  'str/htmlEscape',
  './PropTypes'
], (React, _, I18n, htmlEscape, customTypes) => {

  var USE_CANVAS_DEFAULT = '__UseCanvasDefault__'

  return React.createClass({

    displayName: 'sharedBrandConfigPicker',

    propTypes: {
      activeBrandConfigMd5: customTypes.md5,
      sharedBrandConfigs: customTypes.sharedBrandConfigs,
      saveToSession: React.PropTypes.func.isRequired,
      hasUnsavedChanges: React.PropTypes.bool,
      somethingChanged: React.PropTypes.bool
    },

    selectBrandConfig(md5) {
      if (md5 === USE_CANVAS_DEFAULT) md5 = ''
      this.props.saveToSession(md5)
    },

    hasUnsavedCustomChanges() {
      // return true the current brand config is not applied yet and it's not the default or a shared config
      return this.props.hasUnsavedChanges && (this.props.activeBrandConfigMd5 !== null) && !this.selectedSharedConfig()
    },

    handleSelectChange(event) {
      if (this.props.somethingChanged || this.hasUnsavedCustomChanges()) {
        var msg = I18n.t('You are about to lose any changes that you have not yet applied to your account.\n\n' +
                         'Would you still like to proceed?')
        if (!confirm(msg)) {
          return
        }
      }
      this.selectBrandConfig(event.target.value)
    },

    selectedSharedConfig() {
      var found = _.find(this.props.sharedBrandConfigs, {md5: this.props.activeBrandConfigMd5})
      return found && found.md5
    },

    render() {
      return (
        <div className="Theme__editor-shared-themes">
          <label
            className="screenreader-only"
            htmlFor="sharedThemes"
          >
            {I18n.t('Start From a Theme Template')}
          </label>
          <select
            id="sharedThemes"
            defaultValue={this.selectedSharedConfig()}
            onChange={this.handleSelectChange}
            className="ic-Input"
          >
            <option value="" disabled selected>
              {I18n.t('Start from a template...')}
            </option>
            <option value={USE_CANVAS_DEFAULT}>
              {I18n.t('Canvas Default')}
            </option>
            {this.props.sharedBrandConfigs.map(brandConfig =>
              <option key={brandConfig.md5} value={brandConfig.md5}>
                {brandConfig.name}
              </option>
            )}
          </select>
        </div>
      )
    }
  })
});
