#
# Copyright (C) 2011 Instructure, Inc.
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
# SFU Note: Slightly modified from the original provided by ccutrer in IRC.
#           Original file can be found at https://gist.github.com/grahamb/ed5475ac5f4cbbacf62b

require Pathname(File.dirname(__FILE__)) + "../../sfu_api/app/model/sfu/sfu"

ApplicationController.class_eval do
  def self.test_cluster
    unless defined?(@test_cluster)
      @test_cluster = Setting.from_config('testcluster', false).try(:[], 'test_cluster')
    end
    @test_cluster
  end

  def self.test_cluster?
    !!self.test_cluster
  end

  def current_username
    user = User.find(@current_user.id)
    sfuid = user.pseudonym.unique_id
    sfuid.slice! "@sfu.ca"
    sfuid
  end

  before_filter :add_tc_warning
  def add_tc_warning
    return true unless ApplicationController.test_cluster?
    @fixed_warnings ||= []
    @fixed_warnings << {
      :icon => "warning",
      :title => t('#warnings.test_install.title', "Canvas Test Installation"),
      :message => t('#warnings.test_install.message', "This Canvas installation is only for testing, and may be reset at any time without warning."),
    }
  end

  before_filter :block_student_access
  def block_student_access
    return true unless ApplicationController.test_cluster?
    return true if @files_domain
    return true if @real_current_user # masquerading is always allowed
    return true if self.is_a? InfoController and params[:action] == 'health_check'
    # teachers need to be able to accept invitations
    return true if self.is_a? CoursesController and params[:action] == 'enrollment_invitation'

    return true unless @domain_root_account # WTF? apparently mobile verify skips loading the DRA
    return true if @domain_root_account.service_enabled?(:beta_for_students) # account setting to be nice
    old_crumbs = crumbs.dup
    get_context rescue nil
    # avoid double-crumbs cause we nil out @context and it gets called again
    crumbs.replace(old_crumbs)
    if @context.is_a?(Course) && !(@context.grants_right?(@current_user, :read_as_admin) || SFU::User.belongs_to_maillist?(current_username, "canvas-test-cluster-bypass"))
      @unauthorized_message = "Students are not allowed to access test installations."
      return render_unauthorized_action
    end
    @context = nil
  end
end