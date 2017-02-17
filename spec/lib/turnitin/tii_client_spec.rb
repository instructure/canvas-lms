require File.expand_path(File.dirname(__FILE__) + '/turnitin_spec_helper')
require 'turnitin_api'
module Turnitin
  describe TiiClient do
    include_context "shared_tii_lti"
    subject{described_class.new(lti_student, lti_assignment, tool, {})}

    describe ".new" do

      it 'set the user_id to the opaque identifier' do
        expect(subject.lti_params['user_id']).to eq Lti::Asset.opaque_identifier_for(lti_student)
      end

      it 'set the context_id to the opaque identifier' do
        expect(subject.lti_params['context_id']).to eq Lti::Asset.opaque_identifier_for(lti_assignment.context)
      end

      it 'set the context_title to the context Title' do
        expect(subject.lti_params['context_title']).to eq lti_assignment.context.name
      end

      it 'set the lis_person_contact_email_primary to the users email' do
        expect(subject.lti_params['lis_person_contact_email_primary']).to eq lti_student.email
      end

    end



    describe ".turnitin_data" do
      let(:originality_data) do
        {
          "numeric" => {
            "score" => '1.2'
          },
          "breakdown" => {
            "internet_score" => '2.3',
            "publications_score" => '3.2',
            "submitted_works_score" => '4.2'
          }
        }
      end
      let(:originality_report_url) {"http://example.com/report"}

      before :each do
        subject.stubs(:originality_data).returns(originality_data)
        subject.stubs(:originality_report_url).returns(originality_report_url)
      end

      it "sets the similarity_score" do
        score = originality_data['numeric']['score'].to_f
        expect(subject.turnitin_data[:similarity_score]).to eq score
      end

      it "sets the web_overlap" do
        internet_score = originality_data["breakdown"]["internet_score"].to_f
        expect(subject.turnitin_data[:web_overlap]).to eq internet_score
      end

      it "sets the publication_overlap" do
        publications_score = originality_data["breakdown"]["publications_score"].to_f
        expect(subject.turnitin_data[:publication_overlap]).to eq publications_score
      end

      it "sets the student_overlap" do
        submitted_works_score = originality_data["breakdown"]["submitted_works_score"].to_f
        expect(subject.turnitin_data[:student_overlap]).to eq submitted_works_score
      end

      it "sets the state" do
        state = Turnitin.state_from_similarity_score(originality_data["numeric"]["score"].to_f)
        expect(subject.turnitin_data[:state]).to eq  state
      end

      it "sets the status to scored" do
        expect(subject.turnitin_data[:status]).to eq 'scored'
      end

    end

  end
end
