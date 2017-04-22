/** @jsx React.DOM */
define(function(require) {
  var React = require('old_version_of_react_used_by_canvas_quizzes_client_apps');
  var quizStatistics = require('../../stores/statistics');
  var config = require('../../config');
  var I18n = require('i18n!quiz_statistics');

  var SectionLink = React.createClass({
    handleClick: function(e) {
        e.preventDefault();
        quizStatistics.filterForSection(this.props.sectionId);
      },
    render: function() {
      return (
        <li role="presentation" onClick={this.handleClick}>
          <a href="#" id="toolbar-2" role="menuitem">{this.props.name}</a>
        </li>
      );
    }
  });

  var SectionSelect = React.createClass({
    getInitialState: function() {
      return {sections: []};
    },
    componentDidMount: function() {
      $.ajax({
        url:  config.courseSectionsUrl,
        data: { all: true },
        dataType: 'json',
        cache: false,
        success: function(data) {
          this.setState({sections: data});
        }.bind(this)
      });
    },

    render: function() {
      var sectionTitle = I18n.t('Section Filter')
      if(config.section_ids && config.section_ids != 'all'){
        sectionTitle = $.grep(this.state.sections, function(e){
          return e.id == config.section_ids;
        })[0].name;
      }
      var sectionNodes = this.state.sections.map(function (section, i) {
        return (
          <SectionLink key={i} sectionId={section.id} name={section.name} />
        );
      });

      return(
        <div className="section_selector inline al-dropdown__container">
          <a className="al-trigger btn" role="button" href="#">
            {sectionTitle}
             <i className="icon-mini-arrow-down" aria-hidden="true"></i>
             <span className="screenreader-only">{I18n.t('Section Filter')}</span>
           </a>
          <ul
            id="toolbar-1"
            className="al-options"
            style={{maxHeight: '375px', overflowY: 'scroll'}}
            role="menu"
            tabIndex="0"
            aria-hidden="true"
            aria-expanded="false"
            aria-activedescendant="toolbar-2"
          >
            <SectionLink key={'all'} sectionId={'all'} name={'All Sections'} />
              {sectionNodes}
           </ul>
        </div>
      );
    }
  });

  return SectionSelect;
});
