/** @jsx React.DOM */
define(function(require) {
  var React = require('old_version_of_react_used_by_canvas_quizzes_client_apps');
  var K = require('../../constants');
  var I18n = require('i18n!quiz_statistics.discrimination_index');
  var classSet = require('canvas_quizzes/util/class_set');
  var Dialog = require('jsx!canvas_quizzes/components/dialog');
  var ScreenReaderContent = require('jsx!canvas_quizzes/components/screen_reader_content');
  var SightedUserContent = require('jsx!canvas_quizzes/components/sighted_user_content');
  var Help = require('jsx!./discrimination_index/help');
  var formatNumber = require('../../util/format_number');

  var DiscriminationIndex = React.createClass({
    getDefaultProps: function() {
      return {
        width: 200,
        height: 14 * 3,
        discriminationIndex: 0,
        topStudentCount: 0,
        middleStudentCount: 0,
        bottomStudentCount: 0,
        correctTopStudentCount: 0,
        correctMiddleStudentCount: 0,
        correctBottomStudentCount: 0,
      };
    },

    render: function() {
      var di = this.props.discriminationIndex;
      var passing = di > K.DISCRIMINATION_INDEX_THRESHOLD ? '+' : '-';
      var sign = di == 0 ? '' : di > 0 ? '+' : '-'; // "", "-", or "+"
      var className = {
        'index': true,
        'positive': passing === '+',
        'negative': passing !== '+'
      };

      return (
        <section className="discrimination-index-section">
          <div>
            <SightedUserContent>
              <em className={classSet(className)}>
                <span className="sign">{sign}</span>
                {formatNumber(Math.abs(this.props.discriminationIndex || 0))}
              </em>
              <p>{I18n.t('discrimination_index', 'Discrimination Index')}
                <Dialog
                  tagName="button"
                  title={I18n.t('discrimination_index_dialog_title', 'The Discrimination Index Chart')}
                  content={Help}
                  width={550}
                  className="Button Button--icon-action help-trigger"
                  aria-label={I18n.t('discrimination_index_dialog_trigger', 'Learn more about the Discrimination Index.')}
                  tabIndex="0" >
                    <i className="icon-question"></i>
                  </Dialog>
              </p>
            </SightedUserContent>

            <ScreenReaderContent>
              {I18n.t('audible_discrimination_index', 'Discrimination Index: %{number}.', {
                number: formatNumber(this.props.discriminationIndex || 0)
              })}
            </ScreenReaderContent>
          </div>
        </section>
      );
    }
  });

  return DiscriminationIndex;
});
