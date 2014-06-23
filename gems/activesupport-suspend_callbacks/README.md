Suspend Callbacks
=================

ActiveSupport's Callbacks module allows you to define a callback hook
and then register methods to be run before/after/around that hook.

It also let's you skip callbacks in a specific context. For example,
ActiveRecord::Base defines a callback hook around save. My top level
Person model may register an :ensure_privacy method to run before save.
But the Celebrity model that inherits from Person can then skip that
callback. End result: when I save a john_doe Person object,
:ensure_privacy will run, but when I save the dhh Celebrity object, it
won't.

But what if you want to suspend callbacks, regardless of subclass, but
only for a duration of time? That's when you want to suspend callbacks.

Example
=======

class MyModel < ActiveRecord::Base
  include ActiveSupport::Callbacks::Suspension

  before :save, :expensive_callback
  after :save, :other_callback

  def expensive_callback
    # stuff
  end

  def other_callback
    # stuff
  end
end

instance1 = MyModel.new
instance2 = MyModel.new

MyModel.suspend_callbacks do
  # neither callback will run for either instance
  instance1.save
  instance2.save
end

MyModel.suspend_callbacks(kind: :save) do
  # same
  instance1.save
  instance2.save
end

MyModel.suspend_callbacks(:expensive_callback) do
  # expensive_callback won't run, but other_callback will
  instance1.save
  instance2.save
end

MyModel.suspend_callbacks(type: :before) do
  # same
  instance1.save
  instance2.save
end

instance1.suspend_callbacks do
  # callbacks won't run this time...
  instance1.save

  # ... but they will this time.
  instance2.save
end
