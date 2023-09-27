# i18nliner/i18n_extractor currently do not support prawn templates
# so pass I18nable strins from the controller until this is resovled

require 'prawn/emoji'

prawn_document(page_layout: :portrait, page_size: page_size) do |pdf|
  pdf.font_families.update('LatoWeb' => {
    normal: "public/fonts/lato/latin/LatoLatin-Regular.ttf",
    italic: "public/fonts/lato/latin/LatoLatin-Italic.ttf",
    bold: "public/fonts/lato/latin/LatoLatin-Bold.ttf",
    light: "public/fonts/lato/latin/LatoLatin-Light.ttf",
  })

  pdf.font("LatoWeb") do
    pdf.font_size 8
    pdf.font_size pdf.font_size() * 2.375  do
      pdf.text assignment_title
    end
    pdf.text course_name
    pdf.text student_name
    pdf.text score
    pdf.text account_name

    pdf.move_down 5

    current_author = nil
    submission_comments.find_each do |comment|
      comment_body = "#{comment.body}#{comment.draft? ? " <color rgb=\'ff0000\'>#{draft}</color>" : ''}"
      comment_body_and_timestamp = "#{comment_body} #{timestamps_by_id.fetch(comment.id)}"

      current_author = if comment.author_id.nil? || comment.author_id != current_author
        pdf.text "<b>#{comment.author_name}</b>: #{comment_body_and_timestamp}", inline_format: true
        comment.author_id
      else
        pdf.indent(10) do
          pdf.text comment_body_and_timestamp, inline_format: true
        end
        current_author
      end
    end
  end
end
