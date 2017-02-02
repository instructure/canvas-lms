/** @jsx React.DOM */
define(function(require) {
  var React = require('old_version_of_react_used_by_canvas_quizzes_client_apps');
  var classSet = require('canvas_quizzes/util/class_set');
  var K = require('../../constants');
  var secondsToTime = require('canvas_quizzes/util/seconds_to_time');
  var I18n = require('i18n!quiz_log_auditing.event_stream');
  var Icon = require('jsx!canvas_quizzes/components/icon');
  var SightedUserContent = require('jsx!canvas_quizzes/components/sighted_user_content');
  var Router = require('old_version_of_react-router_used_by_canvas_quizzes_client_apps');
  var Link = Router.Link;


  var Event = React.createClass({
    getDefaultProps: function() {
      return {
        startedAt: new Date()
      };
    },

    render: function() {
      var e = this.props;
      var className = classSet({
        'ic-ActionLog__Entry': true,
        'is-warning': e.flag === K.EVT_FLAG_WARNING,
        'is-ok': e.flag === K.EVT_FLAG_OK,
        'is-neutral': !e.flag
      });
      return (
        <li className={className} key={"event-"+e.id}>
          {this.renderRow(e)}
        </li>
      );
    },

    renderRow: function(e) {
      var secondsSinceStart = (
        new Date(e.createdAt) - new Date(e.startedAt)
      ) / 1000;

      return (
        <div>
          <span className="ic-ActionLog__EntryTimestamp">
            {secondsToTime(secondsSinceStart)}
          </span>

          <SightedUserContent className="ic-ActionLog__EntryFlag">
            {this.renderFlag(e.flag)}
          </SightedUserContent>

          <div className="ic-ActionLog__EntryDescription">
            {this.renderDescription(e)}
          </div>
        </div>
      );
    },

    renderFlag: function(flag) {
      var content = null;

      if (flag === K.EVT_FLAG_WARNING) {
        content = <Icon icon="icon-trouble" />
      }
      else if (flag === K.EVT_FLAG_OK) {
        content = <Icon icon="icon-complete" />
      }
      else {
        content = <Icon icon="icon-empty" />
      }

      return content;
    },

    renderDescription: function(event) {
      var description;
      var label;
      switch(event.type) {
        case K.EVT_SESSION_STARTED:
          description = I18n.t('session_started', 'Session started');
        break;

        case K.EVT_QUESTION_ANSWERED:
          var valid_answers = event.data.filter(function(i) {
            return (i.answer != null);
          })
          if(valid_answers.length == 0) {
            break;
          }
          label = I18n.t('question_answered', {
            one: 'Answered question:',
            other: 'Answered the following questions:'
          }, { count: valid_answers.length });

          description = (
            <div>
              {label}

              <div className="ic-QuestionAnchors">
                {valid_answers.map(this.renderQuestionAnchor)}
              </div>
            </div>
          );
        break;

        case K.EVT_QUESTION_VIEWED:
          label = I18n.t('question_viewed', {
            one: 'Viewed (and possibly read) question',
            other: 'Viewed (and possibly read) the following questions:'
          }, { count: event.data.length });

          description = (
            <div>
              {label}

              <div className="ic-QuestionAnchors">
                {event.data.map(this.renderQuestionAnchor)}
              </div>
            </div>
          );
        break;

        case K.EVT_PAGE_BLURRED:
          description = I18n.t('page_blurred',
            'Stopped viewing the Canvas quiz-taking page...');
        break;

        case K.EVT_PAGE_FOCUSED:
          description = I18n.t('page_focused', 'Resumed.');
        break;

        case K.EVT_QUESTION_FLAGGED:
          if (event.data.flagged) {
            label = I18n.t('question_flagged', 'Flagged question:');
          }
          else {
            label = I18n.t('question_unflagged', 'Unflagged question:');
          }

          description = (
            <div>
              {label}

              <div className="ic-QuestionAnchors">
                {this.renderQuestionAnchor(event.data.questionId)}
              </div>
            </div>
          );
        break;
      }

      return description;
    },

    renderQuestionAnchor: function(record) {
      var id;
      var question;
      var position;

      if (typeof record === 'object') {
        id = record.quizQuestionId;
      }
      else {
        id = record;
      }

      question = this.props.questions.filter(function(q) {
        return q.id === id;
      })[0];

      position = question && question.position

      return (
        <Link
          key={"question-anchor"+id}
          to="question"
          params={{id: id}}
          className="ic-QuestionAnchors__Anchor"
          query={{ event: this.props.id, attempt: this.props.attempt }}
          children={'#'+position} />
      );
    }
  });

  return Event;
});
