# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

describe StudyAssist::Service do
  before :once do
    course_with_student(active_all: true)
    @course.enable_feature!(:study_assist)
  end

  let(:page) { @course.wiki_pages.create!(title: "Hello", body: "<p>Hello <b>world</b></p>") }
  let(:page_state) { { "pageID" => page.url } }

  def stub_cedar(response_text)
    CedarClient.prompt_results = [Struct.new(:response, :response_id).new(response_text, "r1")]
  end

  def call_service(prompt: "Summarize", state: page_state, regenerate: false)
    described_class.call(
      course: @course,
      user: @student,
      prompt:,
      state:,
      locale: "en",
      regenerate:
    )
  end

  before do
    Rails.cache.clear
    stub_const("CedarClient", Class.new do
      class << self
        attr_accessor :prompt_results
      end
      self.prompt_results = []

      def self.prompt(*)
        value = (prompt_results.size > 1) ? prompt_results.shift : prompt_results.first
        raise value if value.is_a?(Exception)

        value
      end

      def self.enabled?
        true
      end
    end)
    stub_cedar("A summary")
  end

  describe ".tool_key_for" do
    it "returns :chips for blank prompt" do
      expect(described_class.tool_key_for("")).to eq(:chips)
    end

    it "matches summarize variants" do
      expect(described_class.tool_key_for("Summarize")).to eq(:summarize)
      expect(described_class.tool_key_for("summarize this")).to eq(:summarize)
    end

    it "matches quiz chip and regenerate prompts" do
      expect(described_class.tool_key_for("Quiz me")).to eq(:quiz)
      expect(described_class.tool_key_for("Generate quiz")).to eq(:quiz)
    end

    it "matches flashcards chip and regenerate prompts" do
      expect(described_class.tool_key_for("Flashcards")).to eq(:flashcards)
      expect(described_class.tool_key_for("Flash cards")).to eq(:flashcards)
      expect(described_class.tool_key_for("Generate flashcards")).to eq(:flashcards)
    end

    it "returns :unknown for unmatched prompts" do
      expect(described_class.tool_key_for("hello there")).to eq(:unknown)
    end
  end

  describe "prompt dispatch" do
    it "returns chips when prompt is blank" do
      result = call_service(prompt: "", state: {})
      expect(result[:chips]).to be_an(Array)
    end

    it "raises InvalidPrompt for unsupported prompts" do
      expect { call_service(prompt: "hello there") }.to raise_error(StudyAssist::InvalidPrompt)
    end
  end

  describe "chips" do
    it "returns all chips when all per-tool flags are enabled" do
      result = call_service(prompt: "", state: {})
      expect(result[:chips].pluck(:chip)).to eq(["Summarize", "Quiz me", "Flashcards"])
    end

    it "omits a chip when its per-tool flag is disabled" do
      @course.disable_feature!(:study_assist_quiz_me)
      result = call_service(prompt: "", state: {})
      expect(result[:chips].pluck(:chip)).to eq(["Summarize", "Flashcards"])
    end

    it "returns an empty list when all tool flags are disabled" do
      @course.disable_feature!(:study_assist_summarize)
      @course.disable_feature!(:study_assist_quiz_me)
      @course.disable_feature!(:study_assist_flashcards)
      result = call_service(prompt: "", state: {})
      expect(result[:chips]).to eq([])
    end
  end

  describe "summarize" do
    it "returns the raw summary text" do
      expect(call_service(prompt: "Summarize")).to eq({ response: "A summary" })
    end

    it "sends the page prompt for page content" do
      expect(CedarClient).to receive(:prompt).with(hash_including(prompt: a_string_starting_with("Summarize this page."))).and_call_original
      call_service(prompt: "Summarize")
    end

    it "sends the file prompt for file content" do
      attachment = attachment_model(
        context: @course,
        content_type: "text/plain",
        uploaded_data: stub_file_data("notes.txt", "file material", "text/plain")
      )
      expect(CedarClient).to receive(:prompt).with(hash_including(prompt: a_string_starting_with("Summarize this file."))).and_call_original
      call_service(prompt: "Summarize", state: { "fileID" => attachment.id.to_s })
    end

    it "appends a no-preamble instruction to the prompt" do
      expect(CedarClient).to receive(:prompt).with(hash_including(prompt: a_string_including("Start directly"))).and_call_original
      call_service(prompt: "Summarize")
    end

    it "returns the response text verbatim (stripping only whitespace)" do
      stub_cedar("  The actual summary begins here.  ")
      expect(call_service(prompt: "Summarize")[:response]).to eq("The actual summary begins here.")
    end

    it "passes content as a Cedar txt document" do
      expect(CedarClient).to receive(:prompt).with(
        hash_including(document: hash_including(format: "txt"))
      ).and_call_original
      call_service(prompt: "Summarize")
    end

    it "raises ToolDisabled when the per-tool feature flag is off" do
      @course.disable_feature!(:study_assist_summarize)
      expect { call_service(prompt: "Summarize") }.to raise_error(StudyAssist::ToolDisabled)
    end

    it "raises ToolDisabled when the master study_assist flag is off" do
      @course.disable_feature!(:study_assist)
      expect { call_service(prompt: "Summarize") }.to raise_error(StudyAssist::ToolDisabled)
    end

    it "raises CedarUnavailable when Cedar returns a blank response" do
      stub_cedar("   ")
      expect { call_service(prompt: "Summarize") }.to raise_error(StudyAssist::CedarUnavailable)
    end

    it "raises RateLimited when Cedar signals rate limit" do
      CedarClient.prompt_results = [
        InstructureMiscPlugin::Extensions::CedarClient::CedarLimitReachedError.new("limit")
      ]
      expect { call_service(prompt: "Summarize") }.to raise_error(StudyAssist::RateLimited)
    end
  end

  describe "quiz" do
    let(:quiz_payload) { [{ question: "Q1", options: %w[a b c d], result: 2 }].to_json }

    before { stub_cedar(quiz_payload) }

    it "returns parsed quiz items mapping Journey shape to Canvas shape" do
      result = call_service(prompt: "Quiz me")
      expect(result[:quizItems].first).to include(
        question: "Q1",
        answers: %w[a b c d],
        correctAnswerIndex: 2
      )
    end

    it "raises ToolDisabled when the per-tool flag is off" do
      @course.disable_feature!(:study_assist_quiz_me)
      expect { call_service(prompt: "Quiz me") }.to raise_error(StudyAssist::ToolDisabled)
    end

    it "handles the 'Generate quiz' regenerate prompt" do
      result = call_service(prompt: "Generate quiz")
      expect(result[:quizItems]).to be_an(Array)
    end

    it "raises CedarUnavailable when a quiz item is malformed" do
      stub_cedar([{ question: "Q", options: [] }].to_json)
      expect { call_service(prompt: "Quiz me") }.to raise_error(StudyAssist::CedarUnavailable)
    end

    it "extracts the JSON array even when surrounded by prose" do
      wrapped = "Here you go: #{[{ question: "Q1", options: %w[a b c d], result: 0 }].to_json} hope that helps!"
      stub_cedar(wrapped)
      expect(call_service(prompt: "Quiz me")[:quizItems].first[:correctAnswerIndex]).to eq(0)
    end

    it "limits to 10 quiz items even if Cedar returns more" do
      many = Array.new(20) { |i| { question: "Q#{i}", options: %w[a b c d], result: 0 } }
      stub_cedar(many.to_json)
      expect(call_service(prompt: "Quiz me")[:quizItems].size).to eq(10)
    end
  end

  describe "flashcards" do
    let(:flashcards_payload) { [{ question: "Q", answer: "A" }].to_json }

    before { stub_cedar(flashcards_payload) }

    it "returns parsed flashcards" do
      expect(call_service(prompt: "Flashcards")[:flashCards]).to eq([{ question: "Q", answer: "A" }])
    end

    it "raises ToolDisabled when the per-tool flag is off" do
      @course.disable_feature!(:study_assist_flashcards)
      expect { call_service(prompt: "Flashcards") }.to raise_error(StudyAssist::ToolDisabled)
    end

    it "handles the 'Generate flashcards' regenerate prompt" do
      result = call_service(prompt: "Generate flashcards")
      expect(result[:flashCards]).to be_an(Array)
    end

    it "raises CedarUnavailable when flashcards payload is empty" do
      stub_cedar("[]")
      expect { call_service(prompt: "Flashcards") }.to raise_error(StudyAssist::CedarUnavailable)
    end

    it "limits to 10 flashcards even if Cedar returns more" do
      many = Array.new(30) { |i| { question: "Q#{i}", answer: "A#{i}" } }
      stub_cedar(many.to_json)
      expect(call_service(prompt: "Flashcards")[:flashCards].size).to eq(10)
    end
  end

  describe "content resolution" do
    it "strips HTML from page bodies" do
      # Bust any cached page summarization that might return "A summary"
      call_service(prompt: "Summarize") # baseline call to populate cache
      expect(CedarClient).to receive(:prompt).with(
        hash_including(document: hash_including(base64Source: Base64.strict_encode64("Hello world")))
      ).and_call_original
      Rails.cache.clear
      call_service(prompt: "Summarize")
    end

    it "raises ContentUnavailable when the page is missing" do
      expect do
        call_service(prompt: "Summarize", state: { "pageID" => "no-such-page" })
      end.to raise_error(StudyAssist::ContentUnavailable)
    end

    it "raises ContentUnavailable when no pageID or fileID is provided" do
      expect do
        call_service(prompt: "Summarize", state: {})
      end.to raise_error(StudyAssist::ContentUnavailable)
    end

    it "raises UnsupportedContentType for image attachments" do
      attachment = attachment_model(context: @course, content_type: "image/png", filename: "x.png")
      expect do
        call_service(prompt: "Summarize", state: { "fileID" => attachment.id.to_s })
      end.to raise_error(StudyAssist::UnsupportedContentType)
    end

    it "returns text for a plain text attachment" do
      attachment = attachment_model(
        context: @course,
        content_type: "text/plain",
        uploaded_data: stub_file_data("notes.txt", "lorem ipsum", "text/plain")
      )
      expect(CedarClient).to receive(:prompt).with(
        hash_including(document: hash_including(base64Source: Base64.strict_encode64("lorem ipsum")))
      ).and_call_original
      call_service(prompt: "Summarize", state: { "fileID" => attachment.id.to_s })
    end

    it "raises ContentTooLarge when content exceeds the cap" do
      huge_page = @course.wiki_pages.create!(title: "Huge", body: "x" * (described_class::MAX_CONTENT_CHARS + 1))
      expect do
        call_service(prompt: "Summarize", state: { "pageID" => huge_page.url })
      end.to raise_error(StudyAssist::ContentTooLarge)
    end

    it "rejects fileIDs belonging to a different course" do
      original_course = @course
      other_course = course_model(name: "Other Course")
      other_attachment = attachment_model(
        context: other_course,
        content_type: "text/plain",
        uploaded_data: stub_file_data("other.txt", "cross-course content", "text/plain")
      )
      @course = original_course
      expect do
        call_service(prompt: "Summarize", state: { "fileID" => other_attachment.id.to_s })
      end.to raise_error(StudyAssist::ContentUnavailable)
    end
  end

  describe "caching" do
    before { allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new) }

    it "caches a successful response and reuses it" do
      expect(CedarClient).to receive(:prompt).once.and_call_original
      2.times { call_service(prompt: "Summarize") }
    end

    it "bypasses cache when regenerate is true" do
      expect(CedarClient).to receive(:prompt).twice.and_call_original
      call_service(prompt: "Summarize")
      call_service(prompt: "Summarize", regenerate: true)
    end

    it "treats 'Generate quiz' as an implicit regenerate, busting the cache" do
      stub_cedar([{ question: "Q1", options: %w[a b c d], result: 0 }].to_json)
      expect(CedarClient).to receive(:prompt).twice.and_call_original
      call_service(prompt: "Quiz me")
      call_service(prompt: "Generate quiz")
    end

    it "treats 'Generate flashcards' as an implicit regenerate, busting the cache" do
      stub_cedar([{ question: "Q", answer: "A" }].to_json)
      expect(CedarClient).to receive(:prompt).twice.and_call_original
      call_service(prompt: "Flashcards")
      call_service(prompt: "Generate flashcards")
    end

    it "builds shard-safe cache keys referencing the page's global_id" do
      expect(Rails.cache).to receive(:fetch) do |key, **_opts, &blk|
        expect(key).to include(page.global_id.to_s)
        blk.call
      end.at_least(:once).and_call_original
      call_service(prompt: "Summarize")
    end

    it "does not cache a malformed Cedar response (cache-poisoning regression)" do
      stub_cedar("not a valid quiz array")
      expect(CedarClient).to receive(:prompt).twice.and_call_original
      expect { call_service(prompt: "Quiz me") }.to raise_error(StudyAssist::CedarUnavailable)
      expect { call_service(prompt: "Quiz me") }.to raise_error(StudyAssist::CedarUnavailable)
    end
  end
end
