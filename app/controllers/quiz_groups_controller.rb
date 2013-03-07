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

class QuizGroupsController < ApplicationController
  before_filter :require_context, :get_quiz

  def create
    if authorized_action(@quiz, @current_user, :update)
      @quiz.did_edit if @quiz.created?
      if (bank_id = params[:quiz_group].delete(:assessment_question_bank_id)) && !bank_id.blank?
        if @bank = find_bank(bank_id)
          params[:quiz_group][:assessment_question_bank] = @bank
        end
      end
      @group = @quiz.quiz_groups.build(params[:quiz_group])
      if @group.save
        render :json => @group.to_json
      else
        render :json => @group.errors.to_json, :status => :bad_request
      end
    end
  end

  def update
    if authorized_action(@quiz, @current_user, :update)
      @group = @quiz.quiz_groups.find(params[:id])
      @quiz.did_edit if @quiz.created?
      params[:quiz_group][:position] = @quiz.root_entries_max_position + 1
      params[:quiz_group].delete(:assessment_question_bank_id)
      params[:quiz_group].delete(:position) # position is taken care of in reorder
      if @group.update_attributes(params[:quiz_group])
        render :json => @group.to_json
      else
        render :json => @group.errors.to_json, :status => :bad_request
      end
    end
  end

  def destroy
    if authorized_action(@quiz, @current_user, :update)
      @group = @quiz.quiz_groups.find(params[:id])
      @group.destroy
      render :json => @group.to_json
    end
  end
  
  def reorder
    if authorized_action(@quiz, @current_user, :update)
      @group = @quiz.quiz_groups.find(params[:quiz_group_id])
      items = []
      group_questions = @group.quiz_questions
      questions = @quiz.quiz_questions
      order = params[:order].split(",")
      order.each do |name|
        id = name.gsub(/\Aquestion_/, "").to_i
        obj = questions.detect{|q| q.id == id.to_i }
        obj.quiz_group_id = @group.id
        if obj
          items << obj
          obj.position = items.length
        end
      end
      group_questions.each do |q|
        if !items.include? q
          items << q
          q.position = items.length
        end
      end
      updates = []
      items.each_with_index do |item, idx|
        updates << "WHEN id=#{item.id} THEN #{idx + 1}"
      end
      QuizQuestion.where(:id => items).update_all("quiz_group_id=#{@group.id}, position=CASE #{updates.join(" ")} ELSE id END")
      Quiz.mark_quiz_edited(@quiz.id)
      render :json => {:reorder => true}
    end
  end
  
  def get_quiz
    @quiz = @context.quizzes.find(params[:quiz_id])
  end
  private :get_quiz
end
