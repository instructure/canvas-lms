# frozen_string_literal: true

# Copyright (C) 2011 - present Instructure, Inc.
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

require_relative "../../qti_helper"
if Qti.migration_executable
  describe "HTML Sanitization of" do
    describe "question text" do
      it "sanitizes qti v2p1 escaped html" do
        manifest_node = get_manifest_node("multiple_answer")
        hash = Qti::AssessmentItemConverter.create_instructure_question(manifest_node:, base_dir: html_sanitization_question_dir("escaped"))
        expect(hash[:question_text]).to match_ignoring_whitespace "The Media Wizard also allows you to embed images, audio and video from popular websites, such as YouTube and Picasa. You can also link to an image or audio or video file stored on another server. The advantage to linking to a file is that you don't have to copy the original media content to your online course – you just add a link to it. <br><br><b>Question: </b>Respondus can embed video, audio and images from which two popular websites mentioned above?"
      end

      it "tries to escape unmatched brackets" do
        manifest_node = get_manifest_node("unmatched_brackets")
        hash = Qti::AssessmentItemConverter.create_instructure_question(manifest_node:, base_dir: html_sanitization_question_dir("escaped"))
        expect(hash[:question_text]).to match_ignoring_whitespace "<br> I\"m not good at xml so i\"m going to put in some unmatched &lt; brackets here <br> oh here have some more &gt; &gt; &lt;"
      end

      it "sanitizes other escaped html" do # e.g. angel proprietary
        qti_data = file_as_string(html_sanitization_question_dir("escaped"), "angel_essay.xml")
        hash = Qti::AssessmentItemConverter.create_instructure_question(qti_data:, interaction_type: "essay_question", custom_type: "angel")
        expect(hash[:question_text]).to eq "<div>Rhode Island is neither a road nor an island. Discuss. </div>"
      end

      it "is not confused by angle brackets in HTML attributes" do
        manifest_node = get_manifest_node("bracket_attribute")
        hash = Qti::AssessmentItemConverter.create_instructure_question(manifest_node:, base_dir: html_sanitization_question_dir("escaped"))
        expect(hash[:question_text]).to match_ignoring_whitespace %(<img alt="1 < 2">)
      end
    end

    describe "multiple choice text" do
      it "sanitizes and strip qti v2p1 escaped html" do
        manifest_node = get_manifest_node("multiple_choice")
        hash = Qti::AssessmentItemConverter.create_instructure_question(manifest_node:, base_dir: html_sanitization_question_dir("escaped"))
        hash[:answers].each { |a| a.replace(html: a[:html], text: a[:text]) }
        expect(hash[:answers]).to eq [
          { html: "&nbsp;<img src=\"image0014c114649.jpg\" alt=\"\">",
            text: "No answer text provided." },
          { html: nil, # script tag removed
            text: "No answer text provided." },
          { html: "<img src=\"image0034c114649.jpg\" alt=\"\">", # whitespace removed
            text: "No answer text provided." }
        ]
      end

      it "sanitizes and strip qti v2p1 html nodes" do
        manifest_node = get_manifest_node("multiple_choice")
        hash = Qti::AssessmentItemConverter.create_instructure_question(manifest_node:, base_dir: html_sanitization_question_dir("nodes"))
        hash[:answers].each { |a| a.replace(html: a[:html], text: a[:text]) }
        expect(hash[:answers]).to eq [
          { html: nil, text: "nose" }, # no script tags
          { html: nil, text: "ear" }, # whitespace removed
          { html: "<b>eye</b>", text: "eye" },
          { html: nil, text: "mouth" }
        ]
      end
    end

    describe "multiple answer text" do
      it "sanitizes and strip qti v2p1 escaped html" do
        manifest_node = get_manifest_node("multiple_answer")
        hash = Qti::AssessmentItemConverter.create_instructure_question(manifest_node:, base_dir: html_sanitization_question_dir("escaped"))
        hash[:answers].each { |a| a.replace(html: a[:html], text: a[:text]) }
        expect(hash[:answers][0][:html]).to match_ignoring_whitespace("YouTube <br><object width=\"425\" height=\"344\"><param name=\"movie\" value=\"http://www.youtube.com/v/fTQPCocCwJo?f=videos&amp;app=youtube_gdata&amp;rel=0&amp;autoplay=0&amp;loop=0\">\n<embed src=\"http://www.youtube.com/v/fTQPCocCwJo?f=videos&amp;app=youtube_gdata&amp;rel=0&amp;autoplay=0&amp;loop=0\" type=\"application/x-shockwave-flash\" width=\"425\" height=\"344\"></object>")
        expect(hash[:answers][0][:text]).to eq "YouTube"
        expect(hash[:answers][1][:html]).to match_ignoring_whitespace("Google Picasa<br><span style=\"color: #000000;\"><img src=\"http://lh4.ggpht.com/_U8dXqlIRHu8/Ss4167b2RzI/AAAAAAAAABs/MVyeP6FhYDM/picasa-logo.jpg\" width=\"150\" height=\"59\"></span>&nbsp;")
        expect(hash[:answers][1][:text]).to eq "Google Picasa"
        expect(hash[:answers][2][:html]).to eq "Facebook"
        expect(hash[:answers][2][:text]).to eq "Facebook alert(0xFACE)" # no script tags
        expect(hash[:answers][3][:html]).to be_nil
        expect(hash[:answers][3][:text]).to eq "Twitter" # we've stripped off extraneous whitespace
      end

      it "sanitizes and strip qti v2p1 html nodes" do
        manifest_node = get_manifest_node("multiple_answer")
        hash = Qti::AssessmentItemConverter.create_instructure_question(manifest_node:, base_dir: html_sanitization_question_dir("nodes"))
        hash[:answers].each { |a| a.replace(html: a[:html], text: a[:text]) }
        expect(hash[:answers]).to eq [
          { html: "<b>house</b>", text: "house" }, # whitespace removed
          { html: nil, text: "garage" }, # no script tags
          { html: nil, text: "barn" },
          { html: nil, text: "pond" }
        ]
      end
    end

    describe "matching text" do
      it "sanitizes and strip qti v2p1 escaped html" do
        manifest_node = get_manifest_node("matching")
        hash = Qti::AssessmentItemConverter.create_instructure_question(manifest_node:, base_dir: html_sanitization_question_dir("escaped"))
        hash[:answers].each { |a| a.replace(html: a[:html], text: a[:text]) }
        expect(hash[:answers]).to eq [
          { html: "<i>London</i>", text: "London" },
          { html: "<b>Paris</b>", text: "Paris" }, # <b> tag gets closed
          { html: nil, text: "New York" }, # script tag removed
          { html: nil, text: "Toronto" },
          { html: nil, text: "Sydney" }
        ]
      end

      it "sanitizes and strip qti v2p1 html nodes" do
        manifest_node = get_manifest_node("matching")
        hash = Qti::AssessmentItemConverter.create_instructure_question(manifest_node:, base_dir: html_sanitization_question_dir("nodes"))
        hash[:answers].each { |a| a.replace(html: a[:html], text: a[:text]) }
        expect(hash[:answers]).to eq [
          { html: nil, text: "left 1" },
          { html: "<i>left 2</i>", text: "left 2" },
          { html: nil, text: "left 3" },
          { html: nil, text: "left 4" }
        ]
        expect(hash[:matches].pluck(:text)).to eq ["right 1", "rïght 2", "right 3", "right 4"]
      end
    end
  end
end
