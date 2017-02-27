define([
  'react',
  'i18n!outcomes',
  'jquery'
], (React, I18n, $) => {
  class OutcomeAlignmentDeleteLink extends React.Component {
    static propTypes = {
      url: React.PropTypes.string.isRequired,
      has_rubric_association: React.PropTypes.string
    }

    handleClick = (e) => {
      const $li = $(e.target).parents('li.alignment');

      e.preventDefault();
      $(e.target).confirmDelete({
        success () {
          $li.fadeOut('slow', function () {
            this.remove();
          });
        },
        url: this.props.url
      });
    }

    hasRubricAssociation () {
      return this.props.has_rubric_association;
    }

    render () {
      if (this.hasRubricAssociation()) {
        return (
          <span className="locked_alignment_link">
            <i className="icon-lock" aria-hidden="true" />
            <span className="screenreader-only"> {I18n.t(
              "Can't delete alignments based on rubric associations.  To remove these associations you need to remove the row from the asset's rubric"
            )} </span>
          </span>
        );
      }
      return (
        <a
          className="delete_alignment_link no-hover"
          href="" onClick={this.handleClick}
        >
          <i className="icon-end" aria-hidden="true" />
          <span className="screenreader-only">{I18n.t('Delete alignment')}</span>
        </a>
      );
    }
  }

  return OutcomeAlignmentDeleteLink;
});
