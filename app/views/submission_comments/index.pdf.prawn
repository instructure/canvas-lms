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
  # initialize and set primary (latin) font for normal, bold, and italic styles
  pdf.font_families.update(
    "LatoWeb" => {
      normal: "public/fonts/lato/latin/LatoLatin-Regular.ttf",
      italic: "public/fonts/lato/latin/LatoLatin-Italic.ttf",
      bold: "public/fonts/lato/latin/LatoLatin-Bold.ttf",
    }
  )
  pdf.font("LatoWeb")

  # initialize and set non-Latin fallback fonts using only the “Regular” style
  fallback_fonts = %w[NotoSansJP NotoSansKR NotoSansSC NotoSansTC NotoSansThai NotoSansArabic NotoSansHebrew NotoSansArmenian]
  fallback_fonts.each do |font_name|
    font_path = "#{File.dirname(__FILE__)}/fonts/noto_sans/#{font_name}-Regular.ttf"
    pdf.font_families.update(font_name => {
                               normal: { file: font_path, subset: true },
                               bold: { file: font_path, subset: true },
                               italic: { file: font_path, subset: true }
                             })
  end
  pdf.fallback_fonts(fallback_fonts)

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
    comment_body = "#{comment.body}#{draft_markup}"
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
