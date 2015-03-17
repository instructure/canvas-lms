/** @jsx React.DOM */

define([
  'jquery',
  'underscore',
  'old_unsupported_dont_use_react',
  'i18n!course_wizard',
  './ListItems'
], function($, _, React, I18n, ListItems) {

  var courseNotSetUpItem = {
    text: I18n.t("Great, so you've got a course. Now what? Well, before you go publishing it to the world, you may want to check and make sure you've got the basics laid out.  Work through the list on the left to ensure that your course is ready to use."),
    warning: I18n.t("This course is visible only to teachers until it is published."),
    iconClass: 'icon-instructure'
  };

  var checklistComplete = {
    text: I18n.t("Now that your course is set up and available, you probably won't need this checklist anymore. But we'll keep it around in case you realize later you want to try something new, or you just want a little extra help as you make changes to your course content."),
    iconClass: 'icon-instructure'
  };

  var InfoFrame = React.createClass({
      displayName: 'InfoFrame',

      getInitialState: function () {
        return {
          itemShown: courseNotSetUpItem,
        };
      },

      componentWillMount: function () {
        if (ENV.COURSE_WIZARD.checklist_states.publish_step) {
          this.setState({
            itemShown: checklistComplete
          });
        }
      },

      componentWillReceiveProps: function (newProps) {
        this.getWizardItem(newProps.itemToShow);
      },

      getWizardItem: function (key) {
        var item = _.findWhere(ListItems, {key: key});

        this.setState({
          itemShown: item
        }, function () {
          $messageBox = $(this.refs.messageBox.getDOMNode());
          $messageIcon = $(this.refs.messageIcon.getDOMNode());

          // I would use .toggle, but it has too much potential to get all out
          // of whack having to be called twice to force the animation.

          // Remove the animation classes in case they are there already.
          $messageBox.removeClass('ic-wizard-box__message-inner--is-fired');
          $messageIcon.removeClass('ic-wizard-box__message-icon--is-fired');

          // Add them back
          setTimeout(function() {
            $messageBox.addClass('ic-wizard-box__message-inner--is-fired');
            $messageIcon.addClass('ic-wizard-box__message-icon--is-fired');
          }, 100);




          // Set the focus to the call to action 'button' if it's there
          // otherwise the text.
          if (this.refs.callToAction) {
            this.refs.callToAction.getDOMNode().focus();
          } else {
            this.refs.messageBox.getDOMNode().focus();
          }
        });
      },

      getHref: function () {
        return this.state.itemShown.url || '#';
      },

      chooseHomePage: function (event) {
        event.preventDefault();
        this.props.closeModal();
        $('.choose_home_page_link').click();
      },


      renderButton: function () {
        if (this.state.itemShown.key === 'home_page') {
          return (<a ref="callToAction" onClick={this.chooseHomePage} className="Button Button--primary">
            {this.state.itemShown.title}
          </a>
          );
        }
        if (this.state.itemShown.key === 'publish_course') {
          return (
            <form accept-charset="UTF-8" action={ENV.COURSE_WIZARD.publish_course} method="post">
              <input name="utf8" type="hidden" value="✓" />
              <input name="_method" type="hidden" value="put" />
              <input name="authenticity_token" type="hidden" value={$.cookie('_csrf_token')} />
              <input type="hidden" name="course[event]" value="offer"/>
              <button ref="callToAction" type="submit" className="Button Button--success">{this.state.itemShown.title}</button>
            </form>
          );
        }
        if (this.state.itemShown.hasOwnProperty('title')) {
          return (
            <a ref="callToAction" href={this.getHref()} className="Button Button--primary">
              {this.state.itemShown.title}
            </a>
          );
        }
        else if (this.state.itemShown.hasOwnProperty('warning')) {
          return <b>{this.state.itemShown.warning}</b>
        }
        else {
          return null;
        }
      },

      render: function () {
          return (
              <div className={this.props.className}>
                <h1 className="ic-wizard-box__headline">
                   {I18n.t("Next Steps")}
                </h1>
                <div className="ic-wizard-box__message">
                  <div className="ic-wizard-box__message-layout">
                    <div ref="messageIcon" className="ic-wizard-box__message-icon ic-wizard-box__message-icon--is-fired">
                      <i className={this.state.itemShown.iconClass}></i>
                    </div>
                    <div ref="messageBox" tabIndex="-1" className="ic-wizard-box__message-inner ic-wizard-box__message-inner--is-fired">
                      <p className="ic-wizard-box__message-text">
                        {this.state.itemShown.text}
                      </p>
                      <div className="ic-wizard-box__message-button">
                        {this.renderButton()}
                      </div>
                    </div>
                  </div>
                </div>
              </div>
          );
      }
  });

  return InfoFrame;

});