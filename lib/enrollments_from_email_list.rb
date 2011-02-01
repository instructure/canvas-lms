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

class EnrollmentsFromEmailList
  class << self
    def process(list, opts={})
      course_id = opts.delete(:course_id)
      sfao = new(course_id)
      sfao.process(list, opts)
    end
  end
  
  
  attr_reader :students, :course
  
  def initialize(course_id)
    @course = Course.find_by_id(course_id) or raise ArgumentError, "Must provide a valid course id"
    @entries = []
    @students = []
  end
  
  def process(list, opts={})
    raise ArgumentError, "Must provide a EmailList" unless
      list.is_a?(EmailList)
    enrollment_type = opts.fetch(:enrollment_type, 'StudentEnrollment')
    section = @course.course_sections.active.find_by_id(opts[:course_section_id]) || @course.default_section
    limit_priveleges_to_course_section = opts[:limit_priveleges_to_course_section]
    @entries = list.addresses
    if opts[:limit]
      @entries = @entries[0,opts[:limit]]
    end
    @new_user_state = @course.available? ? "pre_registered" : "creation_pending"
    get_students(@course.root_account)
    enroll_users(enrollment_type, section, limit_priveleges_to_course_section, opts[:enrollment_state])
    return @enrollments
  end


  protected
    
    # Generate a list of students and pseudonyms
    def get_students(root_account)
      @pseudonyms = []
      emails = @entries.map{|e| e.address }.compact
      found_pseudonyms = root_account.pseudonyms.active.find(:all, :conditions => {:unique_id => emails}, :include => [:user]) #_all_by_unique_id(emails)
      found_channels = CommunicationChannel.find(:all, :conditions => {:path => emails, :path_type => 'email', :workflow_state => ['active','unconfirmed']}, :include => {:user => :pseudonyms, :pseudonym => {}}) #_all_by_path_and_path_type_and_workflow_state(emails, 'email', 'active')
      @students = @entries.map do |entry|
        next unless email = entry.address
        pseudonym = found_pseudonyms.find{|p| p.unique_id == email } #root_account.pseudonyms.active.find_by_unique_id(email)
        cc = nil
        if pseudonym
          pseudonym.assert_user { |u| u.workflow_state = @new_user_state }
          pseudonym.path = email
          pseudonym.assert_communication_channel
          cc = pseudonym.communication_channel if pseudonym.communication_channel && pseudonym.communication_channel.path == email
        end
        ccs = found_channels.select{|some_cc| some_cc.path.downcase == email.downcase } #CommunicationChannel.find_all_by_path_and_path_type_and_workflow_state(email, 'email', 'active')
        cc ||= ccs.sort_by{|some_cc| [(some_cc.active? ? 0 : 1), (some_cc.pseudonym && some_cc.pseudonym.account_id == root_account.id ? 0 : 1), (some_cc.created_at || Time.now)] }.first
        cc ||= CommunicationChannel.create(:path => email, :path_type => 'email')
        user = cc.assert_user { |u| u.workflow_state = @new_user_state }
        user.invitation_email = email
        user.assert_name(entry.name)
        if !pseudonym && !(pseudonym = user.pseudonyms.detect{|p| p.works_for_account?(root_account) })
          pseudonym = user.pseudonyms.build(:unique_id => email, :account => root_account)
          pseudonym.save_without_session_maintenance
        end
        # At this point, we have a saved user with a name and an address
        # Can't create a student unless it can assert a pseudonym.  
        # This uses either en existing pseudonym or creates one.
        if pseudonym && !pseudonym.new_record?
          @pseudonyms << pseudonym
          cc.save!
          user.reload
        else
          user.destroy
          nil
        end
      end
      @students.compact!
    end
    
    # Both enrolls students and creates a list of enrolled students.
    def enroll_users(enrollment_type, section, limit_priveleges_to_course_section, enrollment_state)
      @enrollments = []
      @students = @students.compact.uniq
      @students.each do |student|
        e = @course.enroll_user(student, enrollment_type, :section => section, :limit_priveleges_to_course_section => limit_priveleges_to_course_section, :enrollment_state => enrollment_state)
        @enrollments << e if e
      end
      @enrollments
    end
  
end
