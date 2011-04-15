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

module SIS
  class CrossListImporter < SisImporter
    
    def self.is_xlist_csv?(row)
      row.header?('xlist_course_id') && row.header?('section_id')
    end
    
    def verify(csv, verify)
      FasterCSV.foreach(csv[:fullpath], :headers => :first_row, :skip_blanks => true, :header_converters => :downcase) do |row|
        add_error(csv, "No xlist_course_id given for a cross-listing") if row['xlist_course_id'].blank?
        add_error(csv, "No section_id given for a cross-listing") if row['section_id'].blank?
        add_error(csv, "Improper status \"#{row['status']}\" for a cross-listing") unless row['status'] =~ /\A(active|deleted)\z/i
      end
    end
    
    # possible columns:
    # xlist_course_id, section_id, status
    def process(csv)
      start = Time.now
      course = nil
      FasterCSV.foreach(csv[:fullpath], :headers => :first_row, :skip_blanks => true, :header_converters => :downcase) do |row|
        update_progress
        logger.debug("Processing CrossListing #{row.inspect}")
        
        # reduce database hits if possible (csv sorted by xlist_course_id will be faster)
        unless course && course.sis_source_id == row['xlist_course_id']
          course = Course.find_by_root_account_id_and_sis_source_id(@root_account.id, row['xlist_course_id'])
          if !course && row['status'] =~ /\Aactive\z/i
            course = Course.new
            course.root_account_id = @root_account.id
            course.account_id = @root_account.id
            course.sis_source_id = course.name = course.sis_name = course.short_name = course.sis_course_code = row['xlist_course_id']
            course.sis_batch_id = @batch.id if @batch
            course.workflow_state = 'claimed'
            course.save_without_broadcasting!
          end
        end
        
        section = CourseSection.find_by_root_account_id_and_sis_source_id(@root_account.id, row['section_id'])
        unless section
          add_warning(csv, "A cross-listing referenced a non-existent section #{row['section_id']}")
          next
        end
        
        if row['status'] =~ /\Aactive\z/i
          next if section.course.id == course.id
          
          section.account ||= section.course.account
          section.save
          
          begin
            section.move_to_course course
          rescue => e
            add_warning(csv, "An active cross-listing failed: #{e}")
            next
          end
  
        elsif row['status'] =~ /\Adeleted\z/i
          next if course && section.course != course 
          
          section.account = nil
          section.save

          begin
            section.move_to_course section.last_course
            section.last_course = nil
            section.save
          rescue => e
            add_warning(csv, "A deleted cross-listing failed: #{e}")
            next
          end
          
        else
          add_error(csv, "Improper status #{row['status']} for a cross-listing")
        end
        
        @sis.counts[:xlists] += 1
      end
    end
    
  end
end
