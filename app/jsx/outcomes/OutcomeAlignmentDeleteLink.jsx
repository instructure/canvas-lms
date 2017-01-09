define([
  'react',
  'i18n!outcomes'
], (React, I18n) => {
  var OutcomeAlignmentDeleteLink = React.createClass({
    handleClick(e) {
      var $li = $(e.target).parents('li.alignment');

      e.preventDefault();
      $(e.target).confirmDelete({
        success: function(data) {
          $li.fadeOut('slow', function() {
            this.remove();
          });
        },
        url: this.props.url
      });
    },

    hasRubricAssociation() {
      return this.props.has_rubric_association;
    },

    render() {
      if (this.hasRubricAssociation()) {
        return (
          <span className="locked_alignment_link">
            <i className="icon-lock" aria-hidden="true"></i>
            <span className="screenreader-only"> {I18n.t(
              "Can't delete alignments based on rubric associations.  To remove these associations you need to remove the row from the asset's rubric"
            )} </span>
          </span>
        );
      } else {
        return (
          <a className="delete_alignment_link no-hover"
            href="" onClick={this.handleClick}>
            <i className="icon-end" aria-hidden="true"></i>
            <span className="screenreader-only">{I18n.t("Delete alignment")}</span>
          </a>
        );
      }
    }
  });

  return OutcomeAlignmentDeleteLink;
});
