#
# Copyright (C) 2013 Instructure, Inc.
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

class ProgressRunner
  attr_reader :progress, :completed_count, :failed_count, :errors

  # Initialize the ProgressRunner
  # @param progress [Progress] The Progress record to update during {#do_batch_update}
  def initialize(progress)
    @progress = progress
    @completed_count = @failed_count = 0
    @errors = {}
    @completed_message = method(:default_completed_message)
    @error_message = method(:default_error_message)
  end

  # Process a list of elements, periodically updating the Progress record and finalizing it when
  # processing is complete. If processing raises exceptions, the exception messages are recorded
  # as error messages and recorded in the Progress object.
  #
  # @param elements [Array] The collection of elements to process
  # @param process_element A block that performs the actually processing on each element. 
  #   Passed an individual element as a parameter.
  def do_batch_update(elements, &process_element)
    raise 'block required' unless block_given?

    @progress.start!
    update_every = [elements.size / 20, 4].max
    elements.each_slice(update_every) do |batch|
      update_batch(batch, &process_element)
      @progress.calculate_completion!(@completed_count + @failed_count, elements.size)
    end
    finish_update
  rescue => e
    @progress.message = e.message
    @progress.fail!
    @progress.save
  end

  # Provide a custom "X items processed" message. The provided block overrides the default.
  # @param block The block to call to format the completed message.
  # @see #default_completed_message
  def completed_message(&block)
    raise 'block required' unless block_given?
    @completed_message = block
    self
  end

  # Provide a custom error message formatter. The provided block overrides the default
  # @param block The block to call to format an error message. See #default_error_message
  def error_message(&block)
    raise 'block required' unless block_given?
    @error_message = block
    self
  end

  # The default completed message.
  # @param [Integer] completed_count The number of items that were processed successfully.
  def default_completed_message(completed_count)
    I18n.t('lib.progress_runner.completed_message', {
        :one => "1 item processed",
        :other => "%{count} items processed"
      },
      :count => completed_count)
  end

  # The default error message formatter.
  # @param message [String] The error message that was encountered for the specified elements.
  # @param elements [Array] A list of elements this error message applies to.
  def default_error_message(message, elements)
    I18n.t('lib.progress_runner.error_message', "%{error}: %{ids}", :error => message, :ids => elements.join(', '))
  end

private

  def update_batch(batch, &process_element)
    batch.each do |element|
      update_element(element, &process_element)
    end
  end

  def update_element(element, &process_element)
    process_element.call(element)
    @completed_count += 1
  rescue => e
    (@errors[e.message] ||= []) << element
    @failed_count += 1
  end

  def finish_update
    @progress.completion = 100.0
    @progress.message = @completed_message.call(@completed_count)
    @errors.each do |message, elements|
      @progress.message += "\n" + @error_message.call(message, elements)
    end
    @completed_count > 0 ? @progress.complete! : @progress.fail!
    @progress.save
  end
end
