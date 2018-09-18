# This does our special grading stuff that relates to magic fields
# like course participation, mastery, etc. It can be used from the
# bz_controller and also from various grade audit helper scripts.
#
# For now though it isn't used from bz_controller and duplicates a
# bunch of code from there. That's just because the cleanup is hard to
# test so trying to do it in smaller chunks
=begin
  The main public methods you probably want to use are

  ```
  module_unique_magic_fields(module_item_id).each |n|
    # n is a Nokogiri node that represents the magic field element
  end

  response_object = calculate_user_module_score(module_item_id, current_user)
    # response_object has total_score, points_possible, audit_trace

  set_user_grade(participation_assignment, current_user, new_grade)
    # user gets graded
  ```

  The other methods are mostly to help you get the arguments for those three. Only
  use set_user_grade as part of an audit/adjustment script. Otherwise, see code in
  bz_controller for how to use add_to_user_grade.


  To do stuff like half credit for past due, to calculate_user_module_score, but instead
  of using the total_score in the response, instead loop over the audit trace and add points:

  ```
  bzg = BZGrading.new

  # calculate existing score and audit trace
  response_object = bzg.calculate_user_module_score(module_item_id, current_user)

  # adjust for special past due partial credit rule
  score = 0.0
  response_object["audit_trace"].each do |at|
    if at["points_changed"]
      score += at["points_amount"]
    elsif at["points_reason"] == "past_due"
      score += at["points_possible"] / 2
    end
  end

  # save it back
  bzg.set_user_grade_for_module(module_item_id, current_user, score)
  ```

  Or something like that.

