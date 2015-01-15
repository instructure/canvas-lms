module AlignmentsHelper
  def link_to_outcome_alignment(context, outcome, alignment=nil)
    html_class = [
      "title"
    ]
    html_class << "icon-#{alignment.content_type.downcase}" if alignment
    link_to(alignment.try(:title) || nbsp, outcome_alignment_url(context, outcome, alignment), {
      class: html_class
    })
  end

  def outcome_alignment_tag(context, outcome, alignment=nil, &block)
    options = {
      id: "alignment_#{alignment.try(:id) || "blank"}",
      class: [
        "alignment",
        alignment.try(:content_type_class),
        alignment.try(:graded?) ? "also_assignment" : nil
      ].compact,
      data: {
        id: alignment.try(:id),
        has_rubric_association: alignment.try(:has_rubric_association?),
        url: outcome_alignment_url(
          context, outcome, alignment
        )
      }.delete_if { |_, v|
        !v.present?
      }
    }
    options[:style] = hidden unless alignment

    content_tag(:li, options, &block)
  end

  def outcome_alignment_url(context, outcome, alignment=nil)
    if alignment.present?
      [
        context_prefix(alignment.context_code), "outcomes",
        outcome.id, "alignments", alignment.id
      ].join('/')
    else
      context_url(
        context, :context_outcome_alignment_redirect_url,
        outcome.id, "{{ id }}"
      )
    end
  end
end
