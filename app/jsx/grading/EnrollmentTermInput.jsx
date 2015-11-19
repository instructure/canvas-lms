define([
  'react',
  'underscore',
  'axios',
  'convert_case',
  'i18n!grading_periods',
  'bower/react-tokeninput/dist/react-tokeninput',
], function(React, _, axios, ConvertCase, I18n, TokenInput) {
  let ComboboxOption = TokenInput.Option;
  TokenInput = TokenInput.default;

  const groupByTagType = function(options) {
    const now = new Date;
    return _.groupBy(options, (option) => {
      const noStartDate = !_.isDate(option.startAt);
      const noEndDate =   !_.isDate(option.endAt);
      const started = option.startAt < now;
      const ended =   option.endAt < now;

      if ((started && !ended) ||
          (started && noEndDate) ||
          (!ended  && noStartDate)) {
        return 'active';
      } else if (!started) {
        return 'future';
      } else if (ended) {
        return 'past';
      }
      return 'undated';
    });
  };

  let EnrollmentTermInput = React.createClass({

    propTypes: {
      enrollmentTerms: React.PropTypes.array.isRequired,
      setSelectedEnrollmentTermIDs: React.PropTypes.func.isRequired,
      selectedIDs: React.PropTypes.array.isRequired
    },

    handleChange(termIDs) {
      this.props.setSelectedEnrollmentTermIDs(termIDs);
    },

    handleSelect(value, _combobox) {
      const termIDs = _.pluck(this.props.enrollmentTerms, "id");
      if(_.contains(termIDs, value)) {
        const selectedIDs = _.uniq(this.props.selectedIDs.concat([value]));
        this.handleChange(selectedIDs);
      }
    },

    handleRemove(termToRemove) {
      const selectedTermIDs = _.reject(this.props.selectedIDs, (termID) => {
        return termToRemove.id === termID;
      });
      this.handleChange(selectedTermIDs);
    },

    selectableTerms() {
      return _.reject(this.props.enrollmentTerms, term => _.contains(this.props.selectedIDs, term.id));
    },

    filteredTagsForType(type) {
      const groupedTags = groupByTagType(this.selectableTerms());
      return (groupedTags && groupedTags[type]) || [];
    },

    selectableOptions(type) {
      return _.map(this.filteredTagsForType(type), (term) => {
        return this.selectableOption(term);
      });
    },


    selectableOption(term) {
      return(
        <ComboboxOption key={term.id} value={term.id}>
          {term.displayName}
        </ComboboxOption>
      );
    },

    optionsForAllTypes() {
      if (_.isEmpty(this.selectableTerms())) {
        return [this.headerOption('none')];
      } else {
        return _.union(
          this.optionsForType('active'),
          this.optionsForType('undated'),
          this.optionsForType('future'),
          this.optionsForType('past')
        );
      }
    },

    optionsForType(optionType) {
      const header = this.headerOption(optionType);
      const options = this.selectableOptions(optionType);
      return _.any(options) ? _.union([header], options) : [];
    },

    headerOption(heading) {
      const headerText = {
        'active': I18n.t('Active'),
        'undated': I18n.t('Undated'),
        'future': I18n.t('Future'),
        'past': I18n.t('Past'),
        'none': I18n.t('No unassigned terms')
      }[heading];
      return(
        <ComboboxOption
          className='ic-tokeninput-header'
          value={heading}
          key={heading}
        >
          {headerText}
        </ComboboxOption>
      );
    },

    suppressKeys(event) {
      const code = event.keyCode || event.which;
      if (code === 13) {
        event.preventDefault();
      }
    },

    selectedEnrollmentTerms() {
      return _.map(this.props.selectedIDs, (id) => {
        let term = _.findWhere(this.props.enrollmentTerms, { id: id });
        let termForDisplay = _.extend({}, term);
        termForDisplay.name = term.displayName;
        return termForDisplay;
      });
    },

    render() {
      return (
        <div className = 'ic-Form-control'
             onKeyDown = {this.suppressKeys}>
          <label className  = 'ic-Label'
               title      = {I18n.t('Attach terms')}
               aria-label = {I18n.t('Attach terms')}>
             {I18n.t('Attach terms')}
          </label>
          <div className='ic-Input'>
            <TokenInput menuContent     = {this.optionsForAllTypes()}
                        selected        = {this.selectedEnrollmentTerms()}
                        onChange        = {this.handleChange}
                        onSelect        = {this.handleSelect}
                        onRemove        = {this.handleRemove}
                        onInput         = {function(){}}
                        value           = {true}
                        showListOnFocus = {true}
                        ref             = 'input' />
          </div>
        </div>
      );
    }
  });
  return EnrollmentTermInput;
});
