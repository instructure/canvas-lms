define([
  'react',
  'react-dom',
  'react-addons-update',
  'underscore',
  'instructure-ui/Button',
  'i18n!external_tools',
  'jsx/due_dates/DueDateCalendarPicker',
  'jsx/shared/helpers/accessibleDateFormat'
], function(React, ReactDOM, update, _, { default: Button }, I18n,
  DueDateCalendarPicker, accessibleDateFormat) {

  const Types = React.PropTypes;

  const buildPeriod = function(attr) {
    return {
      id:        attr.id,
      title:     attr.title,
      startDate: attr.startDate,
      endDate:   attr.endDate,
      closeDate: attr.closeDate
    };
  };

  const hasDistinctCloseDate = ({ endDate, closeDate }) => {
    return closeDate && !_.isEqual(endDate, closeDate);
  };

  const mergePeriod = (form, attr) => {
    return update(form.state.period, {$merge: attr});
  }

  const changeTitle = function(e) {
    let period = mergePeriod(this, {title: e.target.value});
    this.setState({period: period});
  };

  const changeStartDate = function(date) {
    let period = mergePeriod(this, {startDate: date});
    this.setState({period: period});
  };

  const changeEndDate = function(date) {
    let attr = {endDate: date};
    if (!this.state.preserveCloseDate && !hasDistinctCloseDate(this.state.period)) {
      attr.closeDate = date;
    }
    let period = mergePeriod(this, attr);
    this.setState({period: period});
  };

  const changeCloseDate = function(date) {
    let period = mergePeriod(this, {closeDate: date});
    this.setState({period: period, preserveCloseDate: !!date});
  };

  let GradingPeriodForm = React.createClass({
    propTypes: {
      period:   Types.shape({
        id:        Types.string.isRequired,
        title:     Types.string.isRequired,
        startDate: Types.instanceOf(Date).isRequired,
        endDate:   Types.instanceOf(Date).isRequired,
        closeDate: Types.instanceOf(Date)
      }),
      disabled: Types.bool.isRequired,
      onSave:   Types.func.isRequired,
      onCancel: Types.func.isRequired
    },

    getInitialState: function() {
      let period = buildPeriod(this.props.period || {});
      return {
        period: period,
        preserveCloseDate: hasDistinctCloseDate(period)
      };
    },

    componentDidMount: function() {
      this.hackTheDatepickers();
      this.refs.title.focus();
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
      let $form = ReactDOM.findDOMNode(this);
      let $appends = $form.querySelectorAll('.input-append');
      $appends.forEach(function($el) {
        $el.classList.add('ic-Input-group');
      });

      let $dateFields = $form.querySelectorAll('.date_field');
      $dateFields.forEach(function($el) {
        $el.classList.remove('date_field');
        $el.classList.add('ic-Input');
      });

      let $suggests = $form.querySelectorAll('.datetime_suggest');
      $suggests.forEach(function($el) {
        if(ENV.CONTEXT_TIMEZONE === ENV.TIMEZONE) {
          $el.remove();
        } else {
          $el.innerHTML = $el.innerHTML.replace(/Course/, 'Account');
        }
      });

      let $buttons = $form.querySelectorAll('.ui-datepicker-trigger');
      $buttons.forEach(function($el) {
        $el.classList.remove('btn');
        $el.classList.add('Button');
      });
    },

    renderSaveAndCancelButtons: function() {
      return (
        <div className="ic-Form-actions below-line">
          <Button
            ref       = "cancelButton"
            disabled  = {this.props.disabled}
            onClick   = {this.triggerCancel}
          >
            {I18n.t("Cancel")}
          </Button>
          &nbsp;
          <Button
            variant    = "primary"
            ref        = "saveButton"
            aria-label = {I18n.t("Save Grading Period")}
            disabled   = {this.props.disabled}
            onClick    = {this.triggerSave}
          >
            {I18n.t("Save")}
          </Button>
        </div>
      );
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
                  <input
                    id='title'
                    ref='title'
                    className='ic-Input'
                    title={I18n.t('Grading Period Title')}
                    defaultValue={this.state.period.title}
                    onChange={changeTitle.bind(this)}
                    type='text'
                  />
                </div>

                <div className="ic-Form-control">
                  <label id="start-date-label" htmlFor="start-date" className="ic-Label">
                    {I18n.t("Start Date")}
                  </label>
                  <DueDateCalendarPicker
                    disabled             = {false}
                    inputClasses         = ''
                    dateValue            = {this.state.period.startDate}
                    ref                  = "startDate"
                    dateType             = "due_at"
                    handleUpdate         = {changeStartDate.bind(this)}
                    rowKey               = "start-date"
                    labelledBy           = "start-date-label"
                    isFancyMidnight      = {false}
                  />
                </div>

                <div className="ic-Form-control">
                  <label id="end-date-label" htmlFor="end-date" className="ic-Label">
                    {I18n.t("End Date")}
                  </label>
                  <DueDateCalendarPicker
                    disabled             = {false}
                    inputClasses         = ''
                    dateValue            = {this.state.period.endDate}
                    ref                  = "endDate"
                    dateType             = "due_at"
                    handleUpdate         = {changeEndDate.bind(this)}
                    rowKey               = "end-date"
                    labelledBy           = "end-date-label"
                    isFancyMidnight      = {true}
                  />
                </div>

                <div className="ic-Form-control">
                  <label id="close-date-label" htmlFor="close-date" className="ic-Label">
                    {I18n.t("Close Date")}
                  </label>
                  <DueDateCalendarPicker
                    disabled             = {false}
                    inputClasses         = ''
                    dateValue            = {this.state.period.closeDate}
                    ref                  = "closeDate"
                    dateType             = "due_at"
                    handleUpdate         = {changeCloseDate.bind(this)}
                    rowKey               = "close-date"
                    labelledBy           = "close-date-label"
                    isFancyMidnight      = {true}
                  />
                </div>
              </div>
            </div>
          </div>

          {this.renderSaveAndCancelButtons()}
        </div>
      );
    }
  });

  return GradingPeriodForm;
});
