import React from 'react'
import I18n from 'i18n!account_authorization_configs'
import Select from 'instructure-ui/lib/components/Select'

  class AuthTypePicker extends React.Component {

    static propTypes = {
      authTypes: React.PropTypes.arrayOf(React.PropTypes.shape({
        value: React.PropTypes.string,
        name: React.PropTypes.string
      })).isRequired,
      onChange: React.PropTypes.func
    };

    static defaultProps = {
      authTypes: [],
      onChange () {}
    };

    constructor (props) {
      super(props);
      this.state = {
        authType: 'default'
      };
    }

    handleChange = (event) => {
      const authType = event.target.value;
      this.setState({ authType });
      this.props.onChange(authType);
    }

    renderAuthTypeOptions () {
      return this.props.authTypes.map(authType => (
        <option
          key={authType.value}
          value={authType.value}
        >
          {authType.name}
        </option>
      ));
    }

    render () {
      const label = (
        <span className="add" style={{ display: 'block' }}>
          {I18n.t('Add an identity provider to this account:')}
        </span>
      )

      return (
        <div>
          <Select
            label={label}
            id="add_auth_select"
            onChange={this.handleChange}
            value={this.state.authType}
          >
            {this.renderAuthTypeOptions()}
          </Select>
        </div>
      );
    }

  }

export default AuthTypePicker
