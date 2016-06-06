define([
  'i18n!theme_collection_view',
  'react',
  'underscore',
  './PropTypes',
  './submitHtmlForm',
  './ThemeCard'
], (I18n, React, _, customTypes, submitHtmlForm, ThemeCard) => {

  const blankConfig = {
    name: I18n.t('Default Template'),
    brand_config: {
      md5: '',
      variables: {}
    }
  }

  const isSystemTheme = (sharedBrandConfig) => !sharedBrandConfig.account_id

  return React.createClass({
    displayName: 'CollectionView',

    propTypes: {
      sharedBrandConfigs: React.PropTypes.arrayOf(customTypes.sharedBrandConfig).isRequired,
      activeBrandConfig: customTypes.brandConfig.isRequired,
      accountID: React.PropTypes.string.isRequired,
      brandableVariableDefaults: customTypes.brandableVariableDefaults,
      baseBrandableVariables: customTypes.variables
    },

    getInitialState () {
      return {
        newThemeModalIsOpen: false,
        brandConfigBeingDeleted: null
      }
    },

    brandVariableValue (brandConfig, variableName) {
      const explicitValue = brandConfig && brandConfig.variables[variableName]
      if (explicitValue) return explicitValue

      const variableInfo = this.props.brandableVariableDefaults[variableName]
      let _default = variableInfo.default
      if (_default && _default[0] === '$') {
        return this.brandVariableValue(brandConfig, _default.substring(1))
      }
      return this.props.baseBrandableVariables[variableName]
    },

    startFromBlankSlate() {
      const md5 = ''
      this.saveToSession(md5)
    },

    startEditing({md5ToActivate, sharedBrandConfigToStartEditing}) {
      if (md5ToActivate === (this.props.activeBrandConfig && this.props.activeBrandConfig.md5)) {
        md5ToActivate = undefined
      }
      if (sharedBrandConfigToStartEditing) {
        sessionStorage.setItem('sharedBrandConfigBeingEdited', JSON.stringify(sharedBrandConfigToStartEditing))
      } else {
        sessionStorage.removeItem('sharedBrandConfigBeingEdited')
      }
      submitHtmlForm(`/accounts/${this.props.accountID}/brand_configs/save_to_user_session`, 'POST', md5ToActivate)
    },

    deleteSharedBrandConfig (sharedBrandConfigId) {
      $.ajaxJSON(`/api/v1/shared_brand_configs/${sharedBrandConfigId}`, 'DELETE', {}, () => {
        window.location.reload()
      })
    },

    isActiveBrandConfig (brandConfig) {
      if (this.props.activeBrandConfig) {
        return brandConfig.md5 === this.props.activeBrandConfig.md5
      } else {
        return brandConfig === blankConfig.brand_config
      }
    },

    isDeletable (sharedBrandConfig) {
      // Globally-shared themes and the active theme are not deletable
      return !isSystemTheme(sharedBrandConfig) &&
             !this.isActiveBrandConfig(sharedBrandConfig.brand_config)
    },

    thingsToShow () {
      const thingsToShow = [blankConfig].concat(this.props.sharedBrandConfigs)
      const isActive = (sharedBrandConfig) => this.isActiveBrandConfig(sharedBrandConfig.brand_config)

      // Add in a tile for the active theme if it is otherwise not present in the shared ones
      if (this.props.activeBrandConfig && !_.find(this.props.sharedBrandConfigs, isActive)) {
        const cardForActiveBrandConfig = {
          brand_config: this.props.activeBrandConfig,
          account_id: this.props.accountID
        }
        thingsToShow.unshift(cardForActiveBrandConfig)
      }

      // Make sure the active theme shows up first
      const sorted = _.sortBy(thingsToShow, thing => !isActive(thing))

      // split the globally shared themes and the ones that people in this account have shared apart
      return _.groupBy(sorted, (sbc) => isSystemTheme(sbc) ? 'globalThemes' : 'accountSpecificThemes')
    },

    renderCard (sharedConfig) {
      const onClick = () => {
        const isReadOnly = isSystemTheme(sharedConfig)
        this.startEditing({
          md5ToActivate: sharedConfig.brand_config.md5,
          sharedBrandConfigToStartEditing: !isReadOnly && sharedConfig
        })
      }

      const isActiveEditableTheme = (sbc) =>
        !isSystemTheme(sbc) && (
          this.props.activeBrandConfig &&
          this.props.activeBrandConfig.md5 === sbc.brand_config.md5
        )

      // even if this theme's md5 is active, don't mark it as active if it is a system theme
      // and there is an account-shared theme that also matches the active md5
      const isActiveBrandConfig = this.isActiveBrandConfig(sharedConfig.brand_config) && (
        !isSystemTheme(sharedConfig) ||
        !this.props.sharedBrandConfigs.some(isActiveEditableTheme)
      )

      return (
        <ThemeCard
          key={sharedConfig.id + sharedConfig.brand_config.md5}
          name={sharedConfig.name}
          isActiveBrandConfig={isActiveBrandConfig}
          getVariable   ={this.brandVariableValue.bind(this, sharedConfig.brand_config)}
          open          ={onClick}
          isDeletable   ={this.isDeletable(sharedConfig)}
          isBeingDeleted={this.state.brandConfigBeingDeleted === sharedConfig}
          startDeleting ={() => this.setState({brandConfigBeingDeleted: sharedConfig})}
          cancelDeleting={() => this.setState({brandConfigBeingDeleted: null})}
          onDelete      ={() => this.deleteSharedBrandConfig(sharedConfig.id)}
        />
      )
    },

    render () {
      const thingsToShow = this.thingsToShow()
      return (
        <div>
          <div className="ic-Action-header">
            <div className="ic-Action-header__Primary">
              <h2 className="ic-Action-header__Heading">{I18n.t('Themes')}</h2>
            </div>
            <div className="ic-Action-header__Secondary">
              <div className="al-dropdown__container">
                <button
                  className="al-trigger Button Button--primary"
                  type="button"
                  title={I18n.t('Add Theme')}
                  aria-label={I18n.t('Add Theme')}
                >
                  <i className="icon-plus" />
                  &nbsp;
                  {I18n.t('Theme')}
                  &nbsp;&nbsp;
                  <i className="icon-mini-arrow-down" />
                </button>
                <ul className="al-options ic-ThemeCard-add-template-menu">
                  <li className="ui-menu-item ui-menu-item--helper-text">
                    {I18n.t('Create theme based on')} &hellip;
                  </li>
                  {
                    ['globalThemes', 'accountSpecificThemes'].map(collection =>
                      _.map(thingsToShow[collection], sharedConfig =>
                        <li>
                          <a
                            aria-role="button"
                            href="javascript:;"
                            onClick={() => this.startEditing({md5ToActivate: sharedConfig.brand_config.md5})}
                          >
                            {sharedConfig.name}
                          </a>
                        </li>
                      )
                    )
                  }
                </ul>
              </div>
            </div>
          </div>
          {thingsToShow.globalThemes &&
            <div className="ic-ThemeCard-container">

              <h3 className="ic-ThemeCard-container__Heading">
                <span className="ic-ThemeCard-container__Heading-text">
                  {I18n.t('Templates')}
                  <button
                    type="button"
                    className="Button Button--icon-action"
                    data-tooltip='{"tooltipClass":"popover popover-padded", "position":"left"}'
                    title={I18n.t('Default templates are used as starting points for new themes and cannot be deleted.')}
                  >
                    <i className="icon-question" aria-hidden="true" />
                  </button>
                </span>
              </h3>

              <div className="ic-ThemeCard-container__Main">
                {thingsToShow.globalThemes.map(this.renderCard)}
              </div>

            </div>
          }

          {thingsToShow.accountSpecificThemes &&
            <div className="ic-ThemeCard-container">
              <h3 className="ic-ThemeCard-container__Heading">
                <span className="ic-ThemeCard-container__Heading-text">
                  {I18n.t('My Themes')}
                </span>
              </h3>
              <div className="ic-ThemeCard-container__Main">
                {thingsToShow.accountSpecificThemes.map(this.renderCard)}
              </div>
            </div>
          }

        </div>
      )
    }
  })
})
