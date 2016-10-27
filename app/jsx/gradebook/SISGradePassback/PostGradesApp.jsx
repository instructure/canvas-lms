define([
  'react',
  'react-dom',
  'i18n!modules',
  'jsx/gradebook/SISGradePassback/PostGradesDialog',
  'classnames'
], (React, ReactDOM, I18n, PostGradesDialog, classnames) => {

  // The PostGradesApp mounts a single "Post Grades" button, which pops up
  // the PostGradesDialog when clicked.

  var PostGradesApp = React.createClass({
    componentDidMount () {
      this.boundForceUpdate = this.forceUpdate.bind(this)
      this.props.store.addChangeListener(this.boundForceUpdate)
    },
    componentWillUnmount () { this.props.store.removeChangeListener(this.boundForceUpdate) },

    render () {
      var navClass = classnames({
        "ui-button": this.props.renderAsButton
      });
      if(this.props.renderAsButton){
        return (
          <button
            id="post-grades-button"
            className={navClass}
            onClick={this.openDialog}
          >{this.props.labelText}</button>
        );
      } else {
        return (
          <a
            id="post-grades-button"
            className={navClass}
            onClick={this.openDialog}
          >{this.props.labelText}</a>
        );
      }
    },

    openDialog(e) {
      e.preventDefault();
      var returnFocusTo = this.props.returnFocusTo;

      var $dialog = $('<div class="post-grades-dialog">').dialog({
        title: I18n.t("Post Grades to SIS"),
        maxWidth: 650,     maxHeight: 450,
        minWidth: 650,     minHeight: 450,
        width:    650,     height:    450,
        resizable: false,
        buttons: [],
        close(e) {
          ReactDOM.unmountComponentAtNode(this);
          $(this).remove();
          if(returnFocusTo){
            returnFocusTo.focus();
          }
        }
      });

      var closeDialog = function(e) {
        e.preventDefault();
        $dialog.dialog('close');
      }

      this.props.store.reset()
      ReactDOM.render(<PostGradesDialog store={this.props.store} closeDialog={closeDialog} />, $dialog[0]);
    },
  });

  return PostGradesApp;
});
