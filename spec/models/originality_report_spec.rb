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

  it 'requies a valid workflow_state' do
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
end
