# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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
#

module QuizMathDataFixup
  def fixup_quiz_questions_with_bad_math(quiz_or_bank, check_date: nil, question_bank: false)
    changed = false
    questions = if question_bank
                  quiz_or_bank.assessment_questions
                else
                  quiz_or_bank.quiz_questions
                end
    questions = questions.where("updated_at>?", check_date) if check_date
    questions.find_each do |quiz_question|
      old_data = quiz_question.question_data.to_hash
      new_data = fixup_question_data(quiz_question.question_data.to_hash.symbolize_keys)
      quiz_question.write_attribute(:question_data, new_data) if new_data != old_data
      if quiz_question.changed?
        stat = question_bank ? "updated_math_qb_question" : "updated_math_question"
        InstStatsd::Statsd.increment(stat)
        changed = true
        quiz_question.save!
      end
    rescue => e
      Canvas::Errors.capture(e)
    end
    qstat = question_bank ? "updated_math_question_bank" : "updated_math_quiz"
    InstStatsd::Statsd.increment(qstat) if changed
    quiz_or_bank
  end

  def fixup_submission_questions_with_bad_math(submission)
    submission.questions&.each_with_index do |question, index|
      data = fixup_question_data(question)
      submission.questions[index] = data
    rescue => e
      Canvas::Errors.capture(e)
    end
    begin
      submission.save! if submission.changed?
    rescue => e
      Canvas::Errors.capture(e)
    end
  end

  def fixup_question_data(data)
    %i[neutral_comments_html correct_comments_html incorrect_comments_html].each do |key|
      data[key] = fixup_html(data[key]) if data[key].present?
    end

    data[:question_text] = fixup_html(data[:question_text]) if data[:question_text].present?

    data[:answers].map(&:symbolize_keys).each_with_index do |answer, index|
      %i[html comments_html].each do |key|
        # if there's html, the text field is used as the title attribute/tooltip
        # clear it out if we updated the html because it's probably hosed.
        next unless answer[key].present?

        answer[key] = fixup_html(answer[key])

        text_key = key.to_s.sub("html", "text")
        answer[text_key] = "" if answer[text_key].present?
      end
      data[:answers][index] = answer
    end
    data
  end

  def fixup_html(html_str)
    return html_str unless html_str

    html = Nokogiri::HTML5.fragment(html_str)
    if html.children.length == 1 && html.children[0].node_type == Nokogiri::XML::Node::TEXT_NODE
      # look for an equation_images URL in the text and extract the latex
      m = %r{equation_images/([^\s]+)}.match(html.content)
      if m && m[1]
        code = URI::DEFAULT_PARSER.unescape(URI::DEFAULT_PARSER.unescape(m[1]))
        html =
          "<img class='equation_image' src='/equation_images/#{m[1]}' alt='LaTeX: #{code}' title='#{
            code
          }' data-equation-content='#{code}'/>"
      else
        # look for \(inline latex\) and extract it
        m = html.content.match(/\\\(((?!\\\)).+)\\\)/)
        if m && m[1]
          code = URI::DEFAULT_PARSER.unescape(URI::DEFAULT_PARSER.unescape(m[1]))
          html =
            "<img class='equation_image' src='/equation_images/#{m[1]}' alt='LaTeX: #{
              code
            }' title='#{code}' data-equation-content='#{code}'/>"
        end
      end
      html.search('[id^="MathJax"]').each(&:remove)
      return html.to_s
    end
    html.search(".math_equation_latex").each do |latex|
      # find MathJax generated children, extract the eq's mathml
      # incase we need it later, then remove them
      mjnodes =
        html.search('[class^="MathJax"]')

      unless mjnodes.empty?
        n = mjnodes.filter("[data-mathml]")[0]
        mml = n.attribute("data-mathml") if n
        mjnodes.each(&:remove)
      end
      if !latex.content.empty?
        if latex.content !~ /^(:?\\\(|\$\$).+(:?\\\)|\$\$)$/ && latex.content !~ /[\\+-^=<>]|{.+}/
          # the content is not delimineted latex,
          # and doesn't even _look like_ latex
          # remove math_equation_latex from the class then leave it alone

          latex.attribute("class").value =
            latex.attribute("class").value.sub("math_equation_latex", "").strip
        else
          code = latex.content.gsub(/(^\\\(|\\\)$)/, "")
          escaped = URI::DEFAULT_PARSER.escape(URI::DEFAULT_PARSER.escape(code))
          latex.replace(
            "<img class='equation_image' src='/equation_images/#{escaped}' alt='LaTeX: #{
              code
            }' title='#{code}' data-equation-content='#{code}'/>"
          )
        end
      elsif mml
        latex.replace(
          "<span class='math_equation_mml'><math xmlns='http://www.w3.org/1998/Math/MathML'>#{
            mml
          }</math></span>"
        )
      end
    end

    html.search('[id^="MathJax"]').each(&:remove)
    html.search("span.hidden-readable").each(&:remove)

    return html_str if html.content.empty? && html.search("img.equation_image").empty?

    html.to_s
  end

  def check_or_fix_quizzes(batch_of_ids)
    Quizzes::Quiz.where(id: batch_of_ids).find_each { |q| fixup_quiz_questions_with_bad_math(q) }
  end

  def check_or_fix_question_banks(batch_of_ids)
    AssessmentQuestionBank.where(id: batch_of_ids).find_each do |q|
      fixup_quiz_questions_with_bad_math(q, question_bank: true)
    end
  end
end
