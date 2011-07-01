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

class EnrollmentsFromUserList
  class << self
    def process(list, course, opts={})
      EnrollmentsFromUserList.new(course, opts).process(list)
    end
  end
  
  attr_reader :students, :course
  
  def initialize(course, opts={})
    @course = course
    @new_user_state = @course.available? ? "pre_registered" : "creation_pending"
    @enrollment_state = opts[:enrollment_state]
    @enrollment_type = opts[:enrollment_type] || 'StudentEnrollment'
    @limit = opts[:limit]
    @section = (opts[:course_section_id].present? ? @course.course_sections.active.find_by_id(opts[:course_section_id]) : nil) || @course.default_section
    @limit_privileges_to_course_section = opts[:limit_priveleges_to_course_section] # doh, misspelling
    @enrolled_users = {}
  end
  
  def process(list)
    raise ArgumentError, "Must provide a UserList" unless list.is_a?(UserList)
    @enrollments = []
    entries = @limit ? list.users[0,@limit] : list.users
    
    unique_ids = []
    emails = []
    entries.each do |e|
      if e[:address]
        unique_ids << e[:address]
        emails << e[:address]
      end
      unique_ids << e[:login] if e[:login]
    end
    
    found_pseudonyms = {}
    @course.root_account.pseudonyms.active.find(:all, :conditions => "LOWER(pseudonyms.unique_id) in (#{unique_ids.map{|x| Pseudonym.sanitize(x.downcase)}.join(", ")})", :include => [:user]).each{|p| found_pseudonyms[p.unique_id] = p}

    # really more of this should be SQL
    found_channels = {}
    CommunicationChannel.find(:all, :conditions => {:path => emails, :path_type => 'email', :workflow_state => ['active','unconfirmed']}, :include => {:user => :pseudonyms, :pseudonym => {}}).each do |cc|
      found_channels[cc.path.downcase] ||= []
      found_channels[cc.path.downcase] << cc
    end
    found_channels.keys.each do |path|
      found_channels[path] = found_channels[path].sort_by{|some_cc| [(some_cc.active? ? 0 : 1), (some_cc.pseudonym && some_cc.pseudonym.account_id == @course.root_account.id ? 0 : 1), (some_cc.created_at || Time.now)]}.first
    end
    
    users = {}
    entries.each do |entry|
      if email = entry[:address]
        pseudonym = found_pseudonyms[email]
        if pseudonym
          enroll_user pseudonym.user
          next
        end
        
        new_cc = false
        cc = found_channels[email.downcase]
        unless cc
          cc = CommunicationChannel.create(:path => email, :path_type => 'email')
          new_cc = true
        end
        new_user = false
        user = cc.assert_user do |u|
          u.workflow_state = @new_user_state
          new_user = true
        end
        user.invitation_email = email
        user.assert_name(entry[:name])
        
        # there isn't a pseudonym by this unique_id, or else we wouldn't have got here.
        # see if we can find an existing pseudonym that works, otherwise make one.
        if !(pseudonym = user.pseudonyms.detect{|p| p.works_for_account?(@course.root_account) })
          pseudonym = user.pseudonyms.build(:unique_id => email, :account => @course.root_account)
          pseudonym.save_without_session_maintenance
        end
        
        # did our pseudonym save fail?
        if pseudonym.new_record?
          # we just created this stuff, so let's destroy it.
          cc.destroy if new_cc
          user.destroy if new_user
        else
          enroll_user user
        end

      elsif entry[:login]
        enroll_user found_pseudonyms[entry[:login]].try(:user)
      end
    end
    return @enrollments
  end
  
  protected
  
  def enroll_user(user)
    return unless user
    return if @enrolled_users.has_key?(user.id)
    @enrolled_users[user.id] = true
    @course.enroll_user(user, @enrollment_type, :section => @section, :limit_priveleges_to_course_section => @limit_privileges_to_course_section, :enrollment_state => @enrollment_state).tap do |e|
      @enrollments << e if e
    end
  end
end
