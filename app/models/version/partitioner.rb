class Version::Partitioner
  cattr_accessor :logger

  def self.precreate_tables
    Setting.get('versions_precreate_tables', 2).to_i
  end

  def self.process
    Shackles.activate(:deploy) do
      Version.transaction do
        log '*' * 80
        log '-' * 80

        partman = CanvasPartman::PartitionManager.create(Version)

        partman.ensure_partitions(precreate_tables)

        log 'Done. Bye!'
        log '*' * 80
      end
    end
  end

  def self.log(*args)
    logger.info(*args) if logger
  end
end
