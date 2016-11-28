define([
  'react',
  'jquery',
  'i18n!eportfolio',
  'instructure-ui/Modal',
  'instructure-ui/Button',
  'instructure-ui/Heading',
  'instructure-ui/Typography',
  'instructure-ui/Select'
], function(React, $, I18n,
  { default: Modal, ModalHeader, ModalBody, ModalFooter },
  { default: Button },
  { default: Heading },
  { default: Typography },
  { default: Select }) {

  var MoveToDialog = React.createClass({
    propTypes: {
      header: React.PropTypes.string.isRequired,
      source: React.PropTypes.object.isRequired,
      destinations: React.PropTypes.arrayOf(React.PropTypes.object).isRequired,
      onMove: React.PropTypes.func,
      onClose: React.PropTypes.func,
      appElement: React.PropTypes.object,
      triggerElement: React.PropTypes.object
    },

    getInitialState () {
      return {
        isOpen: true
      };
    },

    handleMove() {
      if (this.props.onMove) {
        this.props.onMove(this.refs.select.value)
      }
      this.handleRequestClose()
    },

    handleRequestClose() {
      this.setState({ isOpen: false })
    },

    handleClose() {
      if (this.props.appElement) {
        this.props.appElement.removeAttribute('aria-hidden')
      }
      if (this.props.triggerElement) {
        this.props.triggerElement.focus()
      }
      if (this.props.onClose) {
        this.props.onClose()
      }
    },

    handleReady() {
      if (this.props.appElement) {
        this.props.appElement.setAttribute('aria-hidden', true)
      }
    },

    renderBody() {
      const selectLabel = I18n.t('Place "%{section}" before:', {
        section: this.props.source.label
      })

      return (
        <div>
          <Select ref='select' label={selectLabel}>
          {
            this.props.destinations.map((dest) => (
              <option key={dest.id} value={dest.id}>{ dest.label }</option>
            ))
          }
            <option key='move-to-dialog_at-the-bottom' value=''>{ I18n.t('-- At the bottom --') }</option>
          </Select>
        </div>
      )
    },

    render() {
      const dialogLabel = I18n.t('Modal dialog: %{header} %{source}', {
        header: this.props.header,
        source: this.props.source.label
      })
      return (
        <Modal ref='modal' isOpen={this.state.isOpen}
          modalSize='small'
          label={dialogLabel}
          closeButtonLabel={I18n.t('Cancel')}
          onReady={this.handleReady}
          onRequestClose={this.handleRequestClose}
          onClose={this.handleClose}
          zIndex='9999'>
          <ModalHeader>
            <Heading>{ this.props.header }</Heading>
          </ModalHeader>
          <ModalBody>
            { this.renderBody() }
          </ModalBody>
          <ModalFooter>
            <Button id='MoveToDialog__cancel' onClick={this.handleRequestClose}>{I18n.t('Cancel')}</Button>
            <Button id='MoveToDialog__move' variant='primary' onClick={this.handleMove}>{I18n.t('Move')}</Button>
          </ModalFooter>
        </Modal>
      )
    }
  });
  return MoveToDialog;
});
