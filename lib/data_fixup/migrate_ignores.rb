module DataFixup::MigrateIgnores
  def self.run
    User.where("preferences LIKE '%ignore%'").find_each do |user|
      user.preferences[:ignore].each do |purpose, assets|
        assets.each do |asset, details|
          begin
            ignore = Ignore.new
            ignore.asset_type, ignore.asset_id = ActiveRecord::Base.parse_asset_string(asset)
            ignore.purpose = purpose.to_s
            ignore.permanent = details[:permanent]
            ignore.created_at = Time.parse(details[:set])
            ignore.user = user
            ignore.save!
          rescue ActiveRecord::RecordNotUnique
          end
        end
      end
    end
  end
end