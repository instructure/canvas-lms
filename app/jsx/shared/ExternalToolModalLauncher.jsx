define([
  'underscore',
  'jquery',
  'react',
  'jsx/shared/modal',
  'jsx/shared/modal-content',
], function (_, $, React, Modal, ModalContent) {
  return React.createClass({
    displayName: 'ExternalToolModalLauncher',

    propTypes: {
      tool: React.PropTypes.object,
      isOpen: React.PropTypes.bool.isRequired,
      onRequestClose: React.PropTypes.func.isRequired,
      contextType: React.PropTypes.string.isRequired,
      contextId: React.PropTypes.number.isRequired,
      launchType: React.PropTypes.string.isRequired,
    },

    componentDidMount () {
      $(window).on('externalContentReady', this.onExternalToolCompleted);
      $(window).on('externalContentCancel', this.onExternalToolCompleted);
    },

    componentWillUnmount () {
      $(window).off('externalContentReady', this.onExternalToolCompleted);
      $(window).off('externalContentCancel', this.onExternalToolCompleted);
    },

    onExternalToolCompleted () {
      this.props.onRequestClose();
    },

    getIframeSrc () {
      if (this.props.isOpen && this.props.tool) {
        return [
          '/', this.props.contextType, 's/',
          this.props.contextId,
          '/external_tools/', this.props.tool.definition_id,
          '?display=borderless&launch_type=',
          this.props.launchType,
        ].join('');
      }
    },

    getLaunchDimensions () {
      const dimensions = {
        'width': 700,
        'height': 700,
      };

      if (
        this.props.isOpen &&
        this.props.tool &&
        this.props.launchType &&
        this.props.tool['placements'] &&
        this.props.tool['placements'][this.props.launchType]) {

        const placement = this.props.tool['placements'][this.props.launchType];

        if (placement.launch_width) {
          dimensions.width = placement.launch_width;
        }

        if (placement.launch_height) {
          dimensions.height = placement.launch_height;
        }
      }

      return dimensions;
    },

    getModalLaunchStyle (dimensions) {
      return {
        ...dimensions,
        border: 'none',
      };
    },

    getModalBodyStyle (dimensions) {
      return {
        ...dimensions,
        padding: 0,
        display: 'flex',
      };
    },

    getModalStyle (dimensions) {
      return {
        width: dimensions.width,
      };
    },

    render () {
      const dimensions = this.getLaunchDimensions();

      return (
        <Modal className="ReactModal__Content--canvas"
          overlayClassName="ReactModal__Overlay--canvas"
          style={this.getModalStyle(dimensions)}
          isOpen={this.props.isOpen}
          onRequestClose={this.props.onRequestClose}
          title={this.props.title}
        >
          <ModalContent style={this.getModalBodyStyle(dimensions)}>
            <iframe
              src={this.getIframeSrc()}
              style={this.getModalLaunchStyle(dimensions)}
              tabIndex={0}
            ></iframe>
          </ModalContent>
        </Modal>
      );
    }
  });
});
