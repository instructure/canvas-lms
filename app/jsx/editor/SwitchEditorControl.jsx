define([
  'react',
  'i18n!editor',
  'jsx/shared/rce/RichContentEditor'
], function(React, I18n, RichContentEditor){

  var SwitchEditorControl = React.createClass({
    displayName: 'SwitchEditor',
    propTypes: {
      textarea: React.PropTypes.object.isRequired
    },

    getInitialState () {
      return { mode: "rce" };
    },

    toggle(e){
      e.preventDefault()
      RichContentEditor.callOnRCE(this.props.textarea, 'toggle')
      if(this.state.mode == "rce"){
        this.setState({mode: "html"})
      }else{
        this.setState({mode: "rce"})
      }
    },

    //
    // Rendering
    //

    switchLinkText(){
      if(this.state.mode == 'rce'){
        return I18n.t('switch_editor_html', 'HTML Editor')
      }else {
        return I18n.t('switch_editor_rich_text', 'Rich Content Editor')
      }
    },

    linkClass(){
      if(this.state.mode == 'rce'){
        return "switch-views__link__html"
      }else {
        return "switch-views__link__rce"
      }
    },

    render() {
      return (
        <div style={{float: "right"}}>
          <a href="#" className={this.linkClass()} onClick={this.toggle}>
            {this.switchLinkText()}
          </a>
        </div>
      );
    }
  });

  return SwitchEditorControl;
});
