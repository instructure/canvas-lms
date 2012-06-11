class DelayedJobsUseAdvisoryLocks < ActiveRecord::Migration
  tag :predeploy

  def self.connection
    Delayed::Backend::ActiveRecord::Job.connection
  end

  def self.up
    # use an advisory lock based on the name of the strand, instead of locking the whole table
    # note that we're using half of the md5, so collisions are possible, but we don't really
    # care because that would just be the old behavior, whereas for the most part locking will
    # be much smaller
    if connection.adapter_name == 'PostgreSQL'
      execute(<<-CODE)
      CREATE FUNCTION half_md5_as_bigint(strand varchar) RETURNS bigint AS $$
      DECLARE
        strand_md5 bytea;
      BEGIN
        strand_md5 := decode(md5(strand), 'hex');
        RETURN (CAST(get_byte(strand_md5, 0) AS bigint) << 56) +
                                  (CAST(get_byte(strand_md5, 1) AS bigint) << 48) +
                                  (CAST(get_byte(strand_md5, 2) AS bigint) << 40) +
                                  (CAST(get_byte(strand_md5, 3) AS bigint) << 32) +
                                  (CAST(get_byte(strand_md5, 4) AS bigint) << 24) +
                                  (get_byte(strand_md5, 5) << 16) +
                                  (get_byte(strand_md5, 6) << 8) +
                                   get_byte(strand_md5, 7);
      END;
      $$ LANGUAGE plpgsql;
      CODE

      execute(<<-CODE)
      CREATE OR REPLACE FUNCTION delayed_jobs_before_insert_row_tr_fn () RETURNS trigger AS $$
      BEGIN
        PERFORM pg_advisory_xact_lock(half_md5_as_bigint(NEW.strand));
        IF (SELECT 1 FROM delayed_jobs WHERE strand = NEW.strand LIMIT 1) = 1 THEN
          NEW.next_in_strand := 'f';
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
      CODE

      execute(<<-CODE)
      CREATE OR REPLACE FUNCTION delayed_jobs_after_delete_row_tr_fn () RETURNS trigger AS $$
      BEGIN
        PERFORM pg_advisory_xact_lock(half_md5_as_bigint(OLD.strand));
        UPDATE delayed_jobs SET next_in_strand = 't' WHERE id = (SELECT id FROM delayed_jobs j2 WHERE j2.strand = OLD.strand ORDER BY j2.strand, j2.id ASC LIMIT 1 FOR UPDATE);
        RETURN OLD;
      END;
      $$ LANGUAGE plpgsql;
      CODE
    end
  end

  def self.down
    if connection.adapter_name == 'PostgreSQL'
      execute(<<-CODE)
      CREATE OR REPLACE FUNCTION delayed_jobs_before_insert_row_tr_fn () RETURNS trigger AS $$
      BEGIN
        LOCK delayed_jobs IN SHARE ROW EXCLUSIVE MODE;
        IF (SELECT 1 FROM delayed_jobs WHERE strand = NEW.strand LIMIT 1) = 1 THEN
          NEW.next_in_strand := 'f';
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
      CODE

      execute(<<-CODE)
      CREATE OR REPLACE FUNCTION delayed_jobs_after_delete_row_tr_fn () RETURNS trigger AS $$
      BEGIN
        UPDATE delayed_jobs SET next_in_strand = 't' WHERE id = (SELECT id FROM delayed_jobs j2 WHERE j2.strand = OLD.strand ORDER BY j2.strand, j2.id ASC LIMIT 1 FOR UPDATE);
        RETURN OLD;
      END;
      $$ LANGUAGE plpgsql;
      CODE

      execute('DROP FUNCTION half_md5_as_bigint(varchar)')
    end
  end
end
