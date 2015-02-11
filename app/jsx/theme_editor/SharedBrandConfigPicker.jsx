/** @jsx React.DOM */

define([
  'react',
  'i18n!theme_editor',
  'str/htmlEscape'
], (React, I18n, htmlEscape) => {
  return React.createClass({

    displayName: 'sharedBrandConfigPicker',

    selectBrandConfig(md5) {
      $(`
        <form hidden method="POST" action="/brand_configs" method="POST">
          <input name="authenticity_token" type="hidden" value="${htmlEscape($.cookie('_csrf_token'))}" />
          <input name="brand_config[md5]" value="${htmlEscape(md5)}" />
        </form>
      `).appendTo('body').submit()
    },

    render() {
      return (
        <select onChange={event => this.selectBrandConfig(event.target.value)}>
          <option value="" disabled>{I18n.t('Start from a template')}</option>
          {this.props.sharedBrandConfigs.map(brandConfig =>
            <option key={brandConfig.md5} value={brandConfig.md5}>
              {brandConfig.name}
            </option>
          )}
        </select>
      )
    }
  })
});
