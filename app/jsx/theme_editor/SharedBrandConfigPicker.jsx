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
      sharedBrandConfigs: customTypes.sharedBrandConfigs
    },

    selectBrandConfig(md5) {
      if (md5 === USE_CANVAS_DEFAULT){
        md5 = ''
      }
      $(`
        <form hidden method="POST" action="/brand_configs" method="POST">
          <input name="authenticity_token" type="hidden" value="${htmlEscape($.cookie('_csrf_token'))}" />
          <input name="brand_config[md5]" value="${htmlEscape(md5)}" />
        </form>
      `).appendTo('body').submit()
    },

    defaultValue() {
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
            {I18n.t('Start From a Template Theme:')}
          </label>
          <select
            id="sharedThemes"
            defaultValue={this.defaultValue()}
            onChange={event => this.selectBrandConfig(event.target.value)}
          >
            <option value="" disabled selected> {I18n.t('-- Start From a Template Theme --')} </option>
            <option value={USE_CANVAS_DEFAULT}>{I18n.t('Canvas Default')}</option>
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
