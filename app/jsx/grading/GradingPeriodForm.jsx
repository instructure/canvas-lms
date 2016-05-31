define([
  'react',
  'underscore',
  'i18n!external_tools',
  'jsx/due_dates/DueDateCalendarPicker',
  'jsx/shared/helpers/accessibleDateFormat'
], function(React, _, I18n, DueDateCalendarPicker, accessibleDateFormat) {
  const types = React.PropTypes;

  const buildPeriod = function(attr) {
    return {
      id:        attr.id,
      title:     attr.title,
      startDate: attr.startDate || new Date(''),
      endDate:   attr.endDate || new Date('')
    };
  };

  let GradingPeriodForm = React.createClass({
    propTypes: {
      period:   types.shape({
        id:        types.string.isRequired,
        title:     types.string.isRequired,
        startDate: types.instanceOf(Date).isRequired,
        endDate:   types.instanceOf(Date).isRequired
      }),
      disabled: types.bool.isRequired,
      onSave:   types.func.isRequired,
      onCancel: types.func.isRequired
    },

    getInitialState: function() {
      return {
        period: buildPeriod(this.props.period || {})
      };
    },

    componentDidMount: function() {
      this.hackTheDatepickers();
      React.findDOMNode(this.refs.title).focus();
    },

    render: function() {
      return (
        <div className='GradingPeriodForm'>
          <div className="grid-row">
            <div className="col-xs-12 col-lg-8">
              <div className="ic-Form-group ic-Form-group--horizontal">
                <div className="ic-Form-control">
                  <label className="ic-Label" htmlFor="title">
                    {I18n.t("Grading Period Title")}
                  </label>
                  <input id='title'
                         ref='title'
                         className='ic-Input'
                         title={I18n.t('Grading Period Title')}
                         defaultValue={this.state.period.title}
                         onChange={this.changeTitle}
                         type='text'/>
                </div>

                <div className="ic-Form-control">
                  <div className="ic-Label" aria-hidden="true">
                    {I18n.t("Start Date")}
                  </div>

                  <div className="ic-Multi-input">
                    <div className="ic-Input-group">
                      <label className="screenreader-only" htmlFor="start-date">
                        {I18n.t("Start Date")}
                      </label>
                      <DueDateCalendarPicker dateValue    = {this.state.period.startDate}
                                             ref          = "startDate"
                                             dateType     = "due_at"
                                             handleUpdate = {this.changeStartDate}
                                             rowKey       = "start-date"
                                             labelledBy   = "start-date" />
                    </div>

                    <span aria-hidden="true">{I18n.t("Until")}</span>

                    <div className="ic-Input-group">
                      <label className="screenreader-only" htmlFor="end-date">
                        {I18n.t("End Date")}
                      </label>
                      <DueDateCalendarPicker dateValue    = {this.state.period.endDate}
                                             ref          = "endDate"
                                             dateType     = "due_at"
                                             handleUpdate = {this.changeEndDate}
                                             rowKey       = "end-date"
                                             labelledBy   = "end-date" />
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {this.renderSaveAndCancelButtons()}
        </div>
      );
    },

    renderSaveAndCancelButtons: function() {
      return (
        <div className="ic-Form-actions below-line">
          <button className = "Button"
                  type      = "button"
                  ref       = "cancelButton"
                  disabled  = {this.props.disabled}
                  onClick   = {this.triggerCancel}>
            {I18n.t("Cancel")}
          </button>
          <button className  = "Button Button--primary"
                  type       = "submit"
                  ref        = "saveButton"
                  aria-label = {I18n.t("Save Grading Period")}
                  disabled   = {this.props.disabled}
                  onClick    = {this.triggerSave}>
            {I18n.t("Save")}
          </button>
        </div>
      );
    },

    changeTitle: function(e) {
      let period = _.clone(this.state.period);
      period.title = e.target.value;
      this.setState({period: period});
    },

    changeStartDate: function(date) {
      let period = _.clone(this.state.period);
      period.startDate = date;
      this.setState({period: period});
    },

    changeEndDate: function(date) {
      let period = _.clone(this.state.period);
      period.endDate = date;
      this.setState({period: period});
    },

    triggerSave: function() {
      if (this.props.onSave) {
        this.props.onSave(this.state.period);
      }
    },

    triggerCancel: function() {
      if (this.props.onCancel) {
        this.setState({period: buildPeriod({})}, this.props.onCancel);
      }
    },

    hackTheDatepickers: function() {
      // This can be replaced when we have an extensible datepicker
      let $form = React.findDOMNode(this);
      let $appends = $form.querySelectorAll('.input-append');
      Array.prototype.forEach.call($appends, function($el) {
        $el.classList.add('ic-Input-group');
      });
      let $dateFields = $form.querySelectorAll('.date_field');
      Array.prototype.forEach.call($dateFields, function($el) {
        $el.classList.remove('date_field');
        $el.classList.add('ic-Input');
      });
      let $suggests = $form.querySelectorAll('.datetime_suggest');
      Array.prototype.forEach.call($suggests, function($el) {
        $el.remove();
      });
      let $buttons = $form.querySelectorAll('.ui-datepicker-trigger');
      Array.prototype.forEach.call($buttons, function($el) {
        $el.classList.remove('btn');
        $el.classList.add('Button');
      });
      let $container = $form.querySelectorAll('.DueDateInput__Container');
      Array.prototype.forEach.call($container, function($el) {
        $el.classList.add('ic-Input-group');
      });
    }
  });

  return GradingPeriodForm;
});
