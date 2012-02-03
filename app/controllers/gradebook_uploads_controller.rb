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

class GradebookUploadsController < ApplicationController
  before_filter :require_context
  def new
    if authorized_action(@context, @current_user, :manage_grades)
      @gradebook_upload = @context.build_gradebook_upload
    end
  end
  
  def create
    if authorized_action(@context, @current_user, :manage_grades)
      if params[:gradebook_upload] &&
       (@attachment = params[:gradebook_upload][:uploaded_data]) &&
       (@attachment_contents = @attachment.read)

        @uploaded_gradebook = GradebookImporter.new(@context, @attachment_contents)
        errored_csv = false
        begin
          @uploaded_gradebook.parse!
        rescue => e
          logger.warn "Error importing gradebook: #{e.inspect}"
          errored_csv = true
        end
        respond_to do |format|
          if errored_csv
            flash[:error] = t('errors.invalid_file', "Invalid csv file, grades could not be updated")
            format.html { redirect_to named_context_url(@context, :context_gradebook_url) }
          else
            format.html { render :action => "show" }
          end
        end
      else
        respond_to do |format|
          flash[:error] = t('errors.upload_failed', 'File could not be uploaded.')
          format.html { redirect_to named_context_url(@context, :context_gradebook_url) }
        end
      end
    end
  end

  def update
    @data_to_load = ActiveSupport::JSON.decode(params["json_data_to_submit"])
    if authorized_action(@context, @current_user, :manage_grades) 
      if @data_to_load
        @students = @data_to_load["students"]
        @assignments = @data_to_load["assignments"]
        assignment_map = {}
        new_assignment_ids = {}
        @assignments.each do |assignment|
          if !assignment['original_id'] && assignment['id'].to_i < 0
            a = @context.assignments.create!(:title => assignment['title'], :points_possible => assignment['points_possible'])
            new_assignment_ids[assignment['id']] = a.id
            assignment['id'] = a.id
            assignment['original_id'] = a.id
          else
            a = @context.assignments.find(assignment['id'].to_i)
          end
          assignment_map[a.id] = a
        end
        @submissions = @students.inject([]) do |list, student_record|
          student_record['submissions'].map do |submission_record|
            list << {
              :assignment_id => new_assignment_ids[submission_record['assignment_id']] || submission_record['assignment_id'].to_i,
              :user_id => student_record['original_id'].to_i,
              :grade => submission_record['grade']
            }
          end
          list
        end
      
        submissions_updated_count = 0
        @submissions.each do |sub|
          next unless @assignments
          assignment = assignment_map[sub[:assignment_id].to_i]
          next unless assignment
          submission = assignment.find_or_create_submission(sub[:user_id])
          # grade_to_score expects a string so call to_s here, otherwise things that have a score of zero will return nil
          score = assignment.grade_to_score(sub[:grade].to_s)
          unless score == submission.score
            old_score = submission.score
            submission.grade = sub[:grade].to_s
            submission.score = score
            submission.save!
            submissions_updated_count += 1
            logger.info "updated #{submission.student.name} with score #{submission.score} for assignment: #{submission.assignment.title} old score was #{old_score}"
          end
        end
        flash[:notice] = t('notices.updated', {:one => "Successfully updated 1 submission.", :other => "Successfully updated %{count} submissions."}, :count => submissions_updated_count)
      end
      respond_to do |format|
        format.html { redirect_to named_context_url(@context, :context_gradebook_url) }
      end
    end
  end
  
end
