import React from 'react'
import _ from 'underscore'
import ProgressStore from 'jsx/shared/stores/ProgressStore'
import ProgressBar from 'jsx/shared/ProgressBar'
  var ApiProgressBar = React.createClass({
    displayName: 'ProgressBar',
    propTypes: {
      progress_id: React.PropTypes.string,
      onComplete: React.PropTypes.func,
      delay: React.PropTypes.number
    },
    intervalID: null,

    //
    // Preparation
    //

    getDefaultProps(){
      return {
        delay: 1000
      }
    },
    getInitialState () {
      return {
        completion: 0,
        workflow_state: null
      }
    },

    //
    // Lifecycle
    //

    componentDidMount () {
      ProgressStore.addChangeListener(this.handleStoreChange);
      this.intervalID = setInterval(this.poll, this.props.delay);
    },
    componentWillUnmount () {
      ProgressStore.removeChangeListener(this.handleStoreChange);
      if (!_.isNull(this.intervalID)) {
        clearInterval(this.intervalID);
        this.intervalID = null;
      };
    },

    shouldComponentUpdate (nextProps, nextState) {
      return this.state.workflow_state != nextState.workflow_state ||
        this.state.completion != nextState.completion ||
        this.props.progress_id != nextProps.progress_id;
    },
    componentDidUpdate () {
      if (this.isComplete()) {
        if (!_.isNull(this.intervalID)) {
          clearInterval(this.intervalID);
          this.intervalID = null;
        };

        if (!_.isUndefined(this.props.onComplete)) {
          this.props.onComplete();
        };
      };
    },

    //
    // Custom Helpers
    //

    handleStoreChange () {
      var progress = ProgressStore.getState()[this.props.progress_id];

      if (_.isObject(progress)) {
        this.setState({
          completion: progress.completion,
          workflow_state: progress.workflow_state
        });
      };
    },
    isComplete () {
      return _.contains(['completed', 'failed'], this.state.workflow_state);
    },
    isInProgress () {
      return _.contains(['queued', 'running'], this.state.workflow_state);
    },
    poll () {
      if (!_.isUndefined(this.props.progress_id)) {
        ProgressStore.get(this.props.progress_id);
      }
    },

    //
    // Render
    //

    render() {
      if (!this.isInProgress()) {
        return null;
      };

      return (
        <div style={{width: '300px'}}>
          <ProgressBar progress={this.state.completion} />
        </div>
      );
    }
  });

export default ApiProgressBar
