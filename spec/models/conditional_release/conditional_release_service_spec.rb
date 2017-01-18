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

  before(:each) do
    clear_config
  end

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
      edit_rule_path: 'some/path'
    })
    expect(Service.edit_rule_url).to eq 'foo://bar/some/path'
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

  describe 'env_for' do
    before do
      Service.stubs(:enabled_in_context?).returns(true)
      Service.stubs(:jwt_for).returns(:jwt)
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
  end

  describe 'jwt_for' do
    before do
      Canvas::Security::ServicesJwt.stubs(:encryption_secret).returns('secret' * 10)
      Canvas::Security::ServicesJwt.stubs(:signing_secret).returns('donttell' * 10)
      Service.stubs(:enabled_in_context?).returns(true)
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
      expect(canvas_claims[:workflow]).to eq 'conditional-release'
      expect(canvas_claims[:sub]).to eq @student.global_id
      expect(canvas_claims[:domain]).to eq 'foo.bar'
    end
  end
end
