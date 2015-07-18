/** @jsx React.DOM */
define([
  'react',
  'i18n!account_authorization_configs',
  'react-select-box',
  'jquery' /* $ */
], function(React, I18n, ReactSelectBox, $) {

  var SelectBox = React.createFactory(ReactSelectBox);
  var AuthTypePicker = React.createClass({

    displayName: 'AuthTypePicker',

    propTypes: {
      authTypes: React.PropTypes.array.isRequired,
      onChange: React.PropTypes.func
    },

    getInitialState: function(){
      return { authType: null };
    },

    getDefaultProps: function(){
      return {
        authTypes: [],
        onChange: function(){}
      };
    },

    handleChange: function(authType){
      this.setState({authType: authType});
      this.props.onChange(authType);
    },

    renderAuthTypeOptions: function(){
      return this.props.authTypes.map( (authType) => {
        return( <option key={authType['value']}
                        value={authType['value']}>
                  {authType['name']}
                </option> );
      });
    },

    render: function(){

      return (
        <div>
          <span className="add" style={ { display: 'block' }}>
            {I18n.t("Add an identity provider to this account:")}
          </span>
          <SelectBox label={I18n.t("Choose an authentication service")}
                     id='add_auth_select'
                     onChange={this.handleChange}>
            {this.renderAuthTypeOptions()}
          </SelectBox>
        </div>
      );
    }

  });

  return AuthTypePicker;

});
