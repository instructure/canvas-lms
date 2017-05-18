#
# Copyright (C) 2015 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Lti::ContentItemResponse do

  let_once(:context) { course_factory(active_all: true) }
  let_once(:teacher) { course_with_teacher(course: context, active_all: true).user }
  let_once(:assign1) { context.assignments.create!(name: "A1") }
  let_once(:assign2) { context.assignments.create!(name: "A2") }
  let(:controller) do
    controller_mock = mock('controller')
    controller_mock.stubs(:api_v1_course_content_exports_url).returns('api_export_url')
    controller_mock.stubs(:file_download_url).returns('file_download_url')
    controller_mock
  end

  def subject(media_types)
    described_class.new(context, controller, teacher, media_types, 'common_cartridge')
  end

  describe '#initialize' do
    it 'raises an error if an invalid id is passed in' do
      expect { subject({ assignments: [0] }) }.to(
        raise_error(Lti::Errors::InvalidMediaTypeError )
      )
    end

    it 'raises an error if on an invalid export type' do
      expect {
        described_class.new(
          context,
          controller,
          teacher,
          { "assignments" => [assign1.id] },
          'blah'
        )
      }.to raise_error(Lti::Errors::UnsupportedExportTypeError)
    end
  end

  describe '#query_params' do
    it 'return correct query params' do
      content_item_response = subject({assignments: [assign1.id, assign2.id]})
      expect(content_item_response.query_params).to eq({"export_type" => "common_cartridge", "select" => {"assignments" => [assign1.id, assign2.id]}})
    end

    it 'does not return the select object if there are no media types' do
      content_item_response = subject({})
      expect(content_item_response.query_params.keys).not_to include 'select'
    end
  end

  describe '#media_type' do
    it 'uses the canvas_media_type when it is not a module item' do
      content_item_response = subject({assignments: [assign1.id, assign2.id]})
      expect(content_item_response.media_type).to eq 'assignment'
    end

    it 'returns canvas if more than one canvas media is passed in' do
      topic = context.discussion_topics.create!(:title => "blah")
      content_item_response = subject({assignments: [assign1.id, assign2.id], discussion_topics: [topic.id]})
      expect(content_item_response.media_type).to eq 'course'
    end

    context 'module_item' do
      it 'sets the media_type to "assignment"' do
        context_module = context.context_modules.create!(name: 'a module')
        assignment = context.assignments.create!(name: 'an assignment')
        tag = context_module.add_item(:id => assignment.id, :type => 'assignment')
        content_item_response = subject({module_items: [tag.id]})
        expect(content_item_response.media_type).to eq 'assignment'
      end
      it 'sets the media_type to "quiz"' do
        context_module = context.context_modules.create!(name: 'a module')
        quiz = context.quizzes.create!(title: 'a quiz')
        tag = context_module.add_item(:id => quiz.id, :type => 'quiz')
        content_item_response = subject({module_items: [tag.id]})
        expect(content_item_response.media_type).to eq 'quiz'
      end
      it 'sets the media_type to "page"' do
        context_module = context.context_modules.create!(name: 'a module')
        page = context.wiki.wiki_pages.create!(title: 'a page')
        tag = context_module.add_item(:id => page.id, :type => 'page')
        content_item_response = subject({module_items: [tag.id]})
        expect(content_item_response.media_type).to eq 'page'
      end
      it 'sets the media_type to "discussion_topic"' do
        context_module = context.context_modules.create!(name: 'a module')
        topic = context.discussion_topics.create!(:title => "blah")
        tag = context_module.add_item(:id => topic.id, :type => 'discussion_topic')
        content_item_response = subject({module_items: [tag.id]})
        expect(content_item_response.media_type).to eq 'discussion_topic'
      end
    end
  end

  describe '#tag' do
    it 'returns back a tag' do
      context_module = context.context_modules.create!(name: 'a module')
      assignment = context.assignments.create!(name: 'an assignment')
      tag = context_module.add_item(:id => assignment.id, :type => 'assignment')
      content_item_response = subject({module_items: [tag.id]})
      expect(content_item_response.tag).to eq tag
    end
  end

  describe '#file' do
    it 'returns a file' do
      file = attachment_model(context: context)
      content_item_response = subject({files: [file.id]})
      expect(content_item_response.file).to eq file
    end
  end

  describe '#title' do
    it 'gets the title for a file' do
      file = attachment_model(context: context)
      content_item_response = subject({files: [file.id]})
      expect(content_item_response.title).to eq 'unknown.loser'
    end

    it 'gets the title for a assignment' do
      assignment = context.assignments.create!(name: 'an assignment')
      content_item_response = subject({assignments: [assignment.id]})
      expect(content_item_response.title).to eq 'an assignment'
    end

    it 'gets the title for a discussion_topic' do
      topic = context.discussion_topics.create!(:title => "blah")
      content_item_response = subject({discussion_topics: [topic.id]})
      expect(content_item_response.title).to eq 'blah'
    end

    it 'gets the title for a module' do
      context_module = context.context_modules.create!(name: 'a module')
      content_item_response = subject({modules: [context_module.id]})
      expect(content_item_response.title).to eq 'a module'
    end

    it 'gets the title for a page' do
      page = context.wiki.wiki_pages.create!(title: 'a page')
      content_item_response = subject({pages: [page.id]})
      expect(content_item_response.title).to eq 'a page'
    end

    it 'gets the title for a module_item' do
      context_module = context.context_modules.create!(name: 'a module')
      topic = context.discussion_topics.create!(:title => "blah")
      tag = context_module.add_item(:id => topic.id, :type => 'discussion_topic')
      content_item_response = subject({module_items: [tag.id]})
      expect(content_item_response.title).to eq 'blah'
    end

    it 'gets the title for a quiz' do
      quiz = context.quizzes.create!(title: 'a quiz')
      content_item_response = subject({quizzes: [quiz.id]})
      expect(content_item_response.title).to eq 'a quiz'
    end

    it 'gets the title for a course' do
      context_module = context.context_modules.create!(name: 'a module')
      quiz = context.quizzes.create!(title: 'a quiz')
      content_item_response = subject({modules: [context_module.id], quizzes: [quiz.id]})
      expect(content_item_response.title).to eq 'Unnamed Course'
    end

  end

  describe '#content_type' do
    it 'gets the files content_type' do
      file = attachment_model(context: context)
      content_item_response = subject({files: [file.id]})
      expect(content_item_response.content_type).to eq 'application/loser'
    end

    it 'gets the content_type for non files' do
      quiz = context.quizzes.create!(title: 'a quiz')
      content_item_response = subject({quizzes: [quiz.id]})
      expect(content_item_response.content_type).to eq 'application/vnd.instructure.api.content-exports.quiz'
    end
  end

  describe '#url' do
    it 'gets the id for a file' do
      file = attachment_model(context: context)
      content_item_response = subject({files: [file.id]})
      expect(content_item_response.url).to eq 'file_download_url'
    end

    it 'gets the id for non files' do
      quiz = context.quizzes.create!(title: 'a quiz')
      content_item_response = subject({quizzes: [quiz.id]})
      expect(content_item_response.url).to include 'api_export_url'
    end
  end

  describe '#as_json' do
    it 'generates the json for ContentItemSelectionResponse' do
      quiz = context.quizzes.create!(title: 'a quiz')
      content_item_response = subject({quizzes: [quiz.id]})
      json = content_item_response.as_json(lti_message_type: 'ContentItemSelectionResponse')
      expect(json['@context']).to eq "http://purl.imsglobal.org/ctx/lti/v1/ContentItemPlacement"
      expect(json['@graph'].first['@type']).to eq "ContentItemPlacement"
      expect(json['@graph'].first['placementOf']['@type']).to eq "FileItem"
      expect(json['@graph'].first['placementOf']['@id']).to include "api_export_url"
      expect(json['@graph'].first['placementOf']['mediaType']).to eq "application/vnd.instructure.api.content-exports.quiz"
      expect(json['@graph'].first['placementOf']['title']).to eq "a quiz"
    end

    it 'generates the json for ContentItemSelection' do
      quiz = context.quizzes.create!(title: 'a quiz')
      content_item_response = subject({quizzes: [quiz.id]})
      json = content_item_response.as_json(lti_message_type: 'ContentItemSelection')
      expect(json['@context']).to eq "http://purl.imsglobal.org/ctx/lti/v1/ContentItem"
      expect(json['@graph'].first['@type']).to eq "FileItem"
      expect(json['@graph'].first['url']).to include "api_export_url"
      expect(json['@graph'].first['mediaType']).to eq "application/vnd.instructure.api.content-exports.quiz"
      expect(json['@graph'].first['title']).to eq "a quiz"
      expect(json['@graph'].first['copyAdvice']).to eq true
    end

  end

end
