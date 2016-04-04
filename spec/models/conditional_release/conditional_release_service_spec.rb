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
      configure_defaults_app_path: 'some/path'
    })
    expect(Service.configure_defaults_url).to eq 'foo://bar/some/path'
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

  describe 'jwt generation' do
    before do
      Canvas::Security::ServicesJwt.stubs(:encryption_secret).returns('secret' * 10)
      Canvas::Security::ServicesJwt.stubs(:signing_secret).returns('donttell' * 10)
      Service.stubs(:enabled_in_context?).returns(true)
    end

    def get_claims(jwt)
      Canvas::Security::ServicesJwt.new(jwt, false).original_token
    end

    it 'returns no jwt if not enabled' do
      Service.stubs(:enabled_in_context?).returns(false)
      course_with_student_logged_in(active_all: true)
      env = Service.env_for(@course, @student)
      expect(env).not_to have_key :CONDITIONAL_RELEASE_JWT
    end
    
    it 'returns no jwt if user not specified' do
      course_model
      env = Service.env_for(@course)
      expect(env).not_to have_key :CONDITIONAL_RELEASE_JWT
    end

    it 'includes a student jwt for a student viewing a course' do
      course_with_student_logged_in(active_all: true)
      env = Service.env_for(@course, @student)
      claims = get_claims env[:CONDITIONAL_RELEASE_JWT]
      expect(claims[:sub]).to eq @student.id.to_s
      expect(claims[:role]).to eq 'student'
      expect(claims[:context_id]).to eq @course.id.to_s
      expect(claims[:context_type]).to eq 'Course'
      expect(claims[:account_id]).to eq Account.default.lti_guid.to_s
    end

    it 'returns a teacher jwt for a teacher viewing a course' do
      course_with_teacher(active_all: true)
      env = Service.env_for(@course, @user)
      claims = get_claims env[:CONDITIONAL_RELEASE_JWT]
      expect(claims[:sub]).to eq @user.id.to_s
      expect(claims[:role]).to eq 'teacher'
    end

    it 'returns an admin jwt for an admin viewing a course' do
      course
      account_admin_user
      env = Service.env_for(@course, @admin)
      claims = get_claims env[:CONDITIONAL_RELEASE_JWT]
      expect(claims[:sub]).to eq @admin.id.to_s
      expect(claims[:role]).to eq 'admin'
    end

    it 'returns a no-role jwt for a non-associated user viewing a course' do
      teacher_in_course
      course # redefines @course
      env = Service.env_for(@course, @user)
      claims = get_claims env[:CONDITIONAL_RELEASE_JWT]
      expect(claims[:sub]).to eq @user.id.to_s
      expect(claims[:role]).to be_nil
    end

    it 'returns an admin jwt for an admin viewing an account' do
      account_admin_user
      env = Service.env_for(Account.default, @admin)
      claims = get_claims env[:CONDITIONAL_RELEASE_JWT]
      expect(claims[:sub]).to eq @admin.id.to_s
      expect(claims[:context_id]).to eq Account.default.id.to_s
      expect(claims[:context_type]).to eq 'Account'
      expect(claims[:role]).to eq 'admin'
    end

    it 'returns a no-role jwt for an admin viewing a different account' do
      account_admin_user
      account_model # redefines @account
      env = Service.env_for(@account, @admin)
      claims = get_claims env[:CONDITIONAL_RELEASE_JWT]
      expect(claims[:role]).to be_nil
    end

    it 'succeeds when a session is specified' do
      course_with_student_logged_in(active_all: true)
      session = { permissions_key: 'foobar' }
      env = Service.env_for(@course, @student, session)
      claims = get_claims env[:CONDITIONAL_RELEASE_JWT]
      expect(claims[:role]).to eq 'student'
    end
  end
end
