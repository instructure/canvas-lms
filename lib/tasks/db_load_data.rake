Dir.glob("#{File.dirname(__FILE__)}/../../spec/factories/*.rb").each { |file| require file }

def ping
  STDOUT.sync = true
  print '.'
end
  
def create_notification(context, type, delay, link, txt, sms="")
  ping
  Canvas::MessageHelper.create_notification(context, type, delay, link, txt, sms="")
end

def create_scribd_mime_type(ext, name)
  ScribdMimeType.find_or_create_by_extension_and_name(ext, name)
end

namespace :db do
  desc "Generate security.yml key"
  task :generate_security_key do
    security_conf_path = File.expand_path(File.join(RAILS_ROOT, 'config', 'security.yml'))
    security_conf = YAML.load_file(security_conf_path)
    if security_conf[RAILS_ENV]["encryption_key"].to_s.length < 20
      security_conf[RAILS_ENV]["encryption_key"] = ActiveSupport::SecureRandom.hex(64)
      File.open(security_conf_path, 'w') { |f| YAML.dump(security_conf, f) }
    end
  end

  desc "Load environment"
  task :load_environment => [:generate_security_key, :environment] do
    raise "Please configure domain.yml" unless HostUrl.default_host
  end

  desc "Resets the encryption_key hash in the database. Needed if you change the encryption_key"
  task :reset_encryption_key_hash do
    ENV['UPDATE_ENCRYPTION_KEY_HASH'] = "1"
    Rake::Task['db:load_environment'].invoke
  end

  desc "Make sure all scribd mime types are set up correctly"
  task :ensure_scribd_mime_types => :load_environment do
    ping
    create_scribd_mime_type('doc', 'application/msword')
    ping
    create_scribd_mime_type('ppt', 'application/vnd.ms-powerpoint')
    ping
    create_scribd_mime_type('pdf', 'application/pdf')
    ping
    create_scribd_mime_type('xls', 'application/vnd.ms-excel')
    ping
    create_scribd_mime_type('ps', 'application/postscript')
    ping
    create_scribd_mime_type('rtf', 'application/rtf')
    ping
    create_scribd_mime_type('rtf', 'text/rtf')
    ping
    create_scribd_mime_type('docx', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document')
    ping
    create_scribd_mime_type('pptx', 'application/vnd.openxmlformats-officedocument.presentationml.presentation')
    ping
    create_scribd_mime_type('xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
    ping
    create_scribd_mime_type('ppt', 'application/mspowerpoint')
    ping
    create_scribd_mime_type('xls', 'application/excel')
    ping
    create_scribd_mime_type('txt', 'text/plain')
    ping
    create_scribd_mime_type('odt', 'application/vnd.oasis.opendocument.text')
    ping
    create_scribd_mime_type('odp', 'application/vnd.oasis.opendocument.presentation')
    ping
    create_scribd_mime_type('ods', 'application/vnd.oasis.opendocument.spreadsheet')
    ping
    create_scribd_mime_type('sxw', 'application/vnd.sun.xml.writer')
    ping
    create_scribd_mime_type('sxi', 'application/vnd.sun.xml.impress')
    ping
    create_scribd_mime_type('sxc', 'application/vnd.sun.xml.calc')
    ping
    create_scribd_mime_type('xltx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.template')
    ping
    create_scribd_mime_type('ppsx', 'application/vnd.openxmlformats-officedocument.presentationml.slideshow')
    ping
    create_scribd_mime_type('potx', 'application/vnd.openxmlformats-officedocument.presentationml.template')
    ping
    create_scribd_mime_type('dotx', 'application/vnd.openxmlformats-officedocument.wordprocessingml.template')
    ping
    puts 'Scribd Mime Types added'
  end
  desc "Make sure all message templates have notifications in the db"
  task :evaluate_notification_templates => :load_environment do
    Dir.glob(File.join(RAILS_ROOT, 'app', 'messages', '*.erb')) do |filename|
      filename = File.split(filename)[1]
      name = filename.split(".")[0]
      unless name[0,1] == "_"
        titled = name.titleize.gsub(/Sms/, 'SMS')
        puts "No notification found in db for #{name}" unless Notification.find_by_name(titled)
      end
    end
    Notification.all.each do |n|
      puts "No notification files found for #{n.name}" if Dir.glob(File.join(RAILS_ROOT, 'app', 'messages', "#{n.name.downcase.gsub(/\s/, '_')}.*.erb")).empty?
    end
  end
  
  desc "Find or create the notifications"
  task :load_notifications => :load_environment do 
    Notification.reset_column_information

    create_notification 'Announcement', 'Announcement', 0,
      'http://<%= HostUrl.context_host(asset.context) %>/<%= asset.context.class.to_s.downcase.pluralize %>/<%= asset.context_id %>/announcements', %{
      New Announcement
      
      <%= asset.title %>: <%= asset.context.name %>
      
      <%= strip_and_truncate(asset.message, :max_length => 500) %> 
      
      
      <%= main_link %>
    }, %{
      <%= strip_and_truncate(asset.message, :max_length => 200) %>
    }
    
    create_notification 'AccountUser', 'Other', 0,
    'http://<%= HostUrl.default_host %>', %{
      New Account User
      
      New Account Admin for <%= asset.account.name %>
      
      A new admin, <%= asset.user.name %>, has been added for the account <%= asset.account.name %>
    }, %{
      A new admin, <%= asset.user.name %>, has been added for the account <%= asset.account.name %>
    }
    
    create_notification 'Course', 'Other', 0,
    'http://<%= HostUrl.default_host %>', %{
      New Course
      
      New Course for <%= asset.root_account.name %>
      
      A new course, <%= asset.name %>, has been added for the account <%= asset.root_account.name %>
    }, %{
      A new course, <%= asset.name %>, has been added for the account <%= asset.root_account.name %>
    }
    
    create_notification 'StudentReports', 'Other', 0,
    'http://<%= HostUrl.default_host %>', %{
      Report Generated

      Report Generated
      
      Report generated successfully
    }, %{
      Report generated successfully
    }
    
    create_notification 'StudentReports', 'Other', 0,
    'http://<%= HostUrl.default_host %>', %{
      Report Generation Failed

      Report Generation Failed
      
      Report generation failed
    }, %{
      Report generation failed
    }
    
    create_notification 'ContentMigration', 'Migration', 0,
    'http://<%= HostUrl.default_host %>', %{
      Migration Export Ready

      Course Extraction Ready: <%= asset.migration_settings[:course_name] %>
      
      The extraction process for the course, <%= asset.migration_settings[:course_name] %>, has completed.  To finish importing content into <%= asset.context.name %> you'll need to click the following link:
    }, %{
      The extraction process for the course, <%= asset.migration_settings[:course_name] %>, has completed.  To finish importing content into <%= asset.context.name %> you'll need to click the following link:
    }
    
    create_notification 'ContentMigration', 'Migration', 0,
    'http://<%= HostUrl.default_host %>', %{
      Migration Import Finished

      Course Import Finished: <%= asset.context.name %>
      
      Importing <%= asset.migration_settings[:course_name] %> into <%= asset.context.name %> has finished.
    }, %{
      Importing <%= asset.migration_settings[:course_name] %> into <%= asset.context.name %> has finished.
    }
      
    create_notification 'ContentMigration', 'Migration', 0,
    'http://<%= HostUrl.default_host %>', %{
      Migration Import Failed

      Course Import Failed: <%= asset.context.name %>
      
      There was a problem importing <%= asset.migration_settings[:course_name] %> into <%= asset.context.name %>.  Please notify your system administrator, and give them the following error code: "ContentMigration:<%= asset.id %>:<%= asset.progress %>".
    }, %{
      There was a problem importing <%= asset.migration_settings[:course_name] %> into <%= asset.context.name %>.  Please notify your system administrator, and give them the following error code: "ContentMigration:<%= asset.id %>:<%= asset.progress %>".
    }
    
    create_notification 'ContentExport', 'Migration', 0,
    'http://<%= HostUrl.default_host %>', %{
      Content Export Finished

      Course Export Finished: <%= asset.context.name %>
      
      Your course export for "<%= asset.context.name %>" has finished.
    }, %{
      Your course export for "<%= asset.context.name %>" has finished.
    }
    
    create_notification 'ContentExport', 'Migration', 0,
    'http://<%= HostUrl.default_host %>', %{
      Content Export Failed

      Course Export failed: <%= asset.context.name %>
      
      There was a problem exporting the course "<%= asset.context.name %>".
    }, %{
      There was a problem exporting the course "<%= asset.context.name %>".
    }

    create_notification 'User', 'Other', 0,
    'http://<%= HostUrl.default_host %>', %{
      New User
      
      New Instructure User %>
      
      A new user, <%= asset.name %>, just registered for the account <%= asset.account.name rescue nil %>
    }, %{
      A new user, <%= asset.name %>, just registered for the account <%= asset.account.name rescue nil %>
    }
    
    create_notification 'User', 'Other', 0,
    'http://<%= HostUrl.default_host %>', %{
      New Teacher Registration
      
      New Teacher Registration
      
      A new teacher, <%= asset.name %>, just registered at Instructure
    }, %{
      A new teacher, <%= asset.name %>, just registered at Instructure
    }
    
    create_notification 'Assignment', 'Due Date', 5*60, 
    'http://<%= HostUrl.context_host(asset.context) %>/<%= asset.context.class.to_s.downcase.pluralize %>/<%= asset.context_id %>/assignments/<%= asset.id %>', %{
      Assignment Due Date Changed
      
      Assignment Due Date Changed: <%= asset.title %>, <%= asset.context.name %>
      
      The due date for the assignment, <%= asset.title %>, for the course, <%= asset.context.name %> has changed to:
      
      <%= asset.due_at.strftime("%b %d at %I:%M") rescue "No Due Date" %><%= asset.due_at.strftime("%p").downcase rescue "" %>
      
      
      Click here to view the assignment: 
      <%= main_link %>
    }, %{
      <%= asset.title %>, <%= asset.context.name %>, is now due:
      <%= asset.due_at.strftime("%b %d at %I:%M") rescue "No Due Date" %><%= asset.due_at.strftime("%p").downcase rescue "" %>
    }

    create_notification 'AssignmentOverride', 'Due Date', 5*60,
                        'http://<%= HostUrl.context_host(asset.assignment.context) %>/<%= asset.assignment.context.class.to_s.downcase.pluralize %>/<%= asset.assignment.context_id %>/assignments/<%= asset.assignment.id %>', %{
      Assignment Due Date Override Changed

      Assignment Due Date Changed: <%= asset.assignment.title %>, <%= asset.assignment.context.name %> (<%= asset.title %>)

      The due date for the assignment, <%= asset.assignment.title %>, for the course, <%= asset.assignment.context.name %> (<%= asset.title %>) has changed to:

      <%= asset.due_at.strftime("%b %d at %I:%M") rescue "No Due Date" %><%= asset.due_at.strftime("%p").downcase rescue "" %>


      Click here to view the assignment:
      <%= main_link %>
    }, %{
      <%= asset.assignment.title %>, <%= asset.assignment.context.name %> (<%= asset.title %>, is now due:
      <%= asset.due_at.strftime("%b %d at %I:%M") rescue "No Due Date" %><%= asset.due_at.strftime("%p").downcase rescue "" %>
    }

    create_notification 'Assignment', 'Course Content', 30*60, 
    'http://<%= HostUrl.context_host(asset.context) %>/<%= asset.context.class.to_s.downcase.pluralize %>/<%= asset.context_id %>/assignments/<%= asset.id %>', %{
      Assignment Changed
      
      Assignment Changed: <%= asset.title %>, <%= asset.context.name %>
      
      The assignment, <%= asset.title %>, for the course, <%= asset.context.name %>, has changed.  
      
      Click here to view the assignment: 
      <%= main_link %>
    }, %{
      <%= asset.title %>, <%= asset.context.name %> has changed.
    }
    
    create_notification 'Assignment', 'Due Date', 0, 
    'http://<%= HostUrl.context_host(asset.context) %>/<%= asset.context.class.to_s.downcase.pluralize %>/<%= asset.context_id %>/assignments/<%= asset.id %>', %{
      Assignment Created
      
      Assignment Created - <%= asset.title %>: <%= asset.context.name %>
      
      A new assignment has been created for your course, <%= asset.context.name %>
      
      <%= asset.title %> 
      
      due: <%= asset.due_at.strftime("%b %d at %I:%M") rescue "No Due Date" %><%= asset.due_at.strftime("%p").downcase rescue "" %> 
      
      Click here to view the assignment: 
      <%= main_link %>
    }, %{
      New Assignment for <%= asset.context.name %>:
      <%= asset.title %>
      
      due: <%= asset.due_at.strftime("%b %d at %I:%M") rescue "No Due Date" %><%= asset.due_at.strftime("%p").downcase rescue "" %> 
    }
    
    create_notification 'Course', 'Grading Policies', 5*60, 
    'http://<%= HostUrl.context_host(asset) %>/<%= asset.class.to_s.downcase.pluralize %>/<%= asset.id %>/assignments', %{
      Grade Weight Changed
      
      Grade Weight Changed: <%= asset.name %>
      
      The grading policy for <%= asset.name %> has changed.  
      
      You can see details here: 
      <%= main_link %>
    }, %{
      <%= asset.name %> grading policy has changed.
    }
    
    create_notification 'Assignment', 'Grading', 15*60, 
    'http://<%= HostUrl.context_host(asset.context) %>/<%= asset.context.class.to_s.downcase.pluralize %>/<%= asset.context_id %>/assignments/<%= asset.id %>', %{
      Assignment Graded
      
      Assignment Graded: <%= asset.title %>, <%= asset.context.name %>
      
      Your assignment, <%= asset.title %>, has been graded.  
      
      You can view it here: 
      <%= main_link %>
    }, %{
      <%= asset.title %>, <%= assset.context.name %> has been graded.
    }

    create_notification 'Assignment', 'Grading', 0, 
    'http://<%= HostUrl.context_host(asset.context) %>/<%= asset.context.class.to_s.downcase.pluralize %>/<%= asset.context_id %>/assignments/<%= asset.id %>', %{
      Assignment Unmuted

      Assignment Unmuted: <%= asset.title %>, <%= asset.context.name %>

      Your instructor has released grade changes and new comments for %{title}. These changes are now viewable.

      Your can view it here:
      %{url}
    }, %{
      <%= asset.title %>, <%= asset.context.name %>  has been unmuted.
    }

    create_notification 'CalendarEvent', 'Calendar', 0,
    'http://<%= HostUrl.context_host(asset.context) %>/<%= asset.context.class.to_s.downcase.pluralize %>/<%= asset.context_id %>/calendar_events/<%= asset.id %>', %{
      New Event Created
      
      New Event - <%= asset.title %>: <%= asset.context.name %>
      
      There's a new event scheduled for <%= asset.context.name %> that you should be aware of:
      
      <%= asset.title %> 
      
      <% if (asset.start_at == asset.end_at || !asset.end_at) %>
      <%= asset.start_at.strftime("%b %d at %I:%M") rescue "No Time Set" %><%= asset.start_at.strftime("%p").downcase rescue "" %> 
      
      <% else %>
      from <%= asset.start_at.strftime("%b %d %I:%M") rescue "No Time Set" %><%= asset.start_at.strftime("%p").downcase rescue "" %> 
      
      to <%= asset.end_at.strftime("%b %d %I:%M") rescue "No Time Set" %><%= asset.end_at.strftime("%p").downcase rescue "" %> 
      
      <% end %>
      
      You can see details here: 
      <%= main_link %>
    }, %{
      New event for <%= asset.contex.name: %>
      
      <%= asset.title %>
      
      <% if (asset.start_at == asset.end_at || !asset.end_at) %>
      <%= asset.start_at.strftime("%b %d at %I:%M") rescue "No Time Set" %><%= asset.start_at.strftime("%p").downcase rescue "" %> 
      
      <% else %>
      from <%= asset.start_at.strftime("%b %d %I:%M") rescue "No Time Set" %><%= asset.start_at.strftime("%p").downcase rescue "" %> 
      
      to <%= asset.end_at.strftime("%b %d %I:%M") rescue "No Time Set" %><%= asset.end_at.strftime("%p").downcase rescue "" %> 
      
      <% end %>
    }
    
    create_notification 'CalendarEvent', 'Calendar', 15*60,
    'http://<%= HostUrl.context_host(asset.context) %>/<%= asset.context.class.to_s.downcase.pluralize %>/<%= asset.context_id %>/calendar_events/<%= asset.id %>', %{
      Event Date Changed
      
      Event Date Changed: <%= asset.title %>, <%= asset.context.name %>
      
      The event, <%= asset.title %>, for the course, <%= asset.context.name %> has changed times.  It's now:
      <% if (asset.start_at == asset.end_at || !asset.end_at) %>
      <%= asset.start_at.strftime("%b %d at %I:%M") rescue "No Time Set" %><%= asset.start_at.strftime("%p").downcase rescue "" %> 
      
      <% else %>
      from <%= asset.start_at.strftime("%b %d %I:%M") rescue "No Time Set" %><%= asset.start_at.strftime("%p").downcase rescue "" %> 
      
      to <%= asset.end_at.strftime("%b %d %I:%M") rescue "No Time Set" %><%= asset.end_at.strftime("%p").downcase rescue "" %> 
      
      <% end %>
      
      You can see details here: 
      <%= main_link %>
    }, %{
      <%= asset.title %>, <%= asset.context.name %> changed to:
      
      <% if (asset.start_at == asset.end_at || !asset.end_at) %>
      <%= asset.start_at.strftime("%b %d at %I:%M") rescue "No Time Set" %><%= asset.start_at.strftime("%p").downcase rescue "" %> 
      
      <% else %>
      from <%= asset.start_at.strftime("%b %d %I:%M") rescue "No Time Set" %><%= asset.start_at.strftime("%p").downcase rescue "" %> 
      
      to <%= asset.end_at.strftime("%b %d %I:%M") rescue "No Time Set" %><%= asset.end_at.strftime("%p").downcase rescue "" %> 
      
      <% end %>
    }
    
    create_notification 'Collaborator', 'Invitation', 0,
    'http://<%= HostUrl.context_host(asset.collaboration.context) %>/<%= asset.collaboration.context.class.to_s.downcase.pluralize %>/<%= asset.collaboration.context_id %>/collaborations', %{
      Collaboration Invitation
      
      Collaboration Invitation: <%= asset.collaboration.context.name %>
      
      You've been invited to collaborate on a document, <%= asset.collaboration.title %> for 
      <%= asset.collaboration.context.name %>.  The document was created 
      <% if asset.collaboration.user %> by <%= asset.collaboration.user.name %><% end %>
      in <%= asset.collaboration.service_name %>
      and you were invited using your email address, <%= asset.user.gmail %>.  
      
      If that's the wrong email address for this type of collaboration, you'll need to 
      change your profile settings or register with <%= asset.collaboration.service_name %>.
      
      You can see the details here:
      <%= main_link %>
    }, %{
      You were invited to collaborate on a document, <%= asset.collaboration.title %> for
      <%= asset.collaboration.context.name %>.  Visit <%= HostUrl.default_host %> for more details.
    }
    
    create_notification 'WebConference', 'Invitation', 0, 
    'http://<%= HostUrl.context_host(asset.context) %>/<%= asset.context.class.to_s.downcase.pluralize %>/<%= asset.context_id %>/conferences', %{
      Web Conference Invitation
      
      Web Conference Invitation: <%= asset.context.name %>
      
      You've been invited to participate in a web conference, <%= asset.title %> for 
      <%= asset.context.name %>.
      
      You can see the details here:
      <%= main_link %>
    }, %{
      You were invited to join a web conference, <%= asset.title %> for
      <%= asset.context.name %>.  Visit <%= HostUrl.default_host %> for more details.
    }
    
    create_notification 'CommunicationChannel', 'Registration', 0,
    'http://<%= HostUrl.context_host(asset.context) %>/pseudonyms/<%= asset.pseudonym_id %>/claim/<%= asset.confirmation_code %>', %{
      Confirm Email Communication Channel
      
      Confirm Email: Instructure
      
      The email address, <%= asset.path %> is being registered at Instructure for the user, <%= asset.user.name %>.
      
      To confirm this registration, please visit the following url: 
      <%= main_link %>
    }, ""
    
    create_notification 'CommunicationChannel', 'Registration', 0,
    'http://<%= HostUrl.context_host(asset.context) %>/communication_channels/<%= asset.id %>/merge/<%= asset.confirmation_code %>', %{
      Merge Email Communication Channel
      
      Claim Email: Instructure
      
      Someone is requesting the use of this email address, <%= asset.path %>, for
      their account at Instructure.  Right now this address is being used by
      <%= asset.user.name %> (id: <%= asset.user_id).
      
      If you would like to assign this email address to a different user, please visit the following url:
      <%= main_link %>
    }, ""
    
    create_notification 'CommunicationChannel', 'Registration', 0,
    'no link available', %{
      Confirm SMS Communication Channel
      
      Confirm SMS: Instructure
      
      This address is being registered at <%= HostUrl.default_host %> for the user, <%= asset.user.name %>.  Enter the code:
      
      <%= asset.confirmation_code %>
      
      at <%= HostUrl.default_host %> to confirm this account.
    }, %{
      Confirm SMS Communication Channel
      
      Confirm SMS: Instructure
      
      This address is being registered at <%= HostUrl.default_host %> for the user, <%= asset.user.name %>.  Enter the code:
      
      <%= asset.confirmation_code %>
      
      at <%= HostUrl.default_host %> to confirm this account.
    }
    
    create_notification 'Pseudonym', 'Registration', 0,
    'http://<%= HostUrl.default_host %>/pseudonyms/<%= asset.pseudonym_id %>/change_password/<%= asset.confirmation_code %>', %{
      Pseudonym Registration
      
      Registration: Instructure Canvas
      
      You have been registered for a new login at Instructure.
      
      To finish the registration process, please visit the following url: 
      <%= main_link %>
    }
    
    registration_note = create_notification 'CommunicationChannel', 'Registration', 0,
    "http://<%= HostUrl.default_host %>/pseudonyms/<%= asset.pseudonym_id %>/register/<%= asset.confirmation_code %>", %{
      Confirm Registration
      
      Confirm Registration: Instructure
      
      Thank you for registering with Instructure!  This email is confirmation that the user, <%= asset.user.name %> is registering for a new account at <%= HostUrl.default_host %>.
      
      To finish the registration process, please visit the following url: 
      <%= main_link %>
    }
    
    registration_note.update_attribute(:delay_for, 0)
    
    create_notification 'CommunicationChannel', 'Registration', 0,
    'http://<%= HostUrl.default_host %>/pseudonyms/<%= asset.pseudonym_id %>/change_password/<%= asset.confirmation_code %>', %{
      Forgot Password
      
      Forgot Password: Instructure
      
      You requested a confirmation of your password for this address at <%= HostUrl.default_host %>.
      
      To set a new password, please click the following link:
      <%= main_link %>
    }
    
    create_notification 'DiscussionTopic', 'Discussion', 0,
    'http://<%= HostUrl.context_host(asset.context) %>/<%= asset.context.class.to_s.downcase.pluralize %>/<%= asset.context_id %>/discussion_topics/<%= asset.id %>', %{
      New Discussion Topic
      
      New Discussion - <%= asset.title %>: <%= asset.context.name %>
      
      A new discussion topic has been started that may be interesting to you:
      
      <%= asset.title %> 
      
      <%= strip_and_truncate(asset.message, :max_length => 200) %> 
      
      
      Join to the conversation here: 
      <%= main_link %>
    }, %{
      New Topic for <%= asset.context.name %>:
      
      <%= asset.title %>
      
      <%= strip_and_truncate(asset.message, :max_length => 200) %>
    }

    create_notification 'DiscussionEntry', 'DiscussionEntry', 0,
    'http://<%= HostUrl.context_host(asset.context) %>/<%= asset.context.class.to_s.downcase.pluralize %>/<%= asset.context_id %>/discussion_topics/<%= asset.discussion_topic_id %>', %{
      New Discussion Entry
      
      New Comment for <%= asset.discussion_topic.title %>: <%= asset.context.name %>
      
      <%= asset.user.short_name just commented on the topic <%= asset.discussion_topic.title %> for <%= asset.context.name %>:
      
      <%= strip_and_truncate(asset.message, :max_length => 200) %> 
      
      Join to the conversation here: 
      <%= main_link %>
    }, %{
      New Comment for <%= asset.discussion_topic.title %>, <%= asset.context.name %>:
      
      <%= strip_and_truncate(asset.message, :max_length => 200) %>
    }

    create_notification 'AccountUser', 'Registration', 0,
    '<% cc = asset.user.communication_channel %>http://<%= HostUrl.context_host(asset.account) %>/pseudonyms/<%= cc.pseudonym_id %>/register/<%= cc.confirmation_code %>', %{
      Account User Registration
      
      Account Admin Notification
      
      You've been added as an <%= asset.readable_type %> to the account <%= asset.account.name %> at <%= HostUrl.context_host(asset.account) %>.  First you'll need to finish the registration process.
      
      You can finish regsitering your account here:
      <%= main_link %>
    }, %{
      You've been added as an <%= asset.readable_type %> to the account <%= asset.account.name %> at <%= HostUrl.context_host(asset.account) %>
    }

    create_notification 'AccountUser', 'Registration', 0,
    'http://<%= HostUrl.context_host(asset.account) %>/accounts/<%= asset.account_id %>', %{
      Account User Notification
      
      Account Admin Notification
      
      You've been added as an <%= asset.readable_type %> to the account <%= asset.account.name %> at <%= HostUrl.context_host(asset.account) %>
      
      Visit the account page here:
      <%= main_link %>
    }, %{
      You've been added as an <%= asset.readable_type %> to the account <%= asset.account.name %> at <%= HostUrl.context_host(asset.account) %>
    }

    create_notification 'Enrollment', 'Registration', 0,
    'http://<%= HostUrl.context_host(asset.context) %>/<%= asset.context.class.to_s.downcase.pluralize %>/<%= asset.context_id %>?invitation=<%= asset.uuid %>', %{
      Enrollment Invitation
      
      <%= asset.context.class.to_s.capitalize %> Invitation
      
      You've been invited to participate in the <%= asset.context.class.to_s.downcase %>, <%= asset.context.name %>, as a <%= asset.readable_type %>.
      
      Visit the <%= asset.context.class.to_s.downcase %> page here:
      <%= main_link %>
    }, %{
      You've been invited to the <%= asset.context.class.to_s.downcase %> as
      a <%= asset.readable_type %>.  Visit <%= HostUrl.default_host %> for more details.
    }
    
    create_notification 'Enrollment', 'Registration', 0,
    'http://<%= HostUrl.context_host(asset.context) %>/<%= asset.context.class.to_s.downcase.pluralize %>/<%= asset.context_id %>?invitation=<%= asset.uuid %>', %{
      Enrollment Registration
      
      <%= asset.context.class.to_s.capitalize %> Invitation
      
      You've been invited to participate in a class at <%= HostUrl.default_host %>.  The class is
      called <%= asset.context.name %>, and you've been invited to
      participate as a <%= asset.readable_type %>.
      
      Visit the <%= asset.context.class.to_s.downcase %> page here:
      <%= main_link %>
    }, %{
      You've been invited to the <%= asset.context.class.to_s.downcase %> as
      a <%= asset.readable_type %>.  Visit <%= HostUrl.default_host %> for more details.
    }

    create_notification 'Enrollment', 'Registration', 0,
    'http://<%= HostUrl.context_host(asset.context) %>/<%= asset.context.class.to_s.downcase.pluralize %>/<%= asset.context_id %>', %{
      Enrollment Notification
      
      <%= asset.context.class.to_s.capitalize %> Enrollment
      
      You've been enrolled in the <%= asset.context.class.to_s.downcase %>, <%= asset.context.name %> as a <%= asset.readable_type %>
      
      Visit the <%= asset.context.class.to_s.downcase %> page here:
      <%= main_link %>
    }, %{
      You've been enrolled in the <%= asset.context.class.to_s.downcase %> as
      a <%= asset.readable_type %>.  Visit <%= HostUrl.default_host %> for more details.
    }
    
    create_notification 'Enrollment', 'Membership Update', 0,
    'http://<%= HostUrl.context_host(asset.course) %>/<%= asset.course.class.to_s.downcase.pluralize %>/<%= asset.course_id %>/details', %{
      Enrollment Accepted
      
      <%= asset.user.name %> accepted the <%= asset.course.class.to_s.capitalize %> Invitation
      
      <%= asset.user.name %> just accepted their invitation to participate in the <%= asset.course.class.to_s.downcase %>, <%= asset.course.name %>, as a <%= asset.readable_type %>.

      See the list of current enrollments here:
      <%= main_link %>
    }, %{
      <%= asset.user.name %> accepted the <%= asset.readable_type %> invitation for the <%= asset.course.class.to_s.downcase %>, <%= asset.course.name %>
    }

    create_notification 'ConversationMessage', 'Conversation Message', 0,
    'http://<%= HostUrl.context_host(asset.context) %>/<%= asset.context.class.to_s.downcase.pluralize %>/<%= asset.context_id %>', %{
      Conversation Message
      
      New Message from <%= user.name rescue 'Unknown User' %>
      
      <%= user.name rescue 'Unknown User' %> just sent you a message in Canvas:
      
      <%= asset.body %>
      
      <%= main_link %>
    }, %{
      <%= user.name rescue 'Unknown User' %> just sent you a message:
      
      <%= strip_and_truncate(asset.body, :max_length => 50) %>
    }

    create_notification 'AddedToConversation', 'Added To Conversation', 0, 'http://<%= HostUrl.default_host %>', %{
      Added To Conversation
      
      Added to a conversation by <%= user.name rescue 'Unknown User' %>
      
      <%= user.name rescue 'Unknown User' %> just added you to a conversation in Canvas.
      
      <%= main_link %>
    }

    create_notification 'GroupMembership', 'Membership Update', 0,
    'http://<%= HostUrl.context_host(asset.group.context) %>/<%= asset.group.context.class.to_s.downcase.pluralize %>/<%= asset.context_id %>/groups', %{
      New Context Group Membership
      
      New Group Membership: <%= asset.group.name %>
      
      You've been added to a new group for the <%= asset.group.context.class.to_s.downcase %> <%= asset.group.context.name %>.  The name of the group is <%= asset.group.name %>.
      
      You can see your group memberships for this <%= asset.group.context.class.to_s.downcase %> by clicking the link below:
      <%= main_link %>
    }, %{
      You've been added to a new group for the <%= asset.group.context.class.to_s.downcase %> <%= asset.group.context.name %>.  The name of the group is <%= asset.group.name %>.
    }

    create_notification 'GroupMembership', 'Invitation', 0,
    'http://<%= HostUrl.context_host(asset.group.context) %>/<%= asset.group.context.class.to_s.downcase.pluralize %>/<%= asset.context_id %>/groups', %{
      New Context Group Membership Invitation
      
      New Group Membership: <%= asset.group.name %>
      
      You've been added to a new group for the <%= asset.group.context.class.to_s.downcase %> <%= asset.group.context.name %>.  The name of the group is <%= asset.group.name %>.
      
      You can see your group memberships for this <%= asset.group.context.class.to_s.downcase %> by clicking the link below:
      <%= main_link %>
    }, %{
      You've been added to a new group for the <%= asset.group.context.class.to_s.downcase %> <%= asset.group.context.name %>.  The name of the group is <%= asset.group.name %>.
    }

    create_notification 'GroupMembership', 'Membership Update', 0,
    'http://<%= HostUrl.context_host(asset.group.context) %>/<%= asset.group.context.class.to_s.downcase.pluralize %>/<%= asset.context_id %>/groups', %{
      Group Membership Accepted
      
      New Group Membership: <%= asset.group.name %>
      
      You've been added to a new group for the <%= asset.group.context.class.to_s.downcase %> <%= asset.group.context.name %>.  The name of the group is <%= asset.group.name %>.
      
      You can see your group memberships for this <%= asset.group.context.class.to_s.downcase %> by clicking the link below:
      <%= main_link %>
    }, %{
      You've been added to a new group for the <%= asset.group.context.class.to_s.downcase %> <%= asset.group.context.name %>.  The name of the group is <%= asset.group.name %>.
    }

    create_notification 'GroupMembership', 'Membership Update', 0,
    'http://<%= HostUrl.context_host(asset.group.context) %>/<%= asset.group.context.class.to_s.downcase.pluralize %>/<%= asset.context_id %>/groups', %{
      Group Membership Rejected
      
      New Group Membership: <%= asset.group.name %>
      
      You've been added to a new group for the <%= asset.group.context.class.to_s.downcase %> <%= asset.group.context.name %>.  The name of the group is <%= asset.group.name %>.
      
      You can see your group memberships for this <%= asset.group.context.class.to_s.downcase %> by clicking the link below:
      <%= main_link %>
    }, %{
      You've been added to a new group for the <%= asset.group.context.class.to_s.downcase %> <%= asset.group.context.name %>.  The name of the group is <%= asset.group.name %>.
    }

    create_notification 'Group', 'Other', 0,
    'http://<%= HostUrl.context_host(asset.group.context) %>/<%= asset.group.context.class.to_s.downcase.pluralize %>/<%= asset.context_id %>/groups', %{
      New Student Organized Group
      
      New Student Group: <%= asset.group.name %>
      
      <%= main_link %>
    }, %{
      New student group: <%= asset.group.name %>
    }

    create_notification 'AssessmentRequest', 'Invitation', 0,
    '<%ra=asset.rubric_association%>http://<%= HostUrl.context_host(ra.context) %>/<%= ra.context.class.to_s.downcase.pluralize %>/<%= ra.context_id %>/rubrics/<%= ra.rubric_id %>', %{
      Rubric Assessment Submission Reminder
      
      Reminder to Submit Assessment: <%= asset.rubric_association.title %>, <%= asset.rubric_association.context.name %>
      
      You've been reminded to assess: <%= asset.rubric_association.title %>, <%= asset.rubric_association.context.name %>:
      
      <%= asset.rubric_association.description %>
      
      You can review the assessment and submit your entry here: 
      <%= main_link %>
    }, %{
      You've been reminded to assess: <%= asset.rubric_association.title %>, <%= asset.context.name %>.
    }

    create_notification 'AssessmentRequest', 'Invitation', 0,
    '<%ra=asset.rubric_association%>http://<%= HostUrl.context_host(ra.context) %>/<%= ra.context.class.to_s.downcase.pluralize %>/<%= ra.context_id %>/rubric_associations/<%= ra.id %>/assessments/<%= asset.uuid %>', %{
      Rubric Assessment Invitation
      
      Assessment Invitation: <%= asset.rubric_association.title %>, <%= asset.rubric_association.context.name %>
      
      You've been invited by <%= asset.user.name %> to assess their submission for <%= asset.rubric_association.title %>:
      
      <%= asset.rubric_association.description %>
      
      You can review and evaluate the entry here: 
      <%= main_link %>
    }, %{
      You've been invited by <%= asset.user.name %> to assess their submission for <%= asset.rubric_association.title %>.
    }

    create_notification 'RubricAssociation', 'Invitation', 0,
    'http://<%= HostUrl.context_host(asset.context) %>/<%= asset.context.class.to_s.downcase.pluralize %>/<%= asset.context_id %>/rubrics/<%= asset.rubric_id %>', %{
      Rubric Association Created
      
      New Assessment: <%= asset.title %>, <%= asset.context.name %>
      
      A new assessment has been created for <%= asset.context.name %>:
      
      <%= asset.title %>
      
      <%= asset.description %>
      
      You can review the assessment and submit your entry here: 
      <%= main_link %>
    }, %{
      A new assessment has been created for <%= asset.context.name %>.
    }

    create_notification 'Submission', 'All Submissions', 0,
    '<%= a = asset.assignment %>http://<%= HostUrl.context_host(a.context) %>/<%= a.context.class.to_s.downcase.pluralize %>/<%= a.context_id %>/assignments/<%= a.id %>/submissions/<%= asset.user_id %>', %{
      Assignment Submitted
      
      Submitted: <%= asset.user.name %>, <%= asset.assignment.title %>
      
      <%= asset.user.name %> has just turned in a submission for <%= asset.assignment.title %> in the course <%= asset.assignment.context.name %>. 
      
      You can view the submission here: 
      <%= main_link %>
    }, %{
      <%= asset.user.name %> just turned in their assignment (late), <%= asset.assignment.title %>
    }

    create_notification 'Submission', 'All Submissions', 0,
    '<%= a = asset.assignment %>http://<%= HostUrl.context_host(a.context) %>/<%= a.context.class.to_s.downcase.pluralize %>/<%= a.context_id %>/assignments/<%= a.id %>/submissions/<%= asset.user_id %>', %{
      Assignment Resubmitted
      
      Submitted: <%= asset.user.name %>, <%= asset.assignment.title %>
      
      <%= asset.user.name %> has just turned in a re-submission for <%= asset.assignment.title %> in the course <%= asset.assignment.context.name %>. 
      
      You can view the submission here: 
      <%= main_link %>
    }, %{
      <%= asset.user.name %> just turned in their assignment (late), <%= asset.assignment.title %>
    }

    create_notification 'Submission', 'Late Grading', 0,
    '<%= a = asset.assignment %>http://<%= HostUrl.context_host(a.context) %>/<%= a.context.class.to_s.downcase.pluralize %>/<%= a.context_id %>/assignments/<%= a.id %>/submissions/<%= asset.user_id %>', %{
      Assignment Submitted Late
      
      Late Assignment: <%= asset.user.name %>, <%= asset.assignment.title %>
      
      <%= asset.user.name %> has just turned in a late submission for <%= asset.assignment.title %> in the course <%= asset.assignment.context.name %>. 
      
      You can view the submission here: 
      <%= main_link %>
    }, %{
      <%= asset.user.name %> just turned in their assignment (late), <%= asset.assignment.title %>
    }

    create_notification 'Submission', 'Late Grading', 0,
    '<%= a = asset.assignment %>http://<%= HostUrl.context_host(a.context) %>/<%= a.context.class.to_s.downcase.pluralize %>/<%= a.context_id %>/assignments/<%= a.id %>', %{
      Group Assignment Submitted Late
      
      Late Assignment: <%= asset.group.name %>, <%= asset.assignment.title %>
      
      The group <%= asset.group.name %> has just turned in a late submission for <%= asset.assignment.title %> in the course <%= asset.assignment.context.name %>. 
      
      You can view the submission here: 
      http://<%= HostUrl.context_host(asset.assignment.context) %>/<%= asset.assignment.context.class.to_s.downcase.pluralize %>/<%= asset.assignment.context_id %>/assignments/<%= asset.assignment_id %>/submissions/<%= asset.user_id %>
    }, %{
      <%= asset.group.name %> just turned in their assignment (late), <%= asset.assignment.title %>
    }

    create_notification 'Submission', 'Grading', 60*60,
    '<%= a = asset.assignment %>http://<%= HostUrl.context_host(a.context) %>/<%= a.context.class.to_s.downcase.pluralize %>/<%= a.context_id %>/assignments/<%= a.id %>', %{
      Submission Graded
      
      Assignment Graded: <%= asset.assignment.title %>, <%= asset.assignment.context.name %>
      
      Your assignment, <%= asset.assignment.title %>, has been graded.  
      
      You can review the assignment here: 
      <%= main_link %>
    }, %{
      <%= asset.assignment.title %>, <%= asset.assignment.context.name %> has been graded.
    }

    create_notification 'SubmissionComment', 'Submission Comment', 0,
    '<%a=asset.submission.assignment%>http://<%= HostUrl.context_host(a.context) %>/<%= a.context.class.to_s.downcase.pluralize %>/<%= a.context_id %>/assignments/<%= a.id %>/submissions/<%= asset.submission.user_id %>', %{
      Submission Comment
      
      Submission Comment: <%= asset.submission.user.name %>, <%= asset.submission.assignment.title %>, <%= asset.submission.assignment.context.name %>
      
      <%= asset.author_name || "Someone" %> just made a new comment on the submission for <%= asset.submission.user.name %>
      for <%= asset.submission.assignment.title %>.  
      
      You can review the submission details here: 
      <%= main_link %>
    }, %{
      New comment by <%= asset.author.name %> for <%= asset.submission.assignment.title %>, <%= asset.submission.user.name %>, <%= asset.submission.assignment.context.name %>.
    }

    create_notification 'SubmissionComment', 'Submission Comment', 0,
    '<%a=asset.submission.assignment%>http://<%= HostUrl.context_host(a.context) %>/<%= a.context.class.to_s.downcase.pluralize %>/<%= a.context_id %>/assignments/<%= a.id %>/submissions/<%= asset.submission.user_id %>', %{
      Submission Comment For Teacher
      
      Submission Comment: <%= asset.submission.user.name %>, <%= asset.submission.assignment.title %>, <%= asset.submission.assignment.context.name %>
      
      <%= asset.author_name || "Someone" %> just made a new comment on the submission for <%= asset.submission.user.name %>
      for <%= asset.submission.assignment.title %>.  
      
      You can review the submission details here: 
      <%= main_link %>
    }, %{
      New comment by <%= asset.author.name %> for <%= asset.submission.assignment.title %>, <%= asset.submission.user.name %>, <%= asset.submission.assignment.context.name %>.
    }

    create_notification 'Submission', 'Grading', 5*60,
    '<%= a = asset.assignment %>http://<%= HostUrl.context_host(a.context) %>/<%= a.context.class.to_s.downcase.pluralize %>/<%= a.context_id %>/assignments/<%= a.id %>/submissions/<%= asset.user_id %>', %{
      Submission Grade Changed
      
      Grade Changed: <%= asset.assignment.title %>, <%= asset.assignment.context.name %>
      
      The grade on your assignment, <%= asset.assignment.title %> has been changed.  
      
      You can review the assignment here: 
      <%= main_link %>
    }, %{
      Your grade for <%= asset.assignment.title %>, <%= asset.assignment.context.name %> just changed.
    }

    create_notification 'WikiPage', 'Course Content', 15*60,
    'http://<%= HostUrl.context_host(asset.context) %>/<%= asset.context.class.to_s.downcase.pluralize %>/<%= asset.context_id %>/wiki/<%= asset.url %>', %{
      Updated Wiki Page
      
      Updated Wiki Page: <%= asset.title.titleize %>, <%= asset.context.name rescue "" %>
      
      A page has been updated on the wiki for <%= asset.context.name %> that may make your life easier.
      
      <%= asset.title.titleize %> 
      
      <%= strip_and_truncate(asset.body, :max_length => 200) %> 
      
      
      You can review it here: 
      <%= main_link %>
    }, %{
      <%= asset.title %>, <%= asset.context.name %> just updated:

      <%= strip_and_truncate(asset.body, :max_length => 200) %>
    }

    create_notification 'Other', 'Alert', 0,
      'Alert',
      'Alert'
    
    create_notification 'Summary', 'Summaries', 0,
    'http://<%= HostUrl.context_host(namespace.context) %>', %{
      Summaries
      
      Recent Instructure Activity
      
      <%= main_link %>

      Here is a summary of recent activity on your courses at Instructure:
      
      <% for delayed_message in delayed_messages do %>
      * <%= delayed_message.name_of_topic %>
        <%= delayed_message.link %>
        --------------------------------
        <%= delayed_message.summary %>
        
      <% end %>
      
      ==============================================================================

      You received this message because you are subscribed to receive messages at 
      Instructure.

      To change the way you get mail from this group, visit your profile page at
      <%= HostUrl.default_host %>.

      ==============================================================================
    }

    create_notification '', 'Student Appointment Signups', 0, '', 'Appointment Canceled By User'
    create_notification '', 'Appointment Cancelations', 0, '', 'Appointment Deleted For User'
    create_notification '', 'Appointment Cancelations', 0, '', 'Appointment Group Deleted'
    create_notification '', 'Appointment Availability', 0, '', 'Appointment Group Published'
    create_notification '', 'Appointment Availability', 0, '', 'Appointment Group Updated'
    create_notification '', 'Student Appointment Signups', 0, '', 'Appointment Reserved By User'
    create_notification '', 'Appointment Signups', 0, '', 'Appointment Reserved For User'

    puts "\nNotifications Loaded"
  end
  
  desc "Create an administrator account"
  task :configure_admin => :load_environment do

    def create_admin(email, password)
      begin
        pseudonym = Account.site_admin.pseudonyms.active.custom_find_by_unique_id(email)
        pseudonym ||= Account.default.pseudonyms.active.custom_find_by_unique_id(email)
        user = pseudonym ? pseudonym.user : User.create!
        user.register! unless user.registered?
        unless pseudonym
          # don't pass the password in the create call, because that way is extra
          # picky. the admin should know what they're doing, and we'd rather not
          # fail here.
          pseudonym = user.pseudonyms.create!(:unique_id => email,
              :password => "validpassword", :password_confirmation => "validpassword", :account => Account.site_admin)
          user.communication_channels.create!(:path => email) { |cc| cc.workflow_state = 'active' }
        end
        # set the password later.
        pseudonym.password = pseudonym.password_confirmation = password
        unless pseudonym.save
          raise pseudonym.errors.first.join " " if pseudonym.errors.size > 0
          raise "unknown error saving password"
        end
        Account.site_admin.add_user(user, 'AccountAdmin')
        Account.default.add_user(user, 'AccountAdmin')
        user
      rescue => e
        STDERR.puts "Problem creating administrative account, please try again: " + e
        nil
      end
    end

    user = nil
    if !(ENV['CANVAS_LMS_ADMIN_EMAIL'] || "").empty? && !(ENV['CANVAS_LMS_ADMIN_PASSWORD'] || "").empty?
      user = create_admin(ENV['CANVAS_LMS_ADMIN_EMAIL'], ENV['CANVAS_LMS_ADMIN_PASSWORD'])
    end

    unless user
      require 'highline/import'

      while !Rails.env.test? do

        while true do
          email = ask("What email address will the site administrator account use? > ") { |q| q.echo = true }
          email_confirm = ask("Please confirm > ") { |q| q.echo = true }
          break if email == email_confirm
        end

        while true do
          password = ask("What password will the site administrator use? > ") { |q| q.echo = "*" }
          password_confirm = ask("Please confirm > ") { |q| q.echo = "*" }
          break if password == password_confirm
        end

        break if create_admin(email, password)
      end
    end
  end
  
  desc "Configure usage statistics collection"
  task :configure_statistics_collection => [:load_environment] do
    gather_data = ENV["CANVAS_LMS_STATS_COLLECTION"] || ""
    gather_data = "opt_out" if gather_data.empty?

    if !Rails.env.test? && (ENV["CANVAS_LMS_STATS_COLLECTION"] || "").empty?
      require 'highline/import'
      choose do |menu|
        menu.header = "To help our developers better serve you, Instructure would like to collect some usage data about your Canvas installation. You can change this setting at any time."
        menu.prompt = "> "
        menu.choice("Opt in") {
          gather_data = "opt_in"
          puts "Thank you for participating!"
        }
        menu.choice("Only send anonymized data") {
          gather_data = "anonymized"
          puts "Thank you for participating in anonymous usage collection."
        }
        menu.choice("Opt out completely") {
          gather_data = "opt_out"
          puts "You have opted out."
        }
      end
    
      puts "You can change this feature at any time by running the rake task 'rake db:configure_statistics_collection'"
    end
    
    Setting.set("usage_statistics_collection", gather_data)
    Reporting::CountsReport.process
  end
  
  desc "Configure default settings"
  task :configure_default_settings => :load_environment do
    Setting.set("support_multiple_account_types", "false")
    Setting.set("show_opensource_linkback", "true")
  end
  
  desc "generate data"
  task :generate_data => [:configure_default_settings, :load_notifications, :ensure_scribd_mime_types,
      :evaluate_notification_templates] do
  end
  
  desc "Configure Default Account Name"
  task :configure_account_name => :load_environment do
    if (ENV['CANVAS_LMS_ACCOUNT_NAME'] || "").empty?
      require 'highline/import'

      if !Rails.env.test?
        name = ask("What do you want users to see as the account name? This should probably be the name of your organization. > ") { |q| q.echo = true }

        a = Account.default
        a.name = name
        a.save!
      end
    else
      a = Account.default
      a.name = ENV['CANVAS_LMS_ACCOUNT_NAME']
      a.save!
    end
  end
  
  desc "Create all the initial data, including notifications and admin account"
  task :load_initial_data => [:configure_admin, :configure_account_name, :configure_statistics_collection, :generate_data] do
   
    puts "\nInitial data loaded"
    
  end # Task: load_initial_data
  
  desc "Useful initial setup task"
  task :initial_setup => [:generate_security_key, :migrate] do
    load 'app/models/pseudonym.rb'
    Rake::Task['db:load_initial_data'].invoke
  end
  
end # Namespace: db


