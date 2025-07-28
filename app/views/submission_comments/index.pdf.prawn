# frozen_string_literal: true

# Copyright (C) 2024 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

# i18nliner/i18n_extractor currently do not support prawn templates
# so pass I18nable strins from the controller until this is resovled

require "prawn/emoji"
require "pathname"

prawn_document(page_layout: :portrait, page_size:) do |pdf|
  # set primary font to Helvetica for Latin script (handles normal, bold, and italic styles)
  pdf.font("Helvetica")

  # initialize and set non-Latin fallback fonts using only the “Regular” style
  non_latin_fallback_fonts = %w[NotoSansJP NotoSansKR NotoSansSC NotoSansTC NotoSansThai NotoSansArabic NotoSansHebrew NotoSansArmenian]
  non_latin_fallback_fonts.each do |font_name|
    font_path = "#{File.dirname(__FILE__)}/fonts/noto_sans/#{font_name}-Regular.ttf"
    pdf.font_families.update(font_name => {
                               normal: { file: font_path, subset: true },
                               bold: { file: font_path, subset: true },
                               italic: { file: font_path, subset: true }
                             })
  end

  pdf.font_families.update(
    # add DejaVuSans font for general Unicode support
    "DejaVuSans" => {
      normal: "#{File.dirname(__FILE__)}/fonts/DejaVuSans.ttf"
    },
    # add NotoEmoji font for emoji support
    "NotoEmoji" => {
      normal: "#{File.dirname(__FILE__)}/fonts/NotoEmoji-Regular.ttf"
    }
  )

  # set the fallback fonts
  pdf.fallback_fonts(non_latin_fallback_fonts + %w[NotoEmoji DejaVuSans])

  pdf.font_size 8
  pdf.text assignment_title, size: pdf.font_size * 2.375
  pdf.text course_name
  pdf.text student_name
  pdf.text score
  pdf.text account_name
  pdf.move_down 5

  current_author = nil
  submission_comments.find_each do |comment|
    draft_markup = comment.draft? ? " <color rgb='ff0000'>#{draft}</color>" : ""

    # escape '<' followed by a space with a unique placeholder to prevent Nokogiri
    # from converting '&lt;' back to '<'. This ensures that '<' is safely converted
    # to '&lt;' after the HTML to text conversion
    escaped_body = comment.body.to_s.gsub(/<(?=\s)/, "{{{LT_PLACEHOLDER}}}")
    comment_body = "#{html_to_text(escaped_body)}#{draft_markup}"
    comment_body.gsub!("{{{LT_PLACEHOLDER}}}", "&lt;")

    comment_body_and_timestamp = "#{comment_body} #{timestamps_by_id.fetch(comment.id)}"

    if comment.author_id.nil? || comment.author_id != current_author
      # comment from new author, display name, not indented
      pdf.text "<b>#{comment.author_name}</b>: #{comment_body_and_timestamp}", inline_format: true
      current_author = comment.author_id
    else
      # continuing comments from same author, do not display name, indented
      pdf.indent(10) do
        pdf.text comment_body_and_timestamp, inline_format: true
      end
    end
  end
end
