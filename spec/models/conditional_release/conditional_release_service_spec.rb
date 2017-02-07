#
# Copyright (C) 2016 Instructure, Inc.
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
require File.expand_path(File.dirname(__FILE__) + '/../../sharding_spec_helper')

describe ConditionalRelease::Service do
  Service = ConditionalRelease::Service

  def stub_config(*configs)
    ConfigFile.stubs(:load).returns(*configs)
  end

  def clear_config
    Service.reset_config_cache
  end

  def enable_service
    Canvas::Security::ServicesJwt.stubs(:encryption_secret).returns('secret' * 10)
    Canvas::Security::ServicesJwt.stubs(:signing_secret).returns('donttell' * 10)
    Service.stubs(:enabled_in_context?).returns(true)
  end

  before(:each) do
    clear_config
  end

  context 'configuration' do
    it 'is not configured by default' do
      stub_config(nil)
      expect(Service.configured?).to eq false
    end

    it 'requires host to be configured' do
      stub_config({enabled: true})
      expect(Service.configured?).to eq false
    end

    it 'is configured when enabled with host' do
      stub_config({enabled: true, host: 'foo'})
      expect(Service.configured?).to eq true
    end

    it 'has a default config' do
      stub_config(nil)
      config = Service.config
      expect(config).not_to be_nil
      expect(config.size).to be > 0
    end

    it 'defaults protocol to canvas protocol' do
      HostUrl.stubs(:protocol).returns('foo')
      stub_config(nil)
      expect(Service.protocol).to eq('foo')
    end

    it 'overrides defaults with config file' do
      stub_config(nil, {protocol: 'foo'})
      expect(Service.config[:protocol]).not_to eql('foo')
      clear_config
      expect(Service.config[:protocol]).to eql('foo')
    end

    it 'creates urls' do
      stub_config({
        protocol: 'foo', host: 'bar',
        create_account_path: 'some/path',
        editor_path: 'some/other/path'
      })
      expect(Service.create_account_url).to eq 'foo://bar/some/path'
      expect(Service.editor_url).to eq 'foo://bar/some/other/path'
    end

    it 'requires feature flag to be enabled' do
      context = stub({feature_enabled?: true})
      stub_config({enabled: true, host: 'foo'})
      expect(Service.enabled_in_context?(context)).to eq true
    end

    it 'reports enabled as true when enabled' do
      context = stub({feature_enabled?: true})
      stub_config({enabled: true, host: 'foo'})
      env = Service.env_for(context)
      expect(env[:CONDITIONAL_RELEASE_SERVICE_ENABLED]).to eq true
    end

    it 'reports enabled as false if feature flag is off' do
      context = stub({feature_enabled?: false})
      stub_config({enabled: true, host: 'foo'})
      env = Service.env_for(context)
      expect(env[:CONDITIONAL_RELEASE_SERVICE_ENABLED]).to eq false
    end

    it 'reports enabled as false if service is disabled' do
      context = stub({feature_enabled?: true})
      stub_config({enabled: false})
      env = Service.env_for(context)
      expect(env[:CONDITIONAL_RELEASE_SERVICE_ENABLED]).to eq false
    end
  end

  describe 'env_for' do
    before do
      enable_service
      stub_config({
        protocol: 'foo', host: 'bar', rules_path: 'rules'
      })
      Service.stubs(:active_rules).returns([])
      course_with_student(active_all: true)
    end

    it 'returns no jwt or env if not enabled' do
      Service.stubs(:enabled_in_context?).returns(false)
      env = Service.env_for(@course, @student, domain: 'foo.bar')
      expect(env).not_to have_key :CONDITIONAL_RELEASE_ENV
    end

    it 'returns no jwt or env if user not specified' do
      env = Service.env_for(@course)
      expect(env).not_to have_key :CONDITIONAL_RELEASE_ENV
    end

    it 'returns an env with jwt if everything enabled' do
      Service.stubs(:jwt_for).returns(:jwt)
      env = Service.env_for(@course, @student, domain: 'foo.bar')
      expect(env[:CONDITIONAL_RELEASE_ENV][:jwt]).to eq :jwt
    end

    it 'returns an env with current locale' do
      I18n.stubs(:locale).returns('en-PI')
      env = Service.env_for(@course, @student, domain: 'foo.bar')
      expect(env[:CONDITIONAL_RELEASE_ENV][:locale]).to eq 'en-PI'
    end

    it 'includes assignment data when an assignment is specified' do
      assignment_model course: @course
      env = Service.env_for(@course, @student, domain: 'foo.bar', assignment: @assignment)
      cr_env = env[:CONDITIONAL_RELEASE_ENV]
      expect(cr_env[:assignment][:id]).to eq @assignment.id
      expect(cr_env[:assignment][:title]).to eq @assignment.title
      expect(cr_env[:assignment][:points_possible]).to eq @assignment.points_possible
      expect(cr_env[:assignment][:grading_type]).to eq @assignment.grading_type
      expect(cr_env[:assignment][:submission_types]).to eq @assignment.submission_types
    end

    it 'includes a grading scheme when assignment uses it' do
      assignment_model course: @course, grading_type: 'letter_grade'
      env = Service.env_for(@course, @student, domain: 'foo.bar', assignment: @assignment)
      cr_env = env[:CONDITIONAL_RELEASE_ENV]
      expect(cr_env[:assignment][:grading_scheme]).not_to be_nil
    end

    it 'does not include a grading scheme when the assignment does not use it' do
      assignment_model course: @course, grading_type: 'points'
      env = Service.env_for(@course, @student, domain: 'foo.bar', assignment: @assignment)
      cr_env = env[:CONDITIONAL_RELEASE_ENV]
      expect(cr_env[:assignment][:grading_scheme]).to be_nil
    end

    it 'includes a relevant rule if includes :rule' do
      assignment_model course: @course
      Service.stubs(:rule_triggered_by).returns(nil)
      env = Service.env_for(@course, @student, domain: 'foo.bar', assignment: @assignment, includes: [:rule])
      cr_env = env[:CONDITIONAL_RELEASE_ENV]
      expect(cr_env).to have_key :rule
    end

    it 'includes a active rules if includes :active_rules' do
      assignment_model course: @course
      Service.stubs(:rule_triggered_by).returns(nil)
      env = Service.env_for(@course, @student, domain: 'foo.bar', assignment: @assignment, includes: [:active_rules])
      cr_env = env[:CONDITIONAL_RELEASE_ENV]
      expect(cr_env).to have_key :active_rules
    end
  end

  describe 'jwt_for' do
    before do
      enable_service
    end

    def get_claims(jwt)
      Canvas::Security::ServicesJwt.new(jwt, false).original_token
    end

    it 'returns a student jwt for a student viewing a course' do
      course_with_student(active_all: true)
      jwt = Service.jwt_for(@course, @student, 'foo.bar')
      claims = get_claims jwt
      expect(claims[:sub]).to eq @student.id.to_s
      expect(claims[:role]).to eq 'student'
      expect(claims[:context_id]).to eq @course.id.to_s
      expect(claims[:context_type]).to eq 'Course'
      expect(claims[:account_id]).to eq Account.default.lti_guid.to_s
      expect(claims[:domain]).to eq 'foo.bar'
    end

    it 'returns a teacher jwt for a teacher viewing a course' do
      course_with_teacher(active_all: true)
      jwt = Service.jwt_for(@course, @user, 'foo.bar')
      claims = get_claims jwt
      expect(claims[:sub]).to eq @user.id.to_s
      expect(claims[:role]).to eq 'teacher'
    end

    it 'returns an admin jwt for an admin viewing a course' do
      course_factory
      account_admin_user
      jwt = Service.jwt_for(@course, @admin, 'foo.bar')
      claims = get_claims jwt
      expect(claims[:sub]).to eq @admin.id.to_s
      expect(claims[:role]).to eq 'admin'
    end

    it 'returns a no-role jwt for a non-associated user viewing a course' do
      teacher_in_course
      course_factory # redefines @course
      jwt = Service.jwt_for(@course, @user, 'foo.bar')
      claims = get_claims jwt
      expect(claims[:sub]).to eq @user.id.to_s
      expect(claims[:role]).to be_nil
    end

    it 'returns an admin jwt for an admin viewing an account' do
      account_admin_user
      jwt = Service.jwt_for(Account.default, @admin, 'foo.bar')
      claims = get_claims jwt
      expect(claims[:sub]).to eq @admin.id.to_s
      expect(claims[:context_id]).to eq Account.default.id.to_s
      expect(claims[:context_type]).to eq 'Account'
      expect(claims[:role]).to eq 'admin'
    end

    it 'returns a no-role jwt for an admin viewing a different account' do
      account_admin_user
      account_model # redefines @account
      jwt = Service.jwt_for(@account, @admin, 'foo.bar')
      claims = get_claims jwt
      expect(claims[:role]).to be_nil
    end

    it 'succeeds when a session is specified' do
      course_with_student(active_all: true)
      session = { permissions_key: 'foobar' }
      jwt = Service.jwt_for(@course, @student, 'foo.bar', session: session)
      claims = get_claims jwt
      expect(claims[:role]).to eq 'student'
    end

    it 'includes a canvas auth jwt' do
      course_with_student(active_all: true)
      jwt = Service.jwt_for(@course, @student, 'foo.bar')
      claims = get_claims jwt
      expect(claims[:canvas_token]).not_to be nil
      canvas_claims = get_claims claims[:canvas_token]
      expect(canvas_claims[:workflows]).to eq ['conditional-release']
      expect(canvas_claims[:sub]).to eq @student.global_id
      expect(canvas_claims[:domain]).to eq 'foo.bar'
    end
  end

  describe 'select_mastery_path' do
    before do
      enable_service
    end

    before(:once) do
      course_with_student(active_all: true)
    end

    it 'make http request to service' do
      CanvasHttp.expects(:post)
                .with(Service.select_assignment_set_url, anything, anything)
                .returns(stub(code: '200', body: { key: 'value' }.to_json))
      result = Service.select_mastery_path(@course, @student, @student, 100, 200, nil)
      expect(result).to eq({ code: '200', body: { 'key' => 'value' } })
    end

    it 'clears rules cache' do
      CanvasHttp.stubs(:post)
                .returns(stub(code: '200', body: { key: 'value' }.to_json))
      Service.expects(:clear_rules_cache_for).with(@course, @student)
      Service.select_mastery_path(@course, @student, @student, 100, 200, nil)
    end
  end

  describe 'active_rules' do
    before do
      enable_service
    end

    it 'caches a successful http response' do
      enable_cache do
        course_with_teacher
        CanvasHttp.expects(:get).once.returns(stub({ code: '200', body: [].to_json }))
        Canvas::Errors.expects(:capture).never
        Service.active_rules @course, @user, nil
        rules = Service.active_rules @course, @user, nil
        expect(rules).to eq []
      end
    end

    it 'does not cache an error http response' do
      course_with_teacher
      enable_cache do
        CanvasHttp.expects(:get).twice.returns(stub({ code: '500' }))
        Canvas::Errors.expects(:capture).twice.with(instance_of(ConditionalRelease::ServiceError), anything)
        Service.active_rules @course, @user, nil
        Service.active_rules @course, @user, nil
      end
    end
  end

  context 'with active_rules' do
    before(:each) do
      Service.stubs(:enabled_in_context?).returns(true)
      Service.stubs(:jwt_for).returns(:jwt)
    end

    before(:once) do
      course_with_teacher
      @a1 = assignment_model course: @course, grading_type: 'points', points_possible: 20
      @a2 = assignment_model course: @course, grading_type: 'letter_grade', points_possible: 30
      @a3 = assignment_model course: @course, grading_type: 'percent', points_possible: 25
      @a4 = assignment_model course: @course, grading_type: 'points', points_possible: 35
    end

    let_once(:default_rules) do
      [
        {id: 1, trigger_assignment: @a1.id.to_s, scoring_ranges: [{ assignment_sets: [
          { assignments: [
            { assignment_id: @a2.id.to_s },
            { assignment_id: @a3.id.to_s }]}]}]},
        {id: 2, trigger_assignment: @a2.id.to_s, scoring_ranges: [{ assignment_sets: [
          { assignments: [
            { assignment_id: @a3.id.to_s }]}]}]},
        {id: 3, trigger_assignment: @a3.id.to_s}
      ].as_json
    end

    context 'assignment data' do
      before(:each) do
        Service.stubs(:enabled_in_context?).returns(true)
        CanvasHttp.expects(:get).once.returns stub({ code: '200', body: default_rules.to_json })
      end

      let(:rules) do
        Service.active_rules(@course, @teacher, @session)
      end

      it 'includes correct points' do
        expect(rules[0]['trigger_assignment_model'][:points_possible]).to be 20.0
        expect(rules[1]['trigger_assignment_model'][:points_possible]).to be 30.0
      end

      it 'includes correct grading type' do
        expect(rules[0]['trigger_assignment_model'][:grading_type]).to eq 'points'
        expect(rules[1]['trigger_assignment_model'][:grading_type]).to eq 'letter_grade'
      end

      it 'includes grading scheme only for correct grading type' do
        expect(rules[0]['trigger_assignment_model'][:grading_scheme]).to be nil
        expect(rules[1]['trigger_assignment_model'][:grading_scheme]).to eq({
          "A"=>0.94, "A-"=>0.9, "B+"=>0.87, "B"=>0.84, "B-"=>0.8, "C+"=>0.77,
          "C"=>0.74, "C-"=>0.7, "D+"=>0.67, "D"=>0.64, "D-"=>0.61, "F"=>0.0
        })
      end
    end

    describe 'rule_triggered_by' do
      def cache_active_rules(rules = default_rules)
        Rails.cache.write ['conditional_release', 'active_rules', @course.global_id].cache_key, rules
      end

      it 'caches the result of a successful http call' do
        enable_cache do
          CanvasHttp.expects(:get).once.returns stub({ code: '200', body: default_rules.to_json })
          Service.rule_triggered_by(@a1, @teacher, nil)
        end
      end

      context 'with cached rules' do
        it 'returns a matching rule' do
          enable_cache do
            cache_active_rules
            expect(Service.rule_triggered_by(@a1, @teacher, nil)['id']).to eq 1
            expect(Service.rule_triggered_by(@a3, @teacher, nil)['id']).to eq 3
          end
        end

        it 'returns nil if no rules are matching' do
          enable_cache do
            cache_active_rules
            expect(Service.rule_triggered_by(@a4, @teacher, nil)).to be nil
          end
        end
      end

      it 'returns nil without making request if no assignment is provided' do
        CanvasHttp.expects(:get).never
        Service.rule_triggered_by(nil, @teacher, nil)
      end

      it 'returns nil without making request if service is not enabled' do
        Service.stubs(:enabled_in_context?).returns(false)
        CanvasHttp.expects(:get).never
        Service.rule_triggered_by(@a1, @teacher, nil)
      end
    end

    describe 'rules_assigning' do
      before(:each) do
        Service.stubs(:active_rules).returns(default_rules)
      end

      it 'caches the calculation of the reverse index' do
        enable_cache do
          Service.rules_assigning(@a1, @teacher, nil)
          Service.stubs(:active_rules).raises 'should not refetch rules'
          Service.rules_assigning(@a2, @teacher, nil)
        end
      end

      it 'returns all rules which matched assignments' do
        expect(Service.rules_assigning(@a2, @teacher, nil).map{|r| r['id']}).to eq [1]
        expect(Service.rules_assigning(@a3, @teacher, nil).map{|r| r['id']}).to eq [1, 2]
      end

      it 'returns nil if no rules matched assignments' do
        expect(Service.rules_assigning(@a1, @teacher, nil)).to eq nil
        expect(Service.rules_assigning(@a4, @teacher, nil)).to eq nil
      end
    end
  end

  describe 'rules_for' do
    before do
      enable_service
    end

    before(:once) do
      course_with_student
      @a1, @a2, @a3 = 3.times.map { assignment_model course: @course }
    end

    def expect_cyoe_request(code, assignments = nil)
      a3 = @a3
      response = stub() do
        expects(:code).returns(code)
        unless assignments.nil?
          assignments = Array.wrap(assignments)
          assignments_json = assignments.map do |a|
            { id: a.id, assignment_id: a.id }
          end
          expects(:body).returns([
            { id: 1, trigger_assignment: 2, assignment_sets: [
              { id: 11, assignments: assignments_json },
              { id: 12, assignments: [{ id: a3.id, assignment_id: a3.id }]}
            ]}
          ].to_json)
        end
      end
      CanvasHttp.expects(:post).once.returns(response)
    end

    let(:rules) { Service.rules_for(@course, @student, [], nil) }
    let(:assignments0) { rules[0][:assignment_sets][0][:assignments] }
    let(:models0) { assignments0.map{|a| a[:model]} }

    it 'returns a list of rules' do
      expect_cyoe_request '200', @a1
      expect(rules.length > 0)
      expect(models0).to eq [@a1]
    end

    it 'filters missing assignments from an assignment set' do
      expect_cyoe_request '200', [@a1, @a2, @a3]
      @a1.destroy!
      expect(models0).to eq [@a2, @a3]
    end

    it 'filters assignment sets with no assignments' do
      expect_cyoe_request '200', [@a1, @a2]
      @a1.destroy!
      @a2.destroy!
      expect(rules[0][:assignment_sets].length).to eq 1
      expect(models0).to eq [@a3]
    end

    it 'does not filter rules with no follow on assignments' do
      expect_cyoe_request '200', [@a1, @a2]
      @a1.destroy!
      @a2.destroy!
      @a3.destroy!
      expect(rules.length).to eq 1
      expect(rules[0][:assignment_sets].length).to eq 0
    end

    it 'handles an http error with logging and defaults' do
      expect_cyoe_request '404'
      Canvas::Errors.expects(:capture).with(instance_of(ConditionalRelease::ServiceError), anything)
      expect(rules).to eq []
    end

    it 'handles a network exception with logging and defaults' do
      CanvasHttp.expects(:post).throws('something terrible')
      Canvas::Errors.expects(:capture).with(instance_of(ConditionalRelease::ServiceError), anything)
      expect(rules).to eq []
    end

    context 'caching' do
      it 'uses the cache' do
        enable_cache do
          expect_cyoe_request '200', @a1
          Service.rules_for(@course, @student, [], nil)
          Service.rules_for(@course, @student, [], nil)
        end
      end

      it 'does not use the cache if cache cleared manually' do
        enable_cache do
          expect_cyoe_request '200', @a1
          Service.rules_for(@course, @student, [], nil)

          Service.clear_rules_cache_for(@course, @student)

          expect_cyoe_request '200', @a1
          Service.rules_for(@course, @student, [], nil)
        end
      end

      it 'does not use the cache if assignments updated' do
        enable_cache do
          expect_cyoe_request '200', @a1
          Service.rules_for(@course, @student, [], nil)

          @a1.title = 'updated'
          @a1.save!

          expect_cyoe_request '200', @a1
          Service.rules_for(@course, @student, [], nil)
        end
      end

      it 'does not use the cache if assignments are saved' do
        enable_cache do
          expect_cyoe_request '200', @a1
          Service.rules_for(@course, @student, [], nil)

          @a1.save!

          expect_cyoe_request '200', @a1
          Service.rules_for(@course, @student, [], nil)
        end
      end

      it 'does not store an error response in the cache' do
        enable_cache do
          expect_cyoe_request '404'
          Service.rules_for(@course, @student, [], nil)

          expect_cyoe_request '404'
          Service.rules_for(@course, @student, [], nil)
        end
      end
    end

    context 'submissions' do
      def submissions_hash_for(submissions)
        all_the_submissions = Array.wrap(submissions).map do |submission|
          submission.slice(:id, :assignment_id, :score)
            .merge(points_possible: submission.assignment.points_possible)
            .symbolize_keys
        end

        { submissions: all_the_submissions }
      end

      context 'for cross-shard users' do
        specs_require_sharding

        it 'selects submissions' do
          course_with_student(active_all: true)
          @shard1.activate do
            course_with_student(account: Account.create!, user: @student)
            sub = submission_model(course: @course, user: @student)
            Service.expects(:request_rules)
              .with(anything(), submissions_hash_for(sub))
            Service.rules_for(@course, @student, [], nil)
          end
        end
      end

      it 'includes only submissions for the course' do
        course_with_student(active_all: true)
        submission_model(course: @course, user: @student)
        course_with_student(user: @student)
        sub = submission_model(course: @course, user: @student)
        Service.expects(:request_rules)
          .with(anything(), submissions_hash_for(sub))
        Service.rules_for(@course, @student, [], nil)
      end
    end
  end
end
