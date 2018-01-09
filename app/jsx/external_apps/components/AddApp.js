/*
 * Copyright (C) 2014 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import I18n from 'i18n!external_tools'
import _ from 'underscore'
import $ from 'jquery'
import React from 'react'
import PropTypes from 'prop-types'
import Modal from 'react-modal'
import ConfigOptionField from '../../external_apps/components/ConfigOptionField'
import ExternalTool from 'compiled/models/ExternalTool'
import 'jquery.disableWhileLoading'
import 'compiled/jquery.rails_flash_notifications'

  const modalOverrides = {
    overlay : {
      backgroundColor: 'rgba(0,0,0,0.5)'
    },
    content : {
      position: 'static',
      top: '0',
      left: '0',
      right: 'auto',
      bottom: 'auto',
      borderRadius: '0',
      border: 'none',
      padding: '0'
    }
  };

export default React.createClass({
    displayName: 'AddApp',

    propTypes: {
      handleToolInstalled: PropTypes.func.isRequired,
      app: PropTypes.object.isRequired,
      canAddEdit: PropTypes.bool.isRequired
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

    configSettings() {
      var queryParams = {};
      _.map(this.state.fields, function(v, k) {
        if(v.type == "checkbox") {
          if(!v.value) return;
          queryParams[k] = '1';
        } else
          queryParams[k] = encodeURIComponent(v.value);
      });
      delete queryParams['consumer_key'];
      delete queryParams['shared_secret'];

      return queryParams;
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

      newTool.set('name', this.state.fields.name.value);
      newTool.set('app_center_id', this.props.app.short_name);
      newTool.set('config_settings', this.configSettings())

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
            style={modalOverrides}
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
      );
    }
  });
