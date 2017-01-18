define([
  'i18n!theme_editor',
  'react',
  'jquery',
  './PropTypes',
  'jsx/shared/modal',
  'jsx/shared/modal-content',
  'jsx/shared/modal-buttons'
], (I18n, React, $, customTypes, Modal, ModalContent, ModalButtons) => {

  return React.createClass({

    displayName: 'SaveThemeButton',

    propTypes: {
      accountID: React.PropTypes.string.isRequired,
      brandConfigMd5: customTypes.md5,
      sharedBrandConfigBeingEdited: customTypes.sharedBrandConfig.isRequired,
      onSave: React.PropTypes.func.isRequired
    },

    getInitialState() {
      return {
        newThemeName: '',
        modalIsOpen: false
      }
    },

    save () {
      const shouldUpdate = !!(this.props.sharedBrandConfigBeingEdited &&
                              this.props.sharedBrandConfigBeingEdited.id)

      const params = {brand_config_md5: this.props.brandConfigMd5}

      let url, method
      if (shouldUpdate) {
        url = `/api/v1/accounts/${this.props.accountID}/shared_brand_configs/${this.props.sharedBrandConfigBeingEdited.id}`
        method = 'PUT'
      } else {
        if (!this.state.newThemeName) {
          this.setState({modalIsOpen: true})
          return
        }
        params.name = this.state.newThemeName
        url = `/api/v1/accounts/${this.props.accountID}/shared_brand_configs`
        method = 'POST'
      }

      return $.ajaxJSON(url, method, {shared_brand_config: params}, (updatedSharedConfig) => {
        this.setState({modalIsOpen: false})
        this.props.onSave(updatedSharedConfig)
      })
    },

    render() {
      let disable = false
      let disableMessage
      if (this.props.userNeedsToPreviewFirst) {
        disable = true
        disableMessage = I18n.t('You need to "Preview Changes" before saving')
      } else if (this.props.sharedBrandConfigBeingEdited &&
                 this.props.sharedBrandConfigBeingEdited.brand_config_md5 === this.props.brandConfigMd5) {
        disable = true
        disableMessage = I18n.t('There are no unsaved changes')
      } else if (!this.props.brandConfigMd5) {
        disable = true
      }

      return (
        <div
          className="pull-left"
          data-tooltip="left"
          title={disableMessage}
        >
          <button
            type="button"
            className="Button Button--primary"
            disabled={disable}
            onClick={this.save}
          >
            {I18n.t('Save theme')}
          </button>
          <Modal
            title={I18n.t('Theme Name')}
            onSubmit={this.save}
            isOpen={this.state.modalIsOpen}
          >
            <ModalContent>
              <div className="ic-Form-control">
                <label
                  htmlFor="new_theme_theme_name"
                  className="ic-Label"
                >
                  {I18n.t('Theme Name')}
                </label>
                <input
                  type="text"
                  id="new_theme_theme_name"
                  className="ic-Input"
                  placeholder={I18n.t('Pick a name to save this theme as')}
                  onChange={(e) => this.setState({newThemeName: e.target.value})}
                />
              </div>
            </ModalContent>
            <ModalButtons>
              <button
                type='button'
                className='Button'
                onClick={() => this.setState({modalIsOpen:false})}
              >
                {I18n.t('Cancel')}
              </button>
              <button
                type='submit'
                disabled={!this.state.newThemeName}
                className="Button Button--primary"
              >
                {I18n.t('Save theme')}
              </button>
            </ModalButtons>
          </Modal>
        </div>
      )
    }
  })
});
