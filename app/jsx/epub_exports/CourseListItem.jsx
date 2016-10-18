define([
  'react',
  'underscore',
  'jsx/epub_exports/GenerateLink',
  'jsx/epub_exports/DownloadLink',
  'jsx/shared/ApiProgressBar',
  'jsx/epub_exports/CourseStore',
  'i18n!epub_exports',
  'jsx/shared/FriendlyDatetime',
  'classnames'
], function(React, _, GenerateLink, DownloadLink, ApiProgressBar, CourseEpubExportStore, I18n, FriendlyDatetime, classnames) {
  var CourseListItem = React.createClass({
    displayName: 'CourseListItem',
    propTypes: {
      course: React.PropTypes.object.isRequired
    },

    epubExport () {
      return this.props.course.epub_export || {};
    },

    //
    // Rendering
    //

    getDisplayState() {
      var state;

      if (_.isEmpty(this.epubExport())) {
        return null;
      };

      switch(this.epubExport().workflow_state) {
        case 'generated':
          state = I18n.t("Generated:");
          break;
        case 'failed':
          state = I18n.t("Failed:");
          break;
        default:
          state = I18n.t("Generating:");
      };
      return state;
    },
    getDisplayTimestamp() {
      var timestamp;

      if (_.isEmpty(this.epubExport())) {
        return null;
      };
      timestamp = this.epubExport().updated_at;

      return <FriendlyDatetime dateTime={timestamp} />;
    },

    render() {
      var course = this.props.course,
        classes = {
          'ig-row': true
      };
      classes[this.epubExport().workflow_state] = !_.isEmpty(this.epubExport());

      return (
        <li>
          <div className={classnames(classes)}>
            <div className="ig-row__layout">
              <span className="ig-title">
                {course.name}
              </span>
              <div className="ig-details">
                <div className="ellipses">
                  {this.getDisplayState()} {this.getDisplayTimestamp()}
                </div>
              </div>
              <div className="ig-admin epub-exports-admin-controls">
                <ApiProgressBar progress_id={this.epubExport().progress_id}
                  onComplete={this._onComplete}
                  key={this.epubExport().progress_id} />
                <DownloadLink course={this.props.course} />
                <GenerateLink course={this.props.course} />
              </div>
            </div>
          </div>
        </li>
      );
    },

    //
    // Callbacks
    //

    _onComplete () {
      CourseEpubExportStore.get(this.props.course.id, this.epubExport().id);
    },
  });

  return CourseListItem;
});