=end
class BZGrading

  def initialize

  end

  def find_module_item_id(course_id, wiki_page_name)
    pages = WikiPage.where(:title => wiki_page_name)
    tag = nil
    pages.each do |page| # Don't know which WikiPage is from this course, need to lookup the ContentTag for each to find the association
      tag = ContentTag.where(:content_id => page.id, :context_id => course_id, :context_type => 'Course', :content_type => 'WikiPage').first
      if !tag.nil?
        return tag.id
      end
    end
    return nil
  end

  def module_unique_magic_fields(module_item_id)
    context_module = get_context_module(module_item_id)

    names = {}
    selector = 'input[data-bz-retained]:not(.bz-optional-magic-field),textarea[data-bz-retained]:not(.bz-optional-magic-field)'

    # Loop over the Wiki Pages in this module
    items_in_module = context_module.content_tags.active
    items_in_module.each do |item|
      next if !item.published?
      if item.content_type == "WikiPage"
        wiki_page = WikiPage.find(item.content_id)
        page_html = wiki_page.body
        doc = Nokogiri::HTML(page_html)

        # pull in sandwiched modules
        doc.css('[data-replace-with-page]').each do |o|
          p = o.attr('data-replace-with-page')

          all_pages = context_module.course.wiki_pages.active
          page = all_pages.where(:title => p)
          if page.any?
            o.inner_html = page.first.body
          end
        end

        # find magic fields
        doc.css(selector).each do |o|
          n = o.attr('data-bz-retained')
          next if names[n]
          next if o.attr('type') == 'checkbox' && o.attr('data-bz-answer').nil?
          names[n] = true

          yield(o)
        end
      end
    end

    return nil
  end

  def get_magic_field_weight_count(module_item_id)
    context_module = get_context_module(module_item_id)

    total_weight = 0
    graded_checkboxes_that_are_supposed_to_be_empty_weight = 0

    module_unique_magic_fields(module_item_id) do |o|
      n = o.attr('data-bz-retained')
      item_weight = o.attr('data-bz-weight').nil? ? 1 : o.attr('data-bz-weight').to_i
      total_weight += item_weight
      if o.attr('type') == 'checkbox' && o.attr('data-bz-answer') == ''
        graded_checkboxes_that_are_supposed_to_be_empty_weight += item_weight
      end
      Rails.logger.debug("### set_user_retained_data - incrementing magic fields count for: #{n}, total_weight = #{total_weight}, graded_checkboxes_that_are_supposed_to_be_empty_weight = #{graded_checkboxes_that_are_supposed_to_be_empty_weight}")
    end
    [total_weight == 0 ? 1 : total_weight, graded_checkboxes_that_are_supposed_to_be_empty_weight]
  end

  def get_context_module(module_item_id)
    tag = ContentTag.find(module_item_id)
    context_module = tag.context_module
    return context_module
  end

  def get_participation_assignment(course, context_module)
    # This is hacky, but we tie modules to participation tracking assignments using the name.
    # E.g. #Course Participation - Onboarding" would track the Onboarding Module.
    # Note: this is case sensitve based on the module name in the database, not the CSS styled upper case names.
    res = course.assignments.active.where(:title => "Course Participation - #{context_module.name}")
    if !res.empty?
      return res.first
    end

    return nil
  end

  # returns an object with
  # obj["total_score"] = float
  # obj["points_possible"] = float
  # obj["audit_trace"] = array of stuff returned from get_value_of_user_answer for each magic field
  def calculate_user_module_score(module_item_id, current_user)
    magic_field_counts = get_magic_field_weight_count(module_item_id)
    context_module = get_context_module(module_item_id)
    course = context_module.course
    participation_assignment = get_participation_assignment(course, context_module)

    audit_trace = []

    score = 0.0
    module_unique_magic_fields(module_item_id) do |n|
      answer = RetainedData.get_for_course(course.id, current_user.id, n.attr('data-bz-retained'))
      answer_object = get_value_of_user_answer_from_nokogiri(magic_field_counts, current_user, participation_assignment, answer.nil? ? nil : answer.created_at, answer.nil? ? nil : answer.value, n)
      score += answer_object["points_amount"]
      audit_trace <<= answer_object
    end

    returned = {}
    returned["total_score"] = score
    returned["points_possible"] = participation_assignment.points_possible
    returned["audit_trace"] = audit_trace

    return returned
  end

  def add_to_user_grade(participation_assignment, current_user, graded_checkboxes_that_are_supposed_to_be_empty_weight, original_step, step)
    submission = participation_assignment.find_or_create_submission(current_user)
    new_grade = 0
    submission.with_lock do
      existing_grade = submission.grade.nil? ? (graded_checkboxes_that_are_supposed_to_be_empty_weight * original_step) : submission.grade.to_f
      new_grade = existing_grade + step 
      if (new_grade > (participation_assignment.points_possible.to_f - 0.4))
        Rails.logger.debug("### set_user_retained_data - awarding full points since they are close enough #{new_grade}")
        new_grade = participation_assignment.points_possible.to_f # Once they are pretty close to full participation points, always set their grade to full points
                                                                # to account for floating point inaccuracies.
      end
      Rails.logger.debug("### set_user_retained_data - setting new_grade = #{new_grade} = existing_grade + step = #{existing_grade} + #{step}")
      participation_assignment.grade_student(current_user, {:grade => (new_grade), :suppress_notification => true })
    end

    new_grade
  end

  def set_user_grade_for_module(module_item_id, current_user, new_grade)
    cm = get_context_module(module_item_id)
    set_user_grade(get_participation_assignment(cm.course, cm), current_user, new_grade)
  end

  def set_user_grade(participation_assignment, current_user, new_grade)
    submission = participation_assignment.find_or_create_submission(current_user)
    submission.with_lock do
      if (new_grade > (participation_assignment.points_possible.to_f - 0.4))
        Rails.logger.debug("### set_user_retained_data - awarding full points since they are close enough #{new_grade}")
        new_grade = participation_assignment.points_possible.to_f # Once they are pretty close to full participation points, always set their grade to full points
                                                                # to account for floating point inaccuracies.
      end
      participation_assignment.grade_student(current_user, {:grade => (new_grade), :suppress_notification => true })
    end

    new_grade
  end



  def get_value_of_user_answer_from_nokogiri(magic_field_counts, current_user, participation_assignment, time_answer_given, value, nokogiri_element)
    o = nokogiri_element
    return get_value_of_user_answer(o.attr('data-bz-retained'), magic_field_counts, current_user, participation_assignment, value, time_answer_given,
      o.attr('data-bz-weight'), o.attr('data-bz-answer'), o.attr('type'), o.attr('data-bz-partial-credit'))
  end

  # see the next few lines to see what it returns in response_object
  # reasons: wrong, already_awarded, N/A, past_due (last few for 0), not_answered, participation, mastery (these for points). May be preceded with partial_credit:
  def get_value_of_user_answer(magic_field_name, magic_field_counts, current_user, participation_assignment, value, time_answer_given, weight, answer, field_type, partial_credit_mode)
    weight = 1 if weight.nil?

    response_object = {}

    response_object["field_name"] = magic_field_name
    response_object["field_value"] = value
    response_object["field_timing"] = time_answer_given
    response_object["points_given"] = false # did the score go up?
    response_object["points_changed"] = false # did the score change at all? (on incorrect checkboxes it may go down!)
    response_object["points_amount"] = 0
    response_object["points_possible"] = 0
    response_object["points_reason"] = "N/A"

    magic_field_total_weight = magic_field_counts[0]
    graded_checkboxes_that_are_supposed_to_be_empty_weight = magic_field_counts[1]

    step = weight * participation_assignment.points_possible.to_f / magic_field_total_weight
    original_step = step
    response_object["points_possible"] = original_step

    if value.nil?
      # user never answered
      response_object["points_reason"] = "not_answered"
    else
      if !answer.nil? && answer != 'yes' && value == 'yes' && field_type == 'checkbox'
        step = -step # checked the wrong checkbox, deduct points instead (note the exisitng_grade below assumes all are right when it starts so this totals to 100% if they do it all right)
        response_object["points_reason"] = "wrong"
      elsif !answer.nil? && answer == '' && value == '' && field_type == 'checkbox'
        # they checked then unchecked a box, triggering an explicit save. We assume there is no
        # explicit save so the points are already there... but here, there is one, so the points
        # are already there! Thus, despite them putting in the correct answer, since it is a checkbox
        # we want to give them zero points here so they don't get double credit.
        step = 0 # don't award double credit
        response_object["points_reason"] = "already_awarded"
      elsif !answer.nil? && value != answer
        total_potential_value = step
        step = 0 # wrong answer = no points
        response_object["points_reason"] = "wrong"

        case partial_credit_mode
        when 'per_char'
          user_chars = value.split("")
          answer_chars = answer.split("")
          each_char_value = total_potential_value.to_f / answer_chars.count
          answer_chars.each_with_index do |item, index|
            if item == user_chars[index]
              step += each_char_value
              response_object["points_reason"] = "partial_credit"
            end
          end
        end
      end

      response_object["points_changed"] = step != 0
      response_object["points_amount"] = step
      response_object["points_amount_if_on_time"] = step

      if step > 0
        response_object["points_given"] = true
        if response_object["points_reason"] == 'partial_credit'
          response_object["points_reason"] += ":" + (answer.nil? ? "participation" : "mastery")
        else
          response_object["points_reason"] = answer.nil? ? "participation" : "mastery"
        end
      end

      # only update score if we are not yet at the due date or there is no due date
      # participation doesn't count if it is done late.
      # this accounts for a due date being set the same for everyone on the assignment or set differently per section
      overridden = participation_assignment.overridden_for(current_user)
      effective_due_at = overridden.due_at
      effective_due_at = participation_assignment.due_at if overridden.due_at.nil?
      if !effective_due_at.nil? && effective_due_at < time_answer_given
        response_object["points_reason"] = "past_due"
        # if it is a wrong mastery, points may be deducted. continue to deduct them even if late
        response_object["points_amount"] = step > 0 ? 0 : step

        response_object["points_given"] = false
      end
    end


    response_object["points_reason_english"] = case response_object["points_reason"]
      when 'wrong'
        'wrong answer'
      when 'already_awarded'
        'points already awarded elsewhere'
      when 'N/A'
        'N/A'
      when 'past_due'
        'answered past due'
      when 'not_answered'
        'no participation'
      when 'participation'
        'participation'
      when 'mastery'
        'mastery'
      when 'partial_credit:participation'
        'partial participation'
      when 'partial_credit:mastery'
        'partial mastery'
      else
        '?'
    end

    return response_object
  end
end
