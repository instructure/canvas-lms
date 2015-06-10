/** @jsx React.DOM */
define(function(require) {
  var React = require('../../ext/react');
  var $ = require('canvas_packages/jquery');
  var Status = require('jsx!./report/status');
  var Popup = require('jsx!canvas_quizzes/components/popup');
  var ScreenReaderContent = require('jsx!canvas_quizzes/components/screen_reader_content');
  var SightedUserContent = require('jsx!canvas_quizzes/components/sighted_user_content');
  var Descriptor = require('../../models/quiz_report_descriptor');

  var Report = React.createClass({
    mixins: [ React.addons.ActorMixin ],

    propTypes: {
      generatable: React.PropTypes.bool
    },

    getInitialState: function() {
      return {
        tooltipContent: '',
        statusLayer: null
      };
    },

    getDefaultProps: function() {
      return {
        readableType: 'Analysis Report',
        generatable: true,
        isGenerated: false,
        downloadUrl: undefined
      };
    },

    componentDidUpdate: function(prevProps/*, prevState*/) {
      // Restore focus to the generation button which is now the download button
      if (!prevProps.isGenerated && this.props.isGenerated) {
        if (this.refs.popup.screenReaderContentHasFocus()) {
          this.refs.popup.focusAnchor();
        }
      }
      else if (!prevProps.isGenerating && this.props.isGenerating) {
        if (!this.refs.popup.screenReaderContentHasFocus()) {
          this.refs.popup.focusScreenReaderContent(true);
        }
      }
    },

    render: function() {
      var id = this.props.reportType;

      return (
        <div className="report-generator inline">
          <Popup
            ref="popup"
            content={Status}
            id={this.props.id}
            isGenerated={this.props.isGenerated}
            isGenerating={this.props.isGenerating}
            generatable={this.props.generatable}
            progress={this.props.progress}
            file={this.props.file}
            reactivePositioning
            anchorSelector=".btn"
            popupOptions={
              {
                show: {
                  event: 'mouseenter focusin',
                  delay: 0,
                  effect: false,
                  solo: true
                },

                hide: {
                  event: 'mouseleave focusout',
                  delay: 350,
                  effect: false,
                  fixed: true,
                },

                position: {
                  my: 'bottom center',
                  at: 'top center'
                }
              }
            }>
            {this.props.isGenerated ?
              this.renderDownloader() :
              this.renderGenerator()
            }
          </Popup>
        </div>
      );
    },

    renderGenerator: function() {
      var srLabel = Descriptor.getInteractionLabel(this.props);

      return (
        <button
          disabled={!this.props.generatable}
          onClick={this.generate}
          onKeyPress={this.generateAndFocusContent}
          className="btn btn-link generate-report">
            <ScreenReaderContent children={srLabel} />
            <SightedUserContent>
              <i className="icon-analytics" /> {this.props.readableType}
            </SightedUserContent>
        </button>
      );
    },

    renderDownloader: function() {
      var srLabel = Descriptor.getInteractionLabel(this.props);

      return(
        <a href={this.props.file.url} className="btn btn-link download-report">
          <ScreenReaderContent children={srLabel} />

          <SightedUserContent>
            <i className="icon-analytics" /> {this.props.readableType}
          </SightedUserContent>
        </a>
      );
    },

    generate: function(e) {
      e.preventDefault();

      this.sendAction('quizReports:generate', this.props.reportType);
    },

    generateAndFocusContent: function(e) {
      e.preventDefault();

      this.sendAction('quizReports:generate', this.props.reportType);
    }
  });

  return Report;
});