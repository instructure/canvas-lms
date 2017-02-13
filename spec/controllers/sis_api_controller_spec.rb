require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SisApiController do
  describe "GET sis_assignments" do
    let(:account) {account_model}
    let(:course) {course_model(account: account, workflow_state: 'available')}
    let(:admin) {account_admin_user(account: account)}

    before do
      bypass_rescue
      user_session(admin)
    end

    it 'responds with 400 when sis_assignments is disabled' do
      get 'sis_assignments', course_id: course.id

      parsed_json = json_parse(response.body)
      expect(response.code).to eq "400"
      expect(parsed_json['code']).to  eq 'not_enabled'
    end

    context 'with bulk_sis_grade_export enabled' do
      before do
        account.enable_feature!(:bulk_sis_grade_export)
      end

      it 'responds with 200' do
        get 'sis_assignments', course_id: course.id

        parsed_json = json_parse(response.body)
        expect(response.code).to eq "200"
        expect(parsed_json).to eq []
      end

      it 'includes only assignments with post_to_sis enabled' do
        assignment_model(course: course, workflow_state: 'published')
        assignment = assignment_model(course: course, post_to_sis: true, workflow_state: 'published')

        get 'sis_assignments', course_id: course.id

        parsed_json = json_parse(response.body)
        expect(parsed_json.size).to eq 1
        expect(parsed_json.first['id']).to eq assignment.id
      end

      context 'with student overrides' do
        let(:assignment) {assignment_model(course: course, post_to_sis: true, workflow_state: 'published')}

        before do
          @student1 = student_in_course({:course => course, :workflow_state => 'active'}).user
          @student2 = student_in_course({:course => course, :workflow_state => 'active'}).user
          managed_pseudonym(@student2, sis_user_id: 'SIS_ID_2')
          due_at = Time.zone.parse('2017-02-08 22:11:10')
          @override = create_adhoc_override_for_assignment(assignment, [@student1, @student2], due_at: due_at)
        end

        it 'does not include student overrides by default' do
          get 'sis_assignments', course_id: course.id

          parsed_json = json_parse(response.body)
          expect(parsed_json.first).not_to have_key('user_overrides')
        end

        it 'does includes student override data by including student_overrides' do
          get 'sis_assignments', course_id: course.id, include: ['student_overrides']

          parsed_json = json_parse(response.body)
          expect(parsed_json.first['user_overrides'].size).to eq 1
          expect(parsed_json.first['user_overrides'].first['id']).to eq @override.id

          students = parsed_json.first['user_overrides'].first['students']
          expect(students.size).to eq 2
          expect(students).to include({'user_id' => @student1.id, 'sis_user_id' => nil})
          expect(students).to include({'user_id' => @student2.id, 'sis_user_id' => 'SIS_ID_2'})
        end
      end
    end
  end
end

