/** @jsx React.DOM */

define([
  'i18n!modules',
  'react',
  'jsx/gradebook/SISGradePassback/PostGradesDialog'
], (I18n, React, PostGradesDialog) => {

  // The PostGradesApp mounts a single "Post Grades" button, which pops up
  // the PostGradesDialog when clicked.

  var PostGradesApp = React.createClass({
    componentDidMount () {
      this.boundForceUpdate = this.forceUpdate.bind(this)
      this.props.store.addChangeListener(this.boundForceUpdate)
    },
    componentWillUnmount () { this.props.store.removeChangeListener(this.boundForceUpdate) },

    render () {
      var navClass = React.addons.classSet({
        "gradebook-navigation": true,
        "nav_style": true,
        "hidden": !this.props.store.isEnabled() || !this.props.store.hasAssignments()
      });
      return (
        <nav className={navClass}>
          <ul className="nav nav-pills gradebook-navigation-pills pull-right">
            <li>
              <button
                 className="btn"
                 onClick={this.openDialog}
                 type="button"
                 id="post-grades-button"
              >
                {I18n.t("Post Grades")}
              </button>
            </li>
          </ul>
        </nav>
      );
    },

    openDialog(e) {
      e.preventDefault();

      var $dialog = $('<div class="post-grades-dialog">').dialog({
        title: I18n.t("Post Grades to SIS"),
        maxWidth: 650,     maxHeight: 450,
        minWidth: 650,     minHeight: 450,
        width:    650,     height:    450,
        resizable: false,
        buttons: [],
        close(e) {
          React.unmountComponentAtNode(this);
          $(this).remove();
        }
      });

      var closeDialog = function(e) {
        e.preventDefault();
        $dialog.dialog('close');
      }

      this.props.store.reset()
      React.renderComponent(<PostGradesDialog store={this.props.store} closeDialog={closeDialog} />, $dialog[0]);
    },
  });

  return PostGradesApp;
});
