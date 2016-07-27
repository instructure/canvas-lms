define([
  'react',
  'i18n!react_files',
  'compiled/react_files/components/UsageRightsSelectBox'
], function (React, I18n, UsageRightsSelectBox) {

  var CONTENT_OPTIONS = [{
      display: I18n.t('Choose usage rights...'),
      value: 'choose'
    }, {
      display: I18n.t('I hold the copyright'),
      value: 'own_copyright'
    }, {
      display: I18n.t('I have obtained permission to use this file.'),
      value: 'used_by_permission'
    }, {
      display: I18n.t('The material is in the public domain'),
      value: 'public_domain'
    }, {
      display: I18n.t('The material is subject to fair use exception'),
      value: 'fair_use'
    }, {
        display: I18n.t('The material is licensed under Creative Commons'),
        value: 'creative_commons'
    }
  ];

  UsageRightsSelectBox.renderContentOptions = function () {
    return CONTENT_OPTIONS.map((contentOption) => {
      return (<option key={contentOption.value} value={contentOption.value}>{contentOption.display}</option>);
    });
  };

  UsageRightsSelectBox.renderCreativeCommonsOptions = function () {
    var onlyCC = this.state.licenseOptions.filter((license) => {
      return license.id.indexOf('cc') === 0;
    });

    return onlyCC.map((license) => {
      return (<option key={license.id} value={license.id}>{license.name}</option>);
    });
  };

  UsageRightsSelectBox.renderShowCreativeCommonsOptions = function () {
    var renderShowCreativeCommonsOptions = (
      <div className='control-group'>
        <label
          className='control-label'
          htmlFor='creativeCommonsSelection'
        >
          {I18n.t('Creative Commons License:')}
        </label>
        <div className='control'>
          <select
            id='creativeCommonsSelection'
            className='UsageRightsSelectBox__creativeCommons'
            ref='creativeCommons'
            defaultValue={this.props.cc_value}
          >
            {this.renderCreativeCommonsOptions()}
          </select>
        </div>
      </div>
    );
    return this.state.showCreativeCommonsOptions ? renderShowCreativeCommonsOptions : null;
  };

  UsageRightsSelectBox.renderShowMessage = function () {
    var renderShowMessage = (
      <div
        ref='showMessageAlert'
        className='alert'
      >
        <span>
          <i className='icon-warning' ></i>
          <span style={{paddingLeft: '10px'}}>
            {I18n.t("If you do not select usage rights now, this file will be unpublished after it's uploaded.")}
          </span>
        </span>
      </div>
    );
    return this.state.showMessage ? renderShowMessage : null;
  };

  UsageRightsSelectBox.render = function () {
    return (
      <div
        className='UsageRightsSelectBox__container'
      >
        <div className='control-group'>
          <label
            className='control-label'
            htmlFor='usageRightSelector'
          >
            {I18n.t('Usage Right:')}
          </label>
          <div className='controls'>
            <select
              id='usageRightSelector'
              className='UsageRightsSelectBox__select'
              onChange={this.handleChange}
              onKeyUp={this.handleChooseKeyPress}
              ref='usageRightSelection'
              value={this.state.usageRightSelectionValue}
            >
              {this.renderContentOptions()}
            </select>
          </div>
        </div>
        {this.renderShowCreativeCommonsOptions()}
        <div className='control-group'>
          <label
            className='control-label'
            htmlFor='copyrightHolder'
          >
            {I18n.t('Copyright Holder:')}
          </label>
          <div className='controls'>
            <input
              id='copyrightHolder'
              type='text'
              ref='copyright'
              defaultValue={this.props.copyright && this.props.copyright}
              placeholder={I18n.t('(c) 2001 Acme Inc.')}
            >
            </input>
          </div>
        </div>
        {this.renderShowMessage()}
      </div>
    );
  };

  return React.createClass(UsageRightsSelectBox);

});
