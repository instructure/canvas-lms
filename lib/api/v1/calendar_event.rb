#
# Copyright (C) 2012 - present Instructure, Inc.
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

module Api::V1::CalendarEvent
  include Api::V1::Json
  include Api::V1::Assignment
  include Api::V1::Submission
  include Api::V1::AssignmentOverride
  include Api::V1::User
  include Api::V1::Course
  include Api::V1::Group

  def event_json(event, user, session, options={})
    hash = if event.is_a?(::CalendarEvent)
      calendar_event_json(event, user, session, options)
    else
      assignment_event_json(event, user, session, options)
    end
    hash
  end

  def calendar_event_json(event, user, session, options={})
    excludes = options[:excludes] || []
    include = options[:include]
    include ||= excludes.include?('child_events') ? [] : ['child_events']

    context = (options[:context] || event.context)
    duplicates = options[:duplicates] || []
    participant = nil

    hash = api_json(event, user, session, :only => %w(id created_at updated_at start_at end_at all_day all_day_date title location_address location_name workflow_state comments))
    hash['type'] = 'event'
    if event.context_type == "CourseSection"
      hash['title'] += " (#{context.name})"
      hash['description'] = api_user_content(event.description, event.context.course) unless excludes.include?('description')
    else
      hash['description'] = api_user_content(event.description, context) unless excludes.include?('description')
    end

    appointment_group = options[:appointment_group]
    appointment_group ||= AppointmentGroup.find(options[:appointment_group_id]) if options[:appointment_group_id]
    appointment_group ||= event.appointment_group

    # force it to load
    include_child_events = include.include?('child_events')
    if include_child_events
      hash["child_events_count"] = event.child_events.length
    else
      hash["child_events_count"] = options[:child_events_count] || event.child_events.size
    end

    if event.effective_context_code
      if appointment_group && include_child_events
        common_context_codes = common_ag_context_codes(appointment_group, user, event, options[:for_scheduler])
        effective_context_code = (event.effective_context_code.split(',') & common_context_codes).first
        if effective_context_code
          hash['context_code'] = hash['effective_context_code'] = effective_context_code
        else
          # the teacher has no courses in common with the signups
          include_child_events = false
          hash["child_events"] = []
          hash["child_events_count"] = 0
          hash['effective_context_code'] = event.effective_context_code
        end
      else
        hash['effective_context_code'] = event.effective_context_code
      end
      hash['all_context_codes'] = event.effective_context_code
    else
      hash['all_context_codes'] = Context.context_code_for(event)
    end
    hash['context_code'] ||= Context.context_code_for(event)

    hash['parent_event_id'] = event.parent_calendar_event_id
    # events are hidden when section-specific events override them
    # but if nobody is logged in, no sections apply, so show the base event
    hash['hidden'] = user ? event.hidden? : false

    if include.include?('participants')
      if event.context_type == 'User'
        hash['user'] = user_json(event.context, user, session)
      elsif event.context_type == 'Group'
        hash['group'] = group_json(event.context, user, session, :include => ['users'])
      end
    end
    if appointment_group
      hash['appointment_group_id'] = appointment_group.id
      hash['appointment_group_url'] = api_v1_appointment_group_url(appointment_group)
      hash['can_manage_appointment_group'] = appointment_group.grants_right?(user, session, :manage)
      hash['participant_type'] = appointment_group.participant_type
      if options[:current_participant] && event.has_asset?(options[:current_participant])
        hash['own_reservation'] = true
      end
    end
    if event.context_type == 'AppointmentGroup'
      if context.grants_right?(user, session, :reserve)
        participant = context.participant_for(user)
        participant_child_events = event.child_events_for(participant)
        hash['reserved'] = (Array === participant_child_events ? participant_child_events.present? : participant_child_events.exists?)
        hash['reserve_comments'] = participant_child_events.map(&:comments).compact.join(", ")
        hash['reserve_url'] = api_v1_calendar_event_reserve_url(event, participant)
      else
        hash['reserve_url'] = api_v1_calendar_event_reserve_url(event, '{{ id }}')
      end
      if participant_limit = event.participants_per_appointment
        hash["available_slots"] = [participant_limit - event.child_events.size, 0].max
        hash["participants_per_appointment"] = participant_limit
      end
    end

    hash["child_events"] = [] if include_child_events || hash['reserved']
    if include_child_events && hash["child_events_count"] > 0
      can_read_child_events = event.grants_right?(user, session, :read_child_events)
      if can_read_child_events || hash['reserved']
        events = can_read_child_events ? event.child_events.to_a : event.child_events_for(participant)

        # do some preloads
        ActiveRecord::Associations::Preloader.new.preload(events, :context)
        if events.first.context.is_a?(User) && user_json_is_admin?(@context, user)
          user_json_preloads(events.map(&:context))
        end
        can_manage = event.grants_right?(user, session, :manage)


        hash["child_events"] = events.map{ |e|
          e.parent_event = event
          calendar_event_json(e, user, session,
            :include => appointment_group ? ['participants'] : [],
            :appointment_group => appointment_group,
            :current_participant => participant,
            :url_override => can_manage,
            :child_events_count => 0,
            :effective_context => options[:effective_context]
          )
        }
      end
    end

    hash['url'] = api_v1_calendar_event_url(event) if options.has_key?(:url_override) ? options[:url_override] || hash['own_reservation'] : event.grants_right?(user, session, :read)
    hash['html_url'] = calendar_url_for(options[:effective_context] || event.effective_context, :event => event)
    hash['duplicates'] = duplicates
    hash
  end

  def assignment_event_json(assignment, user, session, options={})
    excludes = options[:excludes] || []
    hash = api_json(assignment, user, session, :only => %w(created_at updated_at title all_day all_day_date workflow_state))
    hash['description'] = api_user_content(assignment.description, assignment.context) unless excludes.include?('description')
    hash['id'] = "assignment_#{assignment.id}"
    hash['type'] = 'assignment'

    if excludes.include?('assignment')
      hash['html_url'] = course_assignment_url(assignment.context_id, assignment)
    else
      hash['assignment'] = assignment_json(assignment, user, session, override_dates: false, submission: options[:submission])
      hash['html_url'] = hash['assignment']['html_url'] if hash['assignment'].include?('html_url')
    end
    hash['context_code'] = Context.context_code_for(assignment)
    hash['start_at'] = hash['end_at'] = assignment.due_at
    hash['url'] = api_v1_calendar_event_url("assignment_#{assignment.id}")
    if assignment.applied_overrides.present?
      hash['assignment_overrides'] = assignment.applied_overrides.map { |o| assignment_override_json(o) }
    end
    hash
  end

  def appointment_group_json(group, user, session, options={})
    orig_context = @context
    @context = group.contexts_for_user(user).first
    @user_json_is_admin = nil # when returning multiple groups, @current_user may be admin over some contexts but not others. so we need to recheck

    include = options[:include] || []
    hash = api_json(group, user, session, :only => %w{id created_at description end_at location_address location_name max_appointments_per_participant min_appointments_per_participant participants_per_appointment start_at title updated_at workflow_state participant_visibility}, :methods => :sub_context_codes)

    hash['participant_count'] = group.appointments_participants.count if include.include?('participant_count')
    hash['reserved_times'] = group.reservations_for(user).map{|event| {
        :id => event.id,
        :start_at => event.start_at,
        :end_at => event.end_at}} if include.include?('reserved_times')
    hash['context_codes'] = group.context_codes_for_user(user)
    hash['all_context_codes'] = group.context_codes if include.include?('all_context_codes') && group.grants_right?(user, session, :manage)
    hash['requiring_action'] = group.requiring_action?(user)
    if group.new_appointments.present?
      hash['new_appointments'] = group.new_appointments.map{ |event| calendar_event_json(event, user, session, :skip_details => true, :appointment_group_id => group.id) }
    end
    if include.include?('appointments')
      appointments_scope = group.appointments
      appointments_scope = appointments_scope.where('end_at IS NULL OR end_at>?', Time.now.utc) unless options[:include_past_appointments]
      if include.include?('child_events')
        all_child_events = appointments_scope.map(&:child_events).flatten
        ActiveRecord::Associations::Preloader.new.preload(all_child_events, :context)
        user_json_preloads(all_child_events.map(&:context)) if !all_child_events.empty? && all_child_events.first.context.is_a?(User) && user_json_is_admin?(@context, user)
      end
      hash['appointments'] = appointments_scope.map { |event| calendar_event_json(event, user, session,
                                                                                 :context => group,
                                                                                 :appointment_group => group,
                                                                                 :appointment_group_id => group.id,
                                                                                 :include => include & ['child_events'],
                                                                                 :effective_context => @context,
                                                                                 :for_scheduler => true) }
    end
    hash['appointments_count'] = group.appointments.size
    hash['participant_type'] = group.participant_type
    hash['url'] = api_v1_appointment_group_url(group)
    hash['html_url'] = appointment_group_url(hash['id'])
    hash
  ensure
    @context = orig_context
  end

  private

  # find context codes shared by the viewing user and the user(s) signed up,
  # falling back on the viewing user's contexts if no users are signed up.
  # however, don't limit contexts by existing signups in scheduler view.
  def common_ag_context_codes(appointment_group, user, event, for_scheduler)
    codes_for_user = appointment_group.context_codes_for_user(user)
    unless for_scheduler
      event_user = event.user || infer_user_from_child_events(event.child_events)
      if event_user
        codes_for_event_user = appointment_group.context_codes_for_user(event_user)
        return codes_for_user & codes_for_event_user
      end
    end
    codes_for_user
  end

  # for an AG in multiple courses, if all students signing up for a slot are in the same course,
  # put the event on that course's calendar
  def infer_user_from_child_events(child_events)
    unique_user_ids = child_events.map(&:user_id).uniq
    return child_events.first.user if unique_user_ids.length == 1
    nil
  end

end
