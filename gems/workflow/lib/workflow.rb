# Copyright (c) 2008-2009 Vodafone
# Copyright (c) 2007-2008 Ryan Allen, FlashDen Pty Ltd
# Minor changes by Instructure, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

require 'rubygems'
require 'active_support'
 
module Workflow
 
  class Specification
    
    attr_accessor :states, :initial_state, :on_transition_proc
    
    def initialize
      @states = {}
    end

    def add(&specification)
      instance_eval(&specification)
    end

    private
  
    def state(name, &events_and_etc)
      new_state = @states[name.to_sym] || State.new(name)
      @initial_state = new_state if @states.empty?
      @states[name.to_sym] = new_state
      @scoped_state = new_state
      instance_eval(&events_and_etc) if events_and_etc
    end
    alias :workflow_state :state
    
    def event(name, args = {}, &action)
      @scoped_state.events[name.to_sym] =
        Event.new(name, args[:transitions_to], &action)
    end
    
    def on_entry(&proc)
      @scoped_state.on_entry = proc
    end
    
    def on_exit(&proc)
      @scoped_state.on_exit = proc
    end
 
    def on_transition(&proc)
      @on_transition_proc = proc
    end
  end
  
  class TransitionHalted < Exception
 
    attr_reader :halted_because
 
    def initialize(msg = nil)
      @halted_because = msg
      super msg
    end
 
  end
 
  class NoTransitionAllowed < Exception; end
 
  class State
    
    attr_accessor :name, :events, :on_entry, :on_exit
    
    def initialize(name)
      @name, @events = name, {}
    end
    
    def to_s
      "#{name}"
    end
 
    def to_sym
      name.to_sym
    end
  end
  
  class Event
    
    attr_accessor :name, :transitions_to, :action
    
    def initialize(name, transitions_to, &action)
      @name, @transitions_to, @action = name, transitions_to.to_sym, action
    end
    
  end
  
  module WorkflowClassMethods
    def self.extended(klass)
      klass.send(:class_attribute, :workflow_spec) unless klass.method_defined?(:workflow_spec)
    end
 
    def workflow(&specification)
      unless const_defined?(:WorkflowMethods, false)
        const_set(:WorkflowMethods, Module.new)
      end
      workflow_methods = const_get(:WorkflowMethods, false)
      self.workflow_spec ||= Specification.new
      self.workflow_spec.add(&specification)
      self.workflow_spec.states.values.each do |state|
        state_name = state.name
        workflow_methods.module_eval do
          define_method "#{state_name}?" do
            state_name == current_state.name
          end
        end
 
        state.events.values.each do |event|
          event_name = event.name
          workflow_methods.module_eval do
            define_method "#{event_name}!".to_sym do |*args|
              process_event!(event_name, *args)
            end
            # INSTRUCTURE: 
            define_method "#{event_name}".to_sym do |*args|
              process_event(event_name, *args)
            end
          end
        end
      end

      include workflow_methods
    end
  end
 
  module WorkflowInstanceMethods
    def current_state
      loaded_state = load_workflow_state
      res = spec.states[loaded_state.to_sym] if loaded_state
      res || spec.initial_state
    end
    
    def state
      current_state.to_sym
    end
 
    def halted?
      @halted
    end
 
    def halted_because
      @halted_because
    end

    # INSTRUCTURE: 
    def process_event(name, *args)
      success = true
      begin
        process_event!(name, *args)
      rescue NoTransitionAllowed
        @halted = true
        @halted_because = $!
        success = false
      end
      success
    end
    
    def process_event!(name, *args)
      event = current_state.events[name.to_sym]
      raise NoTransitionAllowed.new(
        "There is no event #{name.to_sym} defined for the #{current_state} state") \
        if event.nil?
      @halted_because = nil
      @halted = false
      @raise_exception_on_halt = false
      return_value = run_action(event.action, *args) || run_action_callback("do_#{event.name}", *args)
      if @halted
        if @raise_exception_on_halt
          raise TransitionHalted.new(@halted_because)
        else
          false
        end
      else
        run_on_transition(current_state, spec.states[event.transitions_to], name, *args)
        transition(current_state, spec.states[event.transitions_to], name, *args)
        return_value
      end
    end
 
    private
 
    def spec
      self.class.workflow_spec
    end
 
    def halt(reason = nil)
      @halted_because = reason
      @halted = true
      @raise_exception_on_halt = false
    end
 
    def halt!(reason = nil)
      @halted_because = reason
      @halted = true
      @raise_exception_on_halt = true
    end
 
    def transition(from, to, name, *args)
      run_on_exit(from, to, name, *args)
      persist_workflow_state to.to_s
      run_on_entry(to, from, name, *args)
    end
 
    def run_on_transition(from, to, event, *args)
      instance_exec(from.name, to.name, event, *args, &spec.on_transition_proc) if spec.on_transition_proc
    end
 
    def run_action(action, *args)
      instance_exec(*args, &action) if action
    end
 
    def run_action_callback(action_name, *args)
      self.send action_name.to_sym, *args if self.respond_to?(action_name.to_sym)
    end
 
    def run_on_entry(state, prior_state, triggering_event, *args)
      instance_exec(prior_state.name, triggering_event, *args, &state.on_entry) if state.on_entry
    end
 
    def run_on_exit(state, new_state, triggering_event, *args)
      instance_exec(new_state.name, triggering_event, *args, &state.on_exit) if state and state.on_exit
    end
 
    # load_workflow_state and persist_workflow_state
    # can be overriden to handle the persistence of the workflow state.
    #
    # Default (non ActiveRecord) implementation stores the current state
    # in a variable.
    #
    # Default ActiveRecord implementation uses a 'workflow_state' database column.
    def load_workflow_state
      @workflow_state if instance_variable_defined? :@workflow_state
    end
 
    def persist_workflow_state(new_value)
      @workflow_state = new_value
    end
  end
 
  module ActiveRecordInstanceMethods
    def load_workflow_state
      read_attribute(:workflow_state)
    end
 
    # On transition the new workflow state is immediately saved in the
    # database.
    def persist_workflow_state(new_value)
      update_attribute :workflow_state, new_value
    end
 
    private
 
    # Motivation: even if NULL is stored in the workflow_state database column,
    # the current_state is correctly recognized in the Ruby code. The problem
    # arises when you want to SELECT records filtering by the value of initial
    # state. That's why it is important to save the string with the name of the
    # initial state in all the new records.
    def write_initial_state
      write_attribute :workflow_state, current_state.to_s
    end
  end
 
  def self.included(klass)
    klass.send :include, WorkflowInstanceMethods
    klass.extend WorkflowClassMethods
    if klass < ActiveRecord::Base
      klass.send :include, ActiveRecordInstanceMethods
      klass.before_validation :write_initial_state
    end
  end
end
 
