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

class GradeCalculator
  
  def initialize(user_ids, course_id)
    @course_id = course_id
    @course = Course.find(course_id)
    @groups = @course.assignment_groups.active
    @assignments = @course.assignments.active.only_graded
    @user_ids = Array(user_ids).map(&:to_i)
    @current_updates = []
    @final_updates = []
  end
  
  def self.recompute_final_score(user_ids, course_id)
    calc = GradeCalculator.new user_ids, course_id
    calc.recompute_and_save_scores
  end
  
  # recomputes the scores and saves them to each user's Enrollment
  def recompute_and_save_scores
    all_submissions = @course.submissions.for_user(@user_ids).to_a
    @user_ids.each do |user_id|
      submissions = all_submissions.select { |submission| submission.user_id == user_id }
      calculate_current_score(user_id, submissions)
      calculate_final_score(user_id, submissions)
    end

    Course.update_all({:updated_at => Time.now.utc}, {:id => @course.id})
    if !@current_updates.empty? || !@final_updates.empty?
      query = "updated_at=#{Enrollment.sanitize(Time.now.utc)}"
      query += ", computed_current_score=CASE #{@current_updates.join(" ")} ELSE computed_current_score END" unless @current_updates.empty?
      query += ", computed_final_score=CASE #{@final_updates.join(" ")} ELSE computed_final_score END" unless @final_updates.empty?
      Enrollment.update_all(query, {:user_id => @user_ids, :course_id => @course.id})
    end
  end

  :private
  
  # The score ignoring unsubmitted assignments
  def calculate_current_score(user_id, submissions)
    group_sums = create_group_sums(submissions)
    score = calculate_total_from_group_scores(group_sums)
    @current_updates << "WHEN user_id=#{user_id} THEN #{score || "NULL"}"
  end

  # The final score for the class, so unsubmitted assignments count as zeros
  def calculate_final_score(user_id, submissions)
    group_sums = create_group_sums(submissions, false)
    score = calculate_total_from_group_scores(group_sums, false)
    @final_updates << "WHEN user_id=#{user_id} THEN #{score || "NULL"}"
  end
 
  # Creates a hash for each assignment group with stats and the end score for each group
  def create_group_sums(submissions, ignore_ungraded=true)
    group_sums = {}
    @groups.each do |group|
      group_assignments = @assignments.select { |a| a.assignment_group_id == group.id }
      assignment_submissions = []
      sums = {:name => group.name,
              :total_points => 0, 
              :user_points => 0, 
              :group_weight => group.group_weight || 0, 
              :submission_count => 0}
      
      # collect submissions for this user for all the assignments
      # if an assignment is muted it will be treated as if there is no submission
      group_assignments.each do |assignment|
        submission = submissions.detect { |s| s.assignment_id == assignment.id }
        submission = nil if assignment.muted
        submission ||= OpenStruct.new(:assignment_id=>assignment.id, :score=>0) unless ignore_ungraded
        assignment_submissions << {:assignment => assignment, :submission => submission}
      end
      
      # Sort the submissions that have a grade by score (to easily drop lowest/highest grades)
      if ignore_ungraded
        sorted_assignment_submissions = assignment_submissions.select { |hash| hash[:submission] && hash[:submission].score }
      else
        sorted_assignment_submissions = assignment_submissions.select { |hash| hash[:submission] }
      end
      sorted_assignment_submissions = sorted_assignment_submissions.sort_by do |hash|
        val = (((hash[:submission].score || 0)/ hash[:assignment].points_possible) rescue 999999)
        val.to_f.finite? ? val : 999999
      end
      
      # Mark the assignments that aren't allowed to be dropped
      if group.rules_hash[:never_drop]
        sorted_assignment_submissions.each do |hash|
          never_drop = group.rules_hash[:never_drop].include?(hash[:assignment].id)
          hash[:never_drop] = true if never_drop
        end
      end
      
      # Flag the the lowest assignments to be dropped
      low_drop_count = 0
      high_drop_count = 0
      total_scored = sorted_assignment_submissions.length
      if group.rules_hash[:drop_lowest]
        drop_total = group.rules_hash[:drop_lowest] || 0
        sorted_assignment_submissions.each do |hash|
          if !hash[:drop] && !hash[:never_drop] && low_drop_count < drop_total && (low_drop_count + high_drop_count + 1) < total_scored
            low_drop_count += 1
            hash[:drop] = true
          end
        end
      end
      
      # Flag the highest assignments to be dropped
      if group.rules_hash[:drop_highest]
        drop_total = group.rules_hash[:drop_highest] || 0
        sorted_assignment_submissions.reverse.each do |hash|
          if !hash[:drop] && !hash[:never_drop] && high_drop_count < drop_total && (low_drop_count + high_drop_count + 1) < total_scored
            high_drop_count += 1
            hash[:drop] = true
          end
        end
      end
      
      # If all submissions are marked to be dropped: don't drop the highest because we need at least one
      if !sorted_assignment_submissions.empty? && sorted_assignment_submissions.all? { |hash| hash[:drop] }
        sorted_assignment_submissions[-1][:drop] = false
      end
      
      # Count the points from all the non-dropped submissions
      sorted_assignment_submissions.select { |hash| !hash[:drop] }.each do |hash|
        sums[:submission_count] += 1
        sums[:total_points] += hash[:assignment].points_possible || 0
        sums[:user_points] += (hash[:submission] && hash[:submission].score) || 0
      end
      
      # Calculate the tally for this group
      sums[:group_weight] = group.group_weight || 0
      sums[:tally] = sums[:user_points].to_f / sums[:total_points].to_f
      sums[:tally] = 0.0 unless sums[:tally].finite?
      sums[:weighted_tally] = sums[:tally] * sums[:group_weight].to_f
      group_sums[group.id] = sums
    end
    group_sums
  end
  
  # Calculates the final score from the sums of all the assignment groups
  def calculate_total_from_group_scores(group_sums, ignore_ungraded=true)
    if @course.group_weighting_scheme == 'percent'
      score = 0
      possible_weight_from_submissions = 0
      total_possible_weight = 0
      group_sums.select { |id, hash| hash[:group_weight] > 0 }.each do |id, hash|
        if hash[:submission_count] > 0
          score += hash[:weighted_tally].to_f
          possible_weight_from_submissions += hash[:group_weight].to_f
        end
        total_possible_weight += hash[:group_weight].to_f
      end
      if ignore_ungraded && score && possible_weight_from_submissions < 100.0
        possible = total_possible_weight < 100 ? total_possible_weight : 100 
        score = score.to_f * possible / possible_weight_from_submissions.to_f rescue nil
      end
      score = (score * 10.0).round / 10.0 rescue nil
    else
      total_points = 0
      user_points = 0
      group_sums.select { |id, hash| hash[:submission_count] > 0 }.each do |id, hash|
        total_points += hash[:total_points] || 0
        user_points += hash[:user_points] || 0
      end
      score = (user_points.to_f / total_points.to_f * 1000.0).round / 10.0 rescue nil
      score = 0 if score && score.nan?
    end
    score
  end
end
