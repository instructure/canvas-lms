/** @jsx React.DOM */

define([
  'i18n!external_tools',
  'underscore',
  'jquery',
  'react',
  'react-modal',
  'jsx/external_apps/components/ConfigOptionField',
  'compiled/models/ExternalTool',
  'jquery.disableWhileLoading',
  'compiled/jquery.rails_flash_notifications'
], function(I18n, _, $, React, Modal, ConfigOptionField, ExternalTool) {

  return React.createClass({
    displayName: 'AddApp',

    propTypes: {
      handleToolInstalled: React.PropTypes.func.isRequired,
      app: React.PropTypes.object.isRequired
    },

    getInitialState() {
      return {
        modalIsOpen: false,
        isValid: false,
        errorMessage: null,
        fields: {}
      }
    },

    componentDidMount() {
      var fields = {};

      fields['name'] = {
        type: 'text',
        value: this.props.app.name,
        required: true,
        description: I18n.t('Name')
      };

      if (this.props.app.requires_secret) {
        fields['consumer_key'] = {
          type: 'text',
          value: '',
          required: true,
          description: I18n.t('Consumer Key')
        };
        fields['shared_secret'] = {
          type: 'text',
          value: '',
          required: true,
          description: I18n.t('Shared Secret')
        };
      }

      this.props.app.config_options.map(function(opt) {
        fields[opt.name] = {
          type: opt.param_type,
          value: opt.default_value,
          required: (opt.is_required || opt.is_required === 1),
          description: opt.description
        };
      });

      if (this.isMounted()) {
        this.setState({fields: fields}, this.validateConfig);
        this.refs.addTool.getDOMNode().focus();
      }
    },

    handleChange(e) {
      var target = e.target
        , value  = target.value
        , name   = $(target).data('rel')
        , fields = this.state.fields;

      if (target.type === 'checkbox') {
        value = target.checked;
      }

      fields[name].value = value;
      this.setState({ fields: fields }, this.validateConfig);
    },

    validateConfig() {
      var invalidFields = _.compact(
        _.map(this.state.fields, function(v, k) {
          if (v.required && _.isEmpty(v.value)) {
            return k;
          }
        })
      );
      this.setState({invalidFields: invalidFields});
      this.setState({ isValid: _.isEmpty(invalidFields) });
    },

    openModal(e) {
      e.preventDefault();
      if (this.isMounted()) {
        this.setState({modalIsOpen: true});
      }
    },

    closeModal(cb) {
      if (typeof cb === "function") {
        this.setState({modalIsOpen: false}, cb);
      } else {
        this.setState({modalIsOpen: false});
      }
    },

    configUrl() {
      var url = this.props.app.config_xml_url;

      var queryParams = {};
      _.map(this.state.fields, function(v, k) {
        if(v.type == "checkbox") {
          if(!v.value) return;
          queryParams[k] = '1';
        } else
          queryParams[k] = v.value;
      });
      delete queryParams['consumer_key'];
      delete queryParams['shared_secret'];

      var newUrl = url + (url.indexOf('?') !== -1 ? '&' : '?') + $.param(queryParams);
      return newUrl;
    },

    submit(e) {
      var newTool = new ExternalTool();
      newTool.on('sync', this.onSaveSuccess, this);
      newTool.on('error', this.onSaveFail, this);
      if (!_.isEmpty(this.state.invalidFields)){
        var fields = this.state.fields
        var invalidFieldNames = _.map(this.state.invalidFields, function(k){
          return fields[k].description
        }).join(', ');
        this.setState({
          errorMessage: I18n.t('The following fields are invalid: %{fields}', {fields: invalidFieldNames})
        });
        return
      }

      if (this.props.app.requires_secret) {
        newTool.set('consumer_key', this.state.fields.consumer_key.value);
        newTool.set('shared_secret', this.state.fields.shared_secret.value);
      } else {
        newTool.set('consumer_key', 'N/A');
        newTool.set('shared_secret', 'N/A');
      }

      newTool.set('config_url', this.configUrl());
      newTool.set('config_type', 'by_url');
      newTool.set('name', this.state.fields.name.value);
      newTool.set('app_center_id', this.props.app.short_name);

      $(e.target).attr('disabled', 'disabled');
      
      newTool.save();
    },

    onSaveSuccess(tool) {
      $(this.refs.addButton.getDOMNode()).removeAttr('disabled');
      tool.off('sync', this.onSaveSuccess);
      this.setState({ errorMessage: null });
      this.closeModal(this.props.handleToolInstalled);
    },

    onSaveFail(tool) {
      $(this.refs.addButton.getDOMNode()).removeAttr('disabled');
      this.setState({
        errorMessage: I18n.t('There was an error in processing your request')
      });
    },

    configOptions() {
      return _.map(this.state.fields, function(v, k) {
        return (
          <ConfigOptionField
            name={k}
            type={v.type}
            ref={'option_' + k}
            key={'option_' + k}
            value={v.value}
            required={v.required}
            aria-required={v.required}
            description={v.description}
            handleChange={this.handleChange} />
        );
      }.bind(this));
    },

    errorMessage: function() {
      if (this.state.errorMessage) {
       $.screenReaderFlashMessage(this.state.errorMessage);
        return <div className="alert alert-error">{this.state.errorMessage}</div>;
      }
    },

    render() {
      return (
        <div className="AddApp">
          <a href="#" ref="addTool" className="btn btn-primary btn-block add_app icon-add" onClick={this.openModal}>{I18n.t('Add App')}</a>

          <Modal className="ReactModal__Content--canvas"
            overlayClassName="ReactModal__Overlay--canvas"
            isOpen={this.state.modalIsOpen}
            onRequestClose={this.closeModal}>

            <div className="ReactModal__Layout">

              <div className="ReactModal__Header">
                <div className="ReactModal__Header-Title">
                  <h4>{I18n.t('Add App')}</h4>
                </div>
                <div className="ReactModal__Header-Actions">
                  <button className="Button Button--icon-action" type="button" onClick={this.closeModal}>
                    <i className="icon-x"></i>
                    <span className="screenreader-only">Close</span>
                  </button>
                </div>
              </div>

              <div className="ReactModal__Body">
                {this.errorMessage()}
                <form role="form">
                  {this.configOptions()}
                </form>
              </div>

              <div className="ReactModal__Footer">
                <div className="ReactModal__Footer-Actions">
                  <button type="button" className="btn btn-default" onClick={this.closeModal}>{I18n.t('Close')}</button>
                  <button type="button" ref="addButton" className="btn btn-primary" onClick={this.submit}>{I18n.t('Add App')}</button>
                </div>
              </div>
            </div>

          </Modal>
        </div>
      )
    }
  });
});
