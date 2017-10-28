#
# Copyright (C) 2016 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/../lti2_spec_helper')

describe OriginalityReport do

  let(:attachment) { attachment_model }
  let(:course) { course_model }
  let(:submission) { submission_model }

  subject {OriginalityReport.create!(attachment: attachment, originality_score: '1', submission: submission, workflow_state: 'pending')}

  it 'can have attachments associated with it' do
    expect(subject.attachment).to eq attachment
  end

  it 'does not require an originality score' do
    subject.originality_score = nil
    subject.valid?
    expect(subject.errors[:originality_score]).to be_blank
  end

  it 'does not allow scores higher than 100' do
    subject.originality_score = 101
    subject.valid?
    expect(subject.errors[:originality_score]).to eq ['score must be between 0 and 100']
  end

  it 'does not allow scores lower than 0' do
    subject.originality_score = -1
    subject.valid?
    expect(subject.errors[:originality_score]).to eq ['score must be between 0 and 100']
  end

  it 'requires an attachment' do
    subject.attachment = nil
    subject.valid?
    expect(subject.errors[:attachment]).to eq ["can't be blank"]
  end

  it 'is invalid if the attachment is already taken' do
    subject
    duplicate = OriginalityReport.create(attachment: attachment, submission: submission_model)
    expect(duplicate).to be_invalid
  end

  it 'requires a valid workflow_state' do
    subject.workflow_state = 'invalid_state'
    subject.valid?
    expect(subject.errors).not_to include :workflow_state
  end

  it 'allows the "pending" workflow state' do
    subject.update_attributes(originality_score: nil)
    expect(subject.workflow_state).to eq 'pending'
  end

  it 'allows the "scored" workflow state' do
    subject.workflow_state = 'scored'
    subject.save!
    expect(subject.workflow_state).to eq 'scored'
  end

  it 'allows the "error" workflow state' do
    subject.workflow_state = 'error'
    subject.save!
    expect(subject.workflow_state).to eq 'error'
  end

  it 'can have a submission' do
    subject.submission = nil
    subject.valid?
    expect(subject.errors[:submission]).to eq ["can't be blank"]
  end

  it 'can have an originality report attachment' do
    originality_attachemnt = attachment_model
    subject.originality_report_attachment = originality_attachemnt
    subject.save!
    expect(subject.originality_report_attachment).to eq originality_attachemnt
  end

  it 'returns the state of the originality report' do
    expect(subject.state).to eq 'acceptable'
  end

  describe 'accepts nested attributes for lti link' do
    let(:lti_link_attributes) do
      {
        product_code: 'product',
        vendor_code: 'vendor',
        resource_type_code: 'resource'
      }
    end

    it 'creates an lti link' do
      report = OriginalityReport.create!(
        attachment: attachment,
        originality_score: '1',
        submission: submission,
        workflow_state: 'pending',
        lti_link_attributes: lti_link_attributes
      )
      expect(report.lti_link.product_code).to eq 'product'
    end

    it 'updates an lti link' do
      report = OriginalityReport.create!(
        attachment: attachment,
        originality_score: '1',
        submission: submission,
        workflow_state: 'pending',
        lti_link_attributes: lti_link_attributes
      )
      report.update_attributes(lti_link_attributes: { id: report.lti_link.id, resource_url: 'http://example.com' })
      expect(report.lti_link.resource_url).to eq 'http://example.com'
    end

    it 'destroys an lti link' do
      report = OriginalityReport.create!(
        attachment: attachment,
        originality_score: '1',
        submission: submission,
        workflow_state: 'pending',
        lti_link_attributes: lti_link_attributes
      )
      link_id = report.lti_link.id
      report.update_attributes!(lti_link_attributes: { id: link_id, _destroy: true })
      expect(Lti::Link.find_by(id: link_id)).to be_nil
    end
  end

  describe 'workflow_state transitions' do
    let(:report_no_score){ OriginalityReport.new(attachment: attachment, submission: submission) }
    let(:report_with_score){ OriginalityReport.new(attachment: attachment, submission: submission, originality_score: 23.2) }

    it "updates state to 'scored' if originality_score is set on existing record" do
      report_no_score.update_attributes(originality_score: 23.0)
      expect(report_no_score.workflow_state).to eq 'scored'
    end

    it "updates state to 'scored' if originality_score is set on a new record" do
      report_with_score.save
      expect(report_with_score.workflow_state).to eq 'scored'
    end

    it "updates state to 'pending' if originality_score is set to nil on existing record" do
      report_with_score.save
      report_with_score.update_attributes(originality_score: nil)
      expect(report_with_score.workflow_state).to eq 'pending'
    end

    it "updates state to 'pending' if originality_score is not set on new record" do
      report_no_score.save
      expect(report_no_score.workflow_state).to eq 'pending'
    end

    it "does not change workflow_state if it is set to 'error'" do
      report_with_score.save
      report_with_score.update_attributes(workflow_state: 'error')
      report_with_score.update_attributes(originality_score: 23.2)
      expect(report_with_score.workflow_state).to eq 'error'
    end
  end

  describe '#report_launch_url' do
    include_context 'lti2_spec_helper'
    let(:lti_link) do
      Lti::Link.new(resource_link_id: SecureRandom.uuid,
                    vendor_code: product_family.vendor_code,
                    product_code: product_family.product_code,
                    resource_type_code: resource_handler.resource_type_code,
                    linkable: report)
    end
    let(:report) { subject }

    it 'creates an LTI launch URL if a lti_link is present' do
      report.update_attributes(lti_link: lti_link)
      expected_url = "http://localhost/courses/"\
                     "#{submission.assignment.course.id}/assignments/"\
                     "#{submission.assignment.id}/lti/resource/#{lti_link.resource_link_id}?display=borderless"
      expect(report.report_launch_url).to eq expected_url
    end

    it 'uses the originality_report_url when the link id is present' do
      non_lti_url = 'http://www.test.com/report'
      report.update_attributes(originality_report_url: non_lti_url)
      expect(report.report_launch_url).to eq non_lti_url
    end
  end

  describe '#state' do
    let(:report) { OriginalityReport.new(workflow_state: 'pending') }

    it "returns the workflow state unless it is 'scored'" do
      expect(report.state).to eq 'pending'
    end

    it "returns the state from similarity score if workflow state is 'scored'" do
      report.update_attributes(originality_score: '25')
      expect(report.state).to eq 'warning'
    end
  end
end
