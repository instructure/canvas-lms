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
        edit_rule_path: 'some/other/path'
      })
      expect(Service.create_account_url).to eq 'foo://bar/some/path'
      expect(Service.edit_rule_url).to eq 'foo://bar/some/other/path'
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
      Service.stubs(:rules_for).returns([])
      course_with_student_logged_in(active_all: true)
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

    it 'includes a relevant rule if include_rule is true' do
      assignment_model course: @course
      Service.stubs(:rule_triggered_by).returns(nil)
      env = Service.env_for(@course, @student, domain: 'foo.bar', assignment: @assignment, include_rule: true)
      cr_env = env[:CONDITIONAL_RELEASE_ENV]
      expect(cr_env).to have_key :rule
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
      course_with_student_logged_in(active_all: true)
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
      course
      account_admin_user
      jwt = Service.jwt_for(@course, @admin, 'foo.bar')
      claims = get_claims jwt
      expect(claims[:sub]).to eq @admin.id.to_s
      expect(claims[:role]).to eq 'admin'
    end

    it 'returns a no-role jwt for a non-associated user viewing a course' do
      teacher_in_course
      course # redefines @course
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
      course_with_student_logged_in(active_all: true)
      session = { permissions_key: 'foobar' }
      jwt = Service.jwt_for(@course, @student, 'foo.bar', session: session)
      claims = get_claims jwt
      expect(claims[:role]).to eq 'student'
    end

    it 'includes a canvas auth jwt' do
      course_with_student_logged_in(active_all: true)
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
      course_with_student_logged_in(active_all: true)
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

  describe 'with active_rules' do
    before(:each) do
      Service.stubs(:enabled_in_context?).returns(true)
      Service.stubs(:jwt_for).returns(:jwt)
    end

    before(:once) do
      course_with_teacher
      @a, @b, @c, @d = 4.times.map { assignment_model course: @course }
    end

    let_once(:default_rules) do
      [
        {id: 1, trigger_assignment: @a.id.to_s, scoring_ranges: [{ assignment_sets: [
          { assignments: [
            { assignment_id: @b.id.to_s },
            { assignment_id: @c.id.to_s }]}]}]},
        {id: 2, trigger_assignment: @b.id.to_s, scoring_ranges: [{ assignment_sets: [
          { assignments: [
            { assignment_id: @c.id.to_s }]}]}]},
        {id: 3, trigger_assignment: @c.id.to_s}
      ].as_json
    end

    describe 'rule_triggered_by' do
      def cache_active_rules(rules = default_rules)
        Rails.cache.write ['conditional_release', 'active_rules', @course.global_id].cache_key, rules
      end

      it 'caches the response of any http call' do
        enable_cache do
          CanvasHttp.expects(:get).once.returns stub({ body: default_rules.to_json })
          Service.rule_triggered_by(@a, @teacher, nil)
        end
      end

      context 'with cached rules' do
        it 'returns a matching rule' do
          enable_cache do
            cache_active_rules
            expect(Service.rule_triggered_by(@a, @teacher, nil)['id']).to eq 1
            expect(Service.rule_triggered_by(@c, @teacher, nil)['id']).to eq 3
          end
        end

        it 'returns nil if no rules are matching' do
          enable_cache do
            cache_active_rules
            expect(Service.rule_triggered_by(@d, @teacher, nil)).to be nil
          end
        end
      end

      it 'returns nil without making request if no assignment is provided' do
        CanvasHttp.stubs(:get).raises 'should not generate request'
        Service.rule_triggered_by(nil, @teacher, nil)
      end

      it 'returns nil without making request if service is not enabled' do
        Service.stubs(:enabled_in_context?).returns(false)
        CanvasHttp.stubs(:get).raises 'should not generate request'
        Service.rule_triggered_by(@a, @teacher, nil)
      end
    end

    describe 'rules_assigning' do
      before(:each) do
        Service.stubs(:active_rules).returns(default_rules)
      end

      it 'caches the calculation of the reverse index' do
        enable_cache do
          Service.rules_assigning(@a, @teacher, nil)
          Service.stubs(:active_rules).raises 'should not refetch rules'
          Service.rules_assigning(@b, @teacher, nil)
        end
      end

      it 'returns all rules which matched assignments' do
        expect(Service.rules_assigning(@b, @teacher, nil).map{|r| r['id']}).to eq [1]
        expect(Service.rules_assigning(@c, @teacher, nil).map{|r| r['id']}).to eq [1, 2]
      end

      it 'returns nil if no rules matched assignments' do
        expect(Service.rules_assigning(@a, @teacher, nil)).to eq nil
        expect(Service.rules_assigning(@d, @teacher, nil)).to eq nil
      end
    end
  end

  describe 'rules_for' do
    before do
      enable_service
    end

    before(:once) do
      course_with_student_logged_in
      assignment_model course: @course
    end

    def expect_cyoe_request(code, assignments = nil)
      assignments = Array.wrap(assignments)
      response = stub() do
        expects(:code).returns(code)
        unless assignments.nil?
          assignments_json = assignments.map do |a|
            { id: a.id, assignment_id: a.id }
          end
          expects(:body).returns([
            { id: 1, trigger_assignment: 2, assignment_sets: [
              { id: 11, assignments: assignments_json }
            ]}
          ].to_json)
        end
      end
      CanvasHttp.expects(:post).once.returns(response)
    end

    it 'returns a list of rules' do
      expect_cyoe_request '200', @a
      rules = Service.rules_for(@course, @student, [], nil)
      expect(rules.length > 0)
      assignment = rules[0][:assignment_sets][0][:assignments][0]
      expect(assignment[:model]).to eq @a
    end

    it 'uses the cache' do
      enable_cache do
        expect_cyoe_request '200', @a
        Service.rules_for(@course, @student, [], nil)
        Service.rules_for(@course, @student, [], nil)
      end
    end

    it 'does not use the cache if cache cleared manually' do
      enable_cache do
        expect_cyoe_request '200', @a
        Service.rules_for(@course, @student, [], nil)

        Service.clear_rules_cache_for(@course, @student)

        expect_cyoe_request '200', @a
        Service.rules_for(@course, @student, [], nil)
      end
    end

    it 'does not use the cache if assignments updated' do
      enable_cache do
        expect_cyoe_request '200', @a
        Service.rules_for(@course, @student, [], nil)

        @a.title = 'updated'
        @a.save!

        expect_cyoe_request '200', @a
        Service.rules_for(@course, @student, [], nil)
      end
    end
  end
end
