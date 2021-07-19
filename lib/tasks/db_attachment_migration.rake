# frozen_string_literal: true

namespace :db do
  desc "migrate local attachment hashes from md5 to sha512"
  task :migrate_attachments_to_sha512 => :environment do |t,args|
    # for s3 storage we use the md5 provided in the etag, so we don't want to change those
    raise 'Cannot migrate attachment digests when configured for s3 storage' if Attachment.s3_storage?

    DataFixup::MigrateAttachmentDigests.run
  end
end
