#
# Copyright (C) 2017 Instructure, Inc.
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

describe Lti::ContentItemSelectionRequest do
  subject(:lti_request) do
    described_class.new(context: course,
                        domain_root_account: root_account,
                        user: teacher,
                        host: test_host)
  end

  let(:test_host) { 'canvas.test' }
  let(:course) { course_model }
  let(:root_account) { course.root_account }
  let(:teacher) { course_with_teacher(course: course).user }
  let(:placement) {'resource_selection'}

  context '#generate_lti_launch' do
    it 'generates an Lti::Launch' do
      expect(lti_request.generate_lti_launch(placement)).to be_a Lti::Launch
    end

    it 'sends opts to the Lti::Launch' do
      opts = {
        post_only: true,
        tool_dimensions: {selection_height: '1000px', selection_width: '100%'}
      }

      expect(Lti::Launch).to receive(:new).with(opts).and_return(Lti::Launch.new(opts))

      lti_request.generate_lti_launch(placement, opts)
    end

    it 'generates resource_url based on a launch_url' do
      lti_launch = lti_request.generate_lti_launch(placement, launch_url: 'https://www.example.com')
      expect(lti_launch.resource_url).to eq 'https://www.example.com'
    end

    context 'params' do
      it 'builds a params hash that includes the default lti params' do
        lti_launch = lti_request.generate_lti_launch(placement)
        default_params = described_class.default_lti_params(course, root_account, teacher)
        expect(lti_launch.params).to include(default_params)
      end

      it "sets the 'accept_multiple' param to false" do
        lti_launch = lti_request.generate_lti_launch(placement)
        expect(lti_launch.params[:accept_multiple]).to eq false
      end

      it 'adds message type and version params' do
        lti_launch = lti_request.generate_lti_launch(placement)
        expect(lti_launch.params).to include({
          lti_message_type: 'ContentItemSelectionRequest',
          lti_version: 'LTI-1p0'
        })
      end

      context 'return_url' do
        it 'properly sets the return URL when no content item id is provided' do
          lti_launch = lti_request.generate_lti_launch(placement)
          expected_url = "http://#{test_host}/courses/#{course.id}/external_content/success/external_tool_dialog"
          expect(lti_launch.params[:content_item_return_url]).to eq expected_url
        end

        it 'properly sets the return URL when a content item id is provided' do
          item_id = 1
          lti_launch = lti_request.generate_lti_launch(placement, content_item_id: item_id)
          expected_url = "http://#{test_host}/courses/#{course.id}/external_content/success/external_tool_dialog/#{item_id}"

          expect(lti_launch.params[:content_item_return_url]).to eq expected_url
        end
      end

      context 'placement params' do
        it 'adds params for the migration_selection placement' do
          lti_launch = lti_request.generate_lti_launch('migration_selection')
          params = lti_launch.params
          expect(params[:accept_media_types]).to include(
            'application/vnd.ims.imsccv1p1',
            'application/vnd.ims.imsccv1p2',
            'application/vnd.ims.imsccv1p3',
            'application/zip,application/xml'
          )
          expect(params[:ext_content_file_extensions]).to include('zip','imscc','mbz','xml')
          expect(params).to include({
            accept_presentation_document_targets: 'download',
            accept_copy_advice: true
          })
        end

        it 'adds params for the editor_button placement' do
          lti_launch = lti_request.generate_lti_launch('editor_button')
          params = lti_launch.params
          expect(params[:accept_media_types]).to include(
            'image/*',
            'text/html',
            'application/vnd.ims.lti.v1.ltilink',
            '*/*'
          )
          expect(params[:accept_presentation_document_targets]).to include(
            'embed',
            'frame',
            'iframe',
            'window'
          )
        end

        it 'adds params for the resource_selection placement' do
          lti_launch = lti_request.generate_lti_launch('resource_selection')
          params = lti_launch.params
          expect(params[:accept_media_types]).to eq 'application/vnd.ims.lti.v1.ltilink'
          expect(params[:accept_presentation_document_targets]).to include(
            'frame',
            'window'
          )
        end

        it 'adds params for the link_selection placement'
        it 'adds params for the assignment_selection placement'

        it 'adds params for the collaboration placement' do
          lti_launch = lti_request.generate_lti_launch('collaboration')

          expect(lti_launch.params).to include({
            accept_media_types: 'application/vnd.ims.lti.v1.ltilink',
            accept_presentation_document_targets: 'window',
            accept_unsigned: false,
            auto_create: true,
          })
        end

        it 'substitutes collaboration variables in a collaboration launch'

        context 'homework_submission' do
          it 'adds params for an assignment that can accept an online_url submission' do
            assignment = assignment_model(course: course, submission_types: 'online_url')
            lti_launch = lti_request.generate_lti_launch('homework_submission', assignment: assignment)
            expect(lti_launch.params).to include({
              accept_media_types: '*/*',
              accept_presentation_document_targets: 'window',
              accept_copy_advice: false
            })
          end

          it 'adds params for an assignment that can accept an online_upload submission' do
            assignment = assignment_model(course: course, submission_types: 'online_upload')
            lti_launch = lti_request.generate_lti_launch('homework_submission', assignment: assignment)
            expect(lti_launch.params).to include({
              accept_media_types: '*/*',
              accept_presentation_document_targets: 'none',
              accept_copy_advice: true
            })
          end

          it 'adds params for extensions allowed by an assignment' do
            assignment = assignment_model(
              course: course,
              submission_types: 'online_upload',
              allowed_extensions: %w(txt jpg)
            )
            lti_launch = lti_request.generate_lti_launch('homework_submission', assignment: assignment)
            expect(lti_launch.params[:accept_media_types]).to include('text/plain', 'image/jpeg')
            expect(lti_launch.params[:ext_content_file_extensions]).to include('txt', 'jpg')
          end

          it 'adds params for assignments that accept either an online_upload or online_url' do
            assignment = assignment_model(course: course, submission_types: 'online_upload,online_url')
            lti_launch = lti_request.generate_lti_launch('homework_submission', assignment: assignment)

            expect(lti_launch.params[:accept_presentation_document_targets]).to include(
              'window',
              'none'
            )
            expect(lti_launch.params).to include({
              accept_media_types: '*/*',
              accept_copy_advice: true
            })
          end
        end
      end
    end
  end

  context '.default_lti_params' do
    before do
      allow(Lti::Asset).to receive(:opaque_identifier_for).with(course).and_return('course_opaque_id')
    end

    it 'generates default_lti_params' do
      root_account.lti_guid = 'account_guid'
      I18n.locale = :de

      params = described_class.default_lti_params(course, root_account)
      expect(params).to include({
        context_id: 'course_opaque_id',
        tool_consumer_instance_guid: 'account_guid',
        roles: 'urn:lti:sysrole:ims/lis/None',
        launch_presentation_locale: :de,
        launch_presentation_document_target: 'iframe',
        ext_roles: 'urn:lti:sysrole:ims/lis/None'
      })
    end

    it 'adds user information when a user is provided' do
      allow(Lti::Asset).to receive(:opaque_identifier_for).with(teacher).and_return('teacher_opaque_id')

      params = described_class.default_lti_params(course, root_account, teacher)

      expect(params).to include({
        roles: 'Instructor',
        user_id: 'teacher_opaque_id'
      })
      expect(params[:ext_roles]).to include('urn:lti:role:ims/lis/Instructor','urn:lti:sysrole:ims/lis/User')
    end
  end
end
