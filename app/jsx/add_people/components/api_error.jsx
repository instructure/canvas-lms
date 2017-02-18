define([
  'i18n!roster',
  'react',
  'instructure-ui'
], (I18n, React, {Alert}) => {
  class ApiError extends React.Component {
    static propTypes = {
      error: React.PropTypes.oneOfType([
        React.PropTypes.string,
        React.PropTypes.arrayOf(React.PropTypes.string)
      ]).isRequired
    };

    renderErrorList () {
      return (
        <div className="addpeople__apierror">
          {I18n.t('The following users could not be created.')}
          <ul className="apierror__error_list">
            {
              this.props.error.map((e, i) => <li key={i}>{e}</li>)
            }
          </ul>
        </div>
      );
    }

    // render the list of login_ids where we did not find users
    render () {
      return (
        <Alert variant="error">
          {Array.isArray(this.props.error) ? this.renderErrorList() : this.props.error}
        </Alert>
      )
    }
  }

  return ApiError;
});
