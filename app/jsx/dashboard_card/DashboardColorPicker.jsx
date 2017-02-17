define([
  'underscore',
  'react',
  'jquery',
  'i18n!dashcards',
  'jsx/shared/ColorPicker',
  'jsx/shared/proptypes/DOMElement',
  'classnames'
], (_, React, $, I18n, ColorPicker, DOMElement, cx) => {
  // ================
  //   COLOR PICKER
  // ================

  var SPACE_NEEDED_FOR_TOOLTIP = 300;

  var ColorPickerTooltip = React.createClass({

    propTypes: {
      elementID: React.PropTypes.string,
      isOpen: React.PropTypes.bool,
      settingsToggle: DOMElement
    },

    getDefaultProps () {
      return {
        elementID: '',
        isOpen: false,
        settingsToggle: null
      }
    },

    // =================
    //     LIFECYCLE
    // =================

    componentDidMount: function () {
      this.setHandlers();
    },

    componentWillUnmount: function() {
      this.unsetHandlers();
    },

    // =================
    //      ACTIONS
    // =================

    closeIfClickedOutsideOf: function(e){
      if (this.isMounted()) {

        const settingsToggle = this.props.settingsToggle;
        if (!$.contains(this.container, e.target) && !$.contains(settingsToggle, e.target) && this.props.isOpen) {
          this.props.doneEditing(e);
        }
      }
    },

    checkEsc: function(e){
      if (e.keyCode != 27) {
        return
      }
      if (this.isMounted()) {
        if ($.contains(this.container, document.activeElement) && this.props.isOpen) {
          this.props.doneEditing(e);
        }
      }
    },

    setHandlers: function(){
      $(window).resize( this.props.doneEditing );
      $(document).mouseup(this.closeIfClickedOutsideOf);
      $(document).keyup(this.checkEsc);
    },

    unsetHandlers: function(){
      $(document).unbind("keyup", this.checkEsc);
      $(document).unbind("mouseup", this.closeIfClickedOutsideOf);
      $(window).unbind("resize", this.props.doneEditing);
    },

    // =================
    //     RENDERING
    // =================

    rightOfScreen: function(){
      return $(window).width();
    },

    leftPlusElement: function(){
      var parentWidth = $(this.props.parentNode).outerWidth();
      return $(this.props.parentNode).offset().left + parentWidth;
    },

    tooltipOnRight: function(){
      var spaceToRight = this.rightOfScreen() - this.leftPlusElement();
      var spaceNeeded = SPACE_NEEDED_FOR_TOOLTIP;
      return spaceToRight >= spaceNeeded;
    },

    topPosition: function(){
      return $(this.props.parentNode).position().top - 6;
    },

    leftPosition: function(){
      return this.tooltipOnRight() ?
        (this.leftPlusElement() - 80) :
        (this.leftPlusElement() - 360)
    },

    pickerToolTipStyle: function() {
      if (this.props.isOpen) {
        return {
          position: 'absolute',
          top: this.topPosition(),
          left: this.leftPosition(),
          zIndex: 9999
        };
      } else {
        return {
          display: 'none'
        };
      }
    },

    render: function () {
      var classes = cx({
        'ic-DashboardCardColorPicker': true,
        'right': this.isOpen && !this.tooltipOnRight(),
        'horizontal': true
      });

      return (
        <div
          id={this.props.elementID}
          className={classes}
          style={this.pickerToolTipStyle()}
          ref={(c) => { this.container = c; }}
        >
          <ColorPicker isOpen           = {this.props.isOpen}
                       assetString      = {this.props.assetString}
                       afterClose       = {this.props.doneEditing}
                       afterUpdateColor = {this.props.handleColorChange}
                       hidePrompt       = {true}
                       nonModal         = {true}
                       hideOnScroll     = {false}
                       currentColor     = {this.props.backgroundColor}
                       nicknameInfo     = {this.props.nicknameInfo}
          />
        </div>
      )
    }
  })

  return ColorPickerTooltip;
});
