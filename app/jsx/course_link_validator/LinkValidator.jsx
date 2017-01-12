define([
  'jquery',
  'react',
  'i18n!link_validator',
  './ValidatorResults'
], function($, React, I18n, ValidatorResults) {

  var LinkValidator = React.createClass({
    getInitialState () {
      return {
        results: [],
        displayResults: false,
        error: false,
      };
    },

    componentWillMount () {
      this.setLoadingState();
      this.getResults(true);
    },

    getResults (initial_load) {
      $.ajax({
        url: ENV.validation_api_url,
        dataType: 'json',
        success: (data) => {
          // Keep trying until the request has been completed
          if (data.state === 'queued' || data.state === 'running') {
            setTimeout(() => {
              this.getResults();
            }, 10000);
          } else {
            if (data.state === 'completed') {
              this.setState({
                buttonMessage: I18n.t("Restart Link Validation"),
                buttonDisabled: false,
                results: data.issues,
                displayResults: true,
                error: false,
              });
              $('#all-results').show();
            } else {
              this.setState({
                buttonMessage: I18n.t("Start Link Validation"),
                buttonDisabled: false
              });
              if (data.state === 'failed' && !initial_load) {
                this.setState({
                  error: true
                });
              }
            }
          }
        },
        error: () => {
          this.setState({
            error: true
          });
        }
      })
    },
    setLoadingState () {
      this.setState({
        buttonMessage: I18n.t("Loading..."),
        buttonDisabled: true,
      });
    },
    startValidation () {
      $('#all-results').hide();

      this.setLoadingState();

      // You need to send a POST request to the API to initialize validation
      $.ajax({
        url: ENV.validation_api_url,
        type: "POST",
        data: {},
        success: () => {
          var getResults = this.getResults;
          setTimeout(() => {
            getResults();
          }, 2000);
        },
        error: () => {
          this.setState({
            error: true
          });
        }
      });
    },

    render () {
      var loadingImage;
      if (this.state.buttonDisabled) {
        loadingImage = <img src="/images/ajax-loader.gif"/>;
      }
      return (
        <div>
          <button onClick={this.startValidation} className="Button Button--primary"
                  disabled={this.state.buttonDisabled}
                  style={this.state.buttonMessageStyle} type="button" role="button">
            {this.state.buttonMessage}
          </button>
          {loadingImage}

          <ValidatorResults
            results={this.state.results}
            displayResults={this.state.displayResults}
            error={this.state.error}
          />
        </div>
      );
    }
  });

  return LinkValidator;
});