SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: ar-u-kn-true; Type: COLLATION; Schema: public; Owner: -
--

CREATE COLLATION public."ar-u-kn-true" (provider = icu, deterministic = false, locale = 'ar-u-kn-true');


--
-- Name: cy-u-kn-true; Type: COLLATION; Schema: public; Owner: -
--

CREATE COLLATION public."cy-u-kn-true" (provider = icu, deterministic = false, locale = 'cy-u-kn-true');


--
-- Name: da-u-kn-true; Type: COLLATION; Schema: public; Owner: -
--

CREATE COLLATION public."da-u-kn-true" (provider = icu, deterministic = false, locale = 'da-u-kn-true');


--
-- Name: el-u-kn-true; Type: COLLATION; Schema: public; Owner: -
--

CREATE COLLATION public."el-u-kn-true" (provider = icu, deterministic = false, locale = 'el-u-kn-true');


--
-- Name: es-ES-u-kn-true; Type: COLLATION; Schema: public; Owner: -
--

CREATE COLLATION public."es-ES-u-kn-true" (provider = icu, deterministic = false, locale = 'es-ES-u-kn-true');


--
-- Name: es-u-kn-true; Type: COLLATION; Schema: public; Owner: -
--

CREATE COLLATION public."es-u-kn-true" (provider = icu, deterministic = false, locale = 'es-u-kn-true');


--
-- Name: fa-u-kn-true; Type: COLLATION; Schema: public; Owner: -
--

CREATE COLLATION public."fa-u-kn-true" (provider = icu, deterministic = false, locale = 'fa-u-kn-true');


--
-- Name: fi-u-kn-true; Type: COLLATION; Schema: public; Owner: -
--

CREATE COLLATION public."fi-u-kn-true" (provider = icu, deterministic = false, locale = 'fi-u-kn-true');


--
-- Name: fr-CA-u-kn-true; Type: COLLATION; Schema: public; Owner: -
--

CREATE COLLATION public."fr-CA-u-kn-true" (provider = icu, deterministic = false, locale = 'fr-CA-u-kn-true');


--
-- Name: he-u-kn-true; Type: COLLATION; Schema: public; Owner: -
--

CREATE COLLATION public."he-u-kn-true" (provider = icu, deterministic = false, locale = 'he-u-kn-true');


--
-- Name: hu-u-kn-true; Type: COLLATION; Schema: public; Owner: -
--

CREATE COLLATION public."hu-u-kn-true" (provider = icu, deterministic = false, locale = 'hu-u-kn-true');


--
-- Name: hy-u-kn-true; Type: COLLATION; Schema: public; Owner: -
--

CREATE COLLATION public."hy-u-kn-true" (provider = icu, deterministic = false, locale = 'hy-u-kn-true');


--
-- Name: is-u-kn-true; Type: COLLATION; Schema: public; Owner: -
--

CREATE COLLATION public."is-u-kn-true" (provider = icu, deterministic = false, locale = 'is-u-kn-true');


--
-- Name: ja-u-kn-true; Type: COLLATION; Schema: public; Owner: -
--

CREATE COLLATION public."ja-u-kn-true" (provider = icu, deterministic = false, locale = 'ja-u-kn-true');


--
-- Name: ko-u-kn-true; Type: COLLATION; Schema: public; Owner: -
--

CREATE COLLATION public."ko-u-kn-true" (provider = icu, deterministic = false, locale = 'ko-u-kn-true');


--
-- Name: nb-u-kn-true; Type: COLLATION; Schema: public; Owner: -
--

CREATE COLLATION public."nb-u-kn-true" (provider = icu, deterministic = false, locale = 'nb-u-kn-true');


--
-- Name: nn-u-kn-true; Type: COLLATION; Schema: public; Owner: -
--

CREATE COLLATION public."nn-u-kn-true" (provider = icu, deterministic = false, locale = 'nn-u-kn-true');


--
-- Name: pl-u-kn-true; Type: COLLATION; Schema: public; Owner: -
--

CREATE COLLATION public."pl-u-kn-true" (provider = icu, deterministic = false, locale = 'pl-u-kn-true');


--
-- Name: ru-u-kn-true; Type: COLLATION; Schema: public; Owner: -
--

CREATE COLLATION public."ru-u-kn-true" (provider = icu, deterministic = false, locale = 'ru-u-kn-true');


--
-- Name: sl-u-kn-true; Type: COLLATION; Schema: public; Owner: -
--

CREATE COLLATION public."sl-u-kn-true" (provider = icu, deterministic = false, locale = 'sl-u-kn-true');


--
-- Name: sv-u-kn-true; Type: COLLATION; Schema: public; Owner: -
--

CREATE COLLATION public."sv-u-kn-true" (provider = icu, deterministic = false, locale = 'sv-u-kn-true');


--
-- Name: th-u-kn-true; Type: COLLATION; Schema: public; Owner: -
--

CREATE COLLATION public."th-u-kn-true" (provider = icu, deterministic = false, locale = 'th-u-kn-true');


--
-- Name: tr-u-kn-true; Type: COLLATION; Schema: public; Owner: -
--

CREATE COLLATION public."tr-u-kn-true" (provider = icu, deterministic = false, locale = 'tr-u-kn-true');


--
-- Name: uk-u-kn-true; Type: COLLATION; Schema: public; Owner: -
--

CREATE COLLATION public."uk-u-kn-true" (provider = icu, deterministic = false, locale = 'uk-u-kn-true');


--
-- Name: und-u-kn-true; Type: COLLATION; Schema: public; Owner: -
--

CREATE COLLATION public."und-u-kn-true" (provider = icu, deterministic = false, locale = 'und-u-kn-true');


--
-- Name: vi-u-kn-true; Type: COLLATION; Schema: public; Owner: -
--

CREATE COLLATION public."vi-u-kn-true" (provider = icu, deterministic = false, locale = 'vi-u-kn-true');


--
-- Name: zh-Hans-u-kn-true; Type: COLLATION; Schema: public; Owner: -
--

CREATE COLLATION public."zh-Hans-u-kn-true" (provider = icu, deterministic = false, locale = 'zh-Hans-u-kn-true');


--
-- Name: zh-Hant-u-kn-true; Type: COLLATION; Schema: public; Owner: -
--

CREATE COLLATION public."zh-Hant-u-kn-true" (provider = icu, deterministic = false, locale = 'zh-Hant-u-kn-true');


--
-- Name: attachment_before_insert_verify_active_folder__tr_fn(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.attachment_before_insert_verify_active_folder__tr_fn() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
DECLARE
  folder_state text;
BEGIN
  SELECT workflow_state INTO folder_state FROM folders WHERE folders.id = NEW.folder_id FOR SHARE;
  if folder_state = 'deleted' then
    RAISE EXCEPTION 'Cannot create attachments in deleted folders --> %', NEW.folder_id;
  end if;
  RETURN NEW;
END;
$$;


--
-- Name: delayed_jobs_after_delete_row_tr_fn(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delayed_jobs_after_delete_row_tr_fn() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $_$
DECLARE
  next_strand varchar;
  running_count integer;
  should_lock boolean;
  should_be_precise boolean;
  update_query varchar;
  skip_locked varchar;
  transition boolean;
BEGIN
  IF OLD.strand IS NOT NULL THEN
    should_lock := true;
    should_be_precise := OLD.id % (OLD.max_concurrent * 4) = 0;

    IF NOT should_be_precise AND OLD.max_concurrent > 16 THEN
      running_count := (SELECT COUNT(*) FROM (
        SELECT 1 as one FROM delayed_jobs WHERE strand = OLD.strand AND next_in_strand = 't' LIMIT OLD.max_concurrent
      ) subquery_for_count);
      should_lock := running_count < OLD.max_concurrent;
    END IF;

    IF should_lock THEN
      PERFORM pg_advisory_xact_lock(half_md5_as_bigint(OLD.strand));
    END IF;

    -- note that we don't really care if the row we're deleting has a singleton, or if it even
    -- matches the row(s) we're going to update. we just need to make sure that whatever
    -- singleton we grab isn't already running (which is a simple existence check, since
    -- the unique indexes ensure there is at most one singleton running, and one queued)
    update_query := 'UPDATE delayed_jobs SET next_in_strand=true WHERE id IN (
      SELECT id FROM delayed_jobs j2
        WHERE next_in_strand=false AND
          j2.strand=$1.strand AND
          (j2.singleton IS NULL OR NOT EXISTS (SELECT 1 FROM delayed_jobs j3 WHERE j3.singleton=j2.singleton AND j3.id<>j2.id AND (j3.locked_by IS NULL OR j3.locked_by = ''on hold'' OR j3.locked_by <> ''on hold'')))
        ORDER BY j2.strand_order_override ASC, j2.id ASC
        LIMIT ';

    IF should_be_precise THEN
      running_count := (SELECT COUNT(*) FROM (
        SELECT 1 FROM delayed_jobs WHERE strand = OLD.strand AND next_in_strand = 't' LIMIT OLD.max_concurrent
      ) s);
      IF running_count < OLD.max_concurrent THEN
        update_query := update_query || '($1.max_concurrent - $2)';
      ELSE
        -- we have too many running already; just bail
        RETURN OLD;
      END IF;
    ELSE
      update_query := update_query || '1';

      -- n-strands don't require precise ordering; we can make this query more performant
      IF OLD.max_concurrent > 1 THEN
        skip_locked := ' SKIP LOCKED';
      END IF;
    END IF;

    update_query := update_query || ' FOR UPDATE' || COALESCE(skip_locked, '') || ')';
    EXECUTE update_query USING OLD, running_count;
  END IF;

  IF OLD.singleton IS NOT NULL THEN
    PERFORM pg_advisory_xact_lock(half_md5_as_bigint(CONCAT('singleton:', OLD.singleton)));

    transition := EXISTS (SELECT 1 FROM delayed_jobs AS j1 WHERE j1.singleton = OLD.singleton AND j1.strand IS DISTINCT FROM OLD.strand AND locked_by IS NULL);

    IF transition THEN
      next_strand := (SELECT j1.strand FROM delayed_jobs AS j1 WHERE j1.singleton = OLD.singleton AND j1.strand IS DISTINCT FROM OLD.strand AND locked_by IS NULL AND j1.strand IS NOT NULL LIMIT 1);

      IF next_strand IS NOT NULL THEN
        -- if the singleton has a new strand defined, we need to lock it to ensure we obey n_strand constraints --
        IF NOT pg_try_advisory_xact_lock(half_md5_as_bigint(next_strand)) THEN
          -- a failure to acquire the lock means that another process already has it and will thus handle this singleton --
          RETURN OLD;
        END IF;
      END IF;
    ELSIF OLD.strand IS NOT NULL THEN
      -- if there is no transition and there is a strand then we have already handled this singleton in the case above --
      RETURN OLD;
    END IF;

    -- handles transitioning a singleton from stranded to not stranded --
    -- handles transitioning a singleton from unstranded to stranded --
    -- handles transitioning a singleton from strand A to strand B --
    -- these transitions are a relatively rare case, so we take a shortcut and --
    -- only start the next singleton if its strand does not currently have any running jobs --
    -- if it does, the next stranded job that finishes will start this singleton if it can --
    UPDATE delayed_jobs SET next_in_strand=true WHERE id IN (
      SELECT id FROM delayed_jobs j2
        WHERE next_in_strand=false AND
          j2.singleton=OLD.singleton AND
          j2.locked_by IS NULL AND
          (j2.strand IS NULL OR NOT EXISTS (SELECT 1 FROM delayed_jobs j3 WHERE j3.strand=j2.strand AND j3.id<>j2.id))
        FOR UPDATE
      );
  END IF;
  RETURN OLD;
END;
$_$;


--
-- Name: delayed_jobs_before_insert_row_tr_fn(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delayed_jobs_before_insert_row_tr_fn() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
BEGIN
  IF NEW.strand IS NOT NULL THEN
    PERFORM pg_advisory_xact_lock(half_md5_as_bigint(NEW.strand));
    IF (SELECT COUNT(*) FROM (
        SELECT 1 FROM delayed_jobs WHERE strand = NEW.strand AND next_in_strand=true LIMIT NEW.max_concurrent
      ) s) = NEW.max_concurrent THEN
      NEW.next_in_strand := false;
    END IF;
  END IF;
  IF NEW.singleton IS NOT NULL THEN
    PERFORM pg_advisory_xact_lock(half_md5_as_bigint(CONCAT('singleton:', NEW.singleton)));
    -- this condition seems silly, but it forces postgres to use the two partial indexes on singleton,
    -- rather than doing a seq scan
    PERFORM 1 FROM delayed_jobs WHERE singleton = NEW.singleton AND (locked_by IS NULL OR locked_by = 'on hold' OR locked_by <> 'on hold');
    IF FOUND THEN
      NEW.next_in_strand := false;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: delayed_jobs_before_unlock_delete_conflicting_singletons_row_fn(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delayed_jobs_before_unlock_delete_conflicting_singletons_row_fn() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
BEGIN
  DELETE FROM delayed_jobs WHERE id<>OLD.id AND singleton=OLD.singleton AND locked_by IS NULL;
  RETURN NEW;
END;
$$;


--
-- Name: folder_before_insert_verify_active_parent_folder__tr_fn(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.folder_before_insert_verify_active_parent_folder__tr_fn() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
DECLARE
  parent_state text;
BEGIN
  SELECT workflow_state INTO parent_state FROM folders WHERE folders.id = NEW.parent_folder_id FOR SHARE;
  if parent_state = 'deleted' then
    RAISE EXCEPTION 'Cannot create sub-folders in deleted folders --> %', NEW.parent_folder_id;
  end if;
  RETURN NEW;
END;
$$;


--
-- Name: guard_excessive_updates(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_excessive_updates() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$ DECLARE record_count integer; max_record_count integer; BEGIN SELECT count(*) FROM oldtbl INTO record_count; max_record_count := COALESCE(setting_as_int('inst.max_update_limit.' || TG_TABLE_NAME), setting_as_int('inst.max_update_limit'), '1000'); IF record_count > max_record_count THEN IF current_setting('inst.max_update_fail', true) IS NOT DISTINCT FROM 'true' THEN RAISE EXCEPTION 'guard_excessive_updates: % to %.% failed', TG_OP, TG_TABLE_SCHEMA, TG_TABLE_NAME USING DETAIL = 'Would update ' || record_count || ' records but max is ' || max_record_count || ', orig query: ' || current_query(); ELSE RAISE WARNING 'guard_excessive_updates: % to %.% was dangerous', TG_OP, TG_TABLE_SCHEMA, TG_TABLE_NAME USING DETAIL = 'Updated ' || record_count || ' records but threshold is ' || max_record_count || ', orig query: ' || current_query(); END IF; END IF; RETURN NULL; END $$;


--
-- Name: half_md5_as_bigint(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.half_md5_as_bigint(strand character varying) RETURNS bigint
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
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
  $$;


--
-- Name: setting_as_int(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.setting_as_int(p_setting text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$ DECLARE v_text text; v_int8 int8; BEGIN v_text := current_setting( p_setting, true ); IF v_text IS NULL THEN RETURN NULL; END IF; IF NOT v_text ~ '^-?[0-9]{1,10}$' THEN RETURN NULL; END IF; v_int8 := v_text::INT8; IF v_int8 > 2147483647 OR v_int8 < -2147483648 THEN RETURN NULL; END IF; RETURN v_int8::int4; END; $_$;


--
-- Name: submission_comment_after_delete_set_last_comment_at__tr_fn(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.submission_comment_after_delete_set_last_comment_at__tr_fn() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
BEGIN
  UPDATE submissions
  SET last_comment_at = (
     SELECT MAX(submission_comments.created_at) FROM submission_comments
      WHERE submission_comments.submission_id=submissions.id AND
      submission_comments.author_id <> submissions.user_id AND
      submission_comments.draft <> 't' AND
      submission_comments.provisional_grade_id IS NULL
  ) WHERE id = OLD.submission_id;
  RETURN OLD;
END;
$$;


--
-- Name: submission_comment_after_save_set_last_comment_at__tr_fn(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.submission_comment_after_save_set_last_comment_at__tr_fn() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
BEGIN
  UPDATE submissions
  SET last_comment_at = (
     SELECT MAX(submission_comments.created_at) FROM submission_comments
      WHERE submission_comments.submission_id=submissions.id AND
      submission_comments.author_id <> submissions.user_id AND
      submission_comments.draft <> 't' AND
      submission_comments.provisional_grade_id IS NULL
  ) WHERE id = NEW.submission_id;
  RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: abstract_courses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.abstract_courses (
    id bigint NOT NULL,
    sis_source_id character varying(255),
    sis_batch_id bigint,
    account_id bigint NOT NULL,
    root_account_id bigint NOT NULL,
    short_name character varying(255),
    name character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    enrollment_term_id bigint NOT NULL,
    workflow_state character varying(255) NOT NULL,
    stuck_sis_fields text
);


--
-- Name: abstract_courses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.abstract_courses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: abstract_courses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.abstract_courses_id_seq OWNED BY public.abstract_courses.id;


--
-- Name: access_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.access_tokens (
    id bigint NOT NULL,
    developer_key_id bigint NOT NULL,
    user_id bigint,
    last_used_at timestamp without time zone,
    expires_at timestamp without time zone,
    purpose character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    crypted_token character varying(255),
    token_hint character varying(255),
    scopes text,
    remember_access boolean,
    crypted_refresh_token character varying(255),
    workflow_state character varying DEFAULT 'active'::character varying NOT NULL,
    root_account_id bigint NOT NULL,
    real_user_id bigint,
    permanent_expires_at timestamp without time zone
);


--
-- Name: access_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.access_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: access_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.access_tokens_id_seq OWNED BY public.access_tokens.id;


--
-- Name: account_notification_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account_notification_roles (
    id bigint NOT NULL,
    account_notification_id bigint NOT NULL,
    role_id bigint
);


--
-- Name: account_notification_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.account_notification_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_notification_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.account_notification_roles_id_seq OWNED BY public.account_notification_roles.id;


--
-- Name: account_notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account_notifications (
    id bigint NOT NULL,
    subject character varying(255),
    icon character varying(255) DEFAULT 'warning'::character varying,
    message text,
    account_id bigint NOT NULL,
    user_id bigint NOT NULL,
    start_at timestamp without time zone NOT NULL,
    end_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    required_account_service character varying(255),
    months_in_display_cycle integer,
    domain_specific boolean DEFAULT false NOT NULL,
    send_message boolean DEFAULT false NOT NULL,
    messages_sent_at timestamp without time zone
);


--
-- Name: account_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.account_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.account_notifications_id_seq OWNED BY public.account_notifications.id;


--
-- Name: account_report_rows; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account_report_rows (
    id bigint NOT NULL,
    account_report_id bigint NOT NULL,
    account_report_runner_id bigint NOT NULL,
    row_number integer,
    "row" character varying[] DEFAULT '{}'::character varying[],
    created_at timestamp without time zone NOT NULL,
    file character varying
);


--
-- Name: account_report_rows_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.account_report_rows_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_report_rows_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.account_report_rows_id_seq OWNED BY public.account_report_rows.id;


--
-- Name: account_report_runners; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account_report_runners (
    id bigint NOT NULL,
    account_report_id bigint NOT NULL,
    workflow_state character varying(255) DEFAULT 'created'::character varying NOT NULL,
    batch_items character varying[] DEFAULT '{}'::character varying[],
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    started_at timestamp without time zone,
    ended_at timestamp without time zone,
    job_ids bigint[] DEFAULT '{}'::bigint[] NOT NULL
);


--
-- Name: account_report_runners_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.account_report_runners_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_report_runners_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.account_report_runners_id_seq OWNED BY public.account_report_runners.id;


--
-- Name: account_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account_reports (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    message text,
    account_id bigint NOT NULL,
    attachment_id bigint,
    workflow_state character varying(255) DEFAULT 'created'::character varying NOT NULL,
    report_type character varying(255),
    progress integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    parameters text,
    current_line integer,
    total_lines integer,
    start_at timestamp without time zone,
    end_at timestamp without time zone,
    job_ids bigint[] DEFAULT '{}'::bigint[] NOT NULL
);


--
-- Name: account_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.account_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.account_reports_id_seq OWNED BY public.account_reports.id;


--
-- Name: account_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account_users (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    role_id bigint NOT NULL,
    workflow_state character varying DEFAULT 'active'::character varying NOT NULL,
    sis_batch_id bigint,
    root_account_id bigint NOT NULL
);


--
-- Name: account_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.account_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.account_users_id_seq OWNED BY public.account_users.id;


--
-- Name: accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts (
    id bigint NOT NULL,
    name character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    workflow_state character varying(255) DEFAULT 'active'::character varying NOT NULL,
    deleted_at timestamp without time zone,
    parent_account_id bigint,
    sis_source_id character varying(255),
    sis_batch_id bigint,
    current_sis_batch_id bigint,
    root_account_id bigint NOT NULL,
    last_successful_sis_batch_id bigint,
    membership_types character varying(255),
    default_time_zone character varying(255),
    external_status character varying(255) DEFAULT 'active'::character varying,
    storage_quota bigint,
    default_storage_quota bigint,
    enable_user_notes boolean DEFAULT false,
    allowed_services character varying(255),
    turnitin_pledge text,
    turnitin_comments text,
    turnitin_account_id character varying(255),
    turnitin_salt character varying(255),
    turnitin_crypted_secret character varying(255),
    show_section_name_as_course_name boolean DEFAULT false,
    allow_sis_import boolean DEFAULT false,
    equella_endpoint character varying(255),
    settings text,
    uuid character varying(255),
    default_locale character varying(255),
    stuck_sis_fields text,
    default_user_storage_quota bigint,
    lti_guid character varying(255),
    default_group_storage_quota bigint,
    turnitin_host character varying(255),
    integration_id character varying(255),
    lti_context_id character varying(255),
    brand_config_md5 character varying(32),
    turnitin_originality character varying(255),
    account_calendar_subscription_type character varying(255) DEFAULT 'manual'::character varying NOT NULL,
    latest_outcome_import_id bigint,
    course_template_id bigint,
    account_calendar_visible boolean DEFAULT false NOT NULL,
    grading_standard_id bigint
);


--
-- Name: accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounts_id_seq OWNED BY public.accounts.id;


--
-- Name: alert_criteria; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.alert_criteria (
    id bigint NOT NULL,
    alert_id bigint,
    criterion_type character varying(255),
    threshold double precision
);


--
-- Name: alert_criteria_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.alert_criteria_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: alert_criteria_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.alert_criteria_id_seq OWNED BY public.alert_criteria.id;


--
-- Name: alerts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.alerts (
    id bigint NOT NULL,
    context_id bigint NOT NULL,
    context_type character varying(255) NOT NULL,
    recipients text NOT NULL,
    repetition integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: alerts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.alerts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: alerts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.alerts_id_seq OWNED BY public.alerts.id;


--
-- Name: anonymous_or_moderation_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.anonymous_or_moderation_events (
    id bigint NOT NULL,
    assignment_id bigint NOT NULL,
    user_id bigint,
    submission_id bigint,
    canvadoc_id bigint,
    event_type character varying NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    context_external_tool_id bigint,
    quiz_id bigint
);


--
-- Name: anonymous_or_moderation_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.anonymous_or_moderation_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: anonymous_or_moderation_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.anonymous_or_moderation_events_id_seq OWNED BY public.anonymous_or_moderation_events.id;


--
-- Name: appointment_group_contexts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.appointment_group_contexts (
    id bigint NOT NULL,
    appointment_group_id bigint,
    context_code character varying(255),
    context_id bigint,
    context_type character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: appointment_group_contexts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.appointment_group_contexts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: appointment_group_contexts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.appointment_group_contexts_id_seq OWNED BY public.appointment_group_contexts.id;


--
-- Name: appointment_group_sub_contexts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.appointment_group_sub_contexts (
    id bigint NOT NULL,
    appointment_group_id bigint,
    sub_context_id bigint,
    sub_context_type character varying(255),
    sub_context_code character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: appointment_group_sub_contexts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.appointment_group_sub_contexts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: appointment_group_sub_contexts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.appointment_group_sub_contexts_id_seq OWNED BY public.appointment_group_sub_contexts.id;


--
-- Name: appointment_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.appointment_groups (
    id bigint NOT NULL,
    title character varying(255),
    description text,
    location_name character varying(255),
    location_address character varying(255),
    context_code character varying(255),
    sub_context_code character varying(255),
    workflow_state character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    start_at timestamp without time zone,
    end_at timestamp without time zone,
    participants_per_appointment integer,
    max_appointments_per_participant integer,
    min_appointments_per_participant integer DEFAULT 0,
    participant_visibility character varying(255),
    allow_observer_signup boolean DEFAULT false NOT NULL
);


--
-- Name: appointment_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.appointment_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: appointment_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.appointment_groups_id_seq OWNED BY public.appointment_groups.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: assessment_question_bank_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assessment_question_bank_users (
    id bigint NOT NULL,
    assessment_question_bank_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: assessment_question_bank_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.assessment_question_bank_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assessment_question_bank_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.assessment_question_bank_users_id_seq OWNED BY public.assessment_question_bank_users.id;


--
-- Name: assessment_question_banks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assessment_question_banks (
    id bigint NOT NULL,
    context_id bigint,
    context_type character varying(255),
    title text,
    workflow_state character varying(255) NOT NULL,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    migration_id character varying(255),
    root_account_id bigint
);


--
-- Name: assessment_question_banks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.assessment_question_banks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assessment_question_banks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.assessment_question_banks_id_seq OWNED BY public.assessment_question_banks.id;


--
-- Name: assessment_questions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assessment_questions (
    id bigint NOT NULL,
    name text,
    question_data text,
    context_id bigint,
    context_type character varying(255),
    workflow_state character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    assessment_question_bank_id bigint,
    deleted_at timestamp without time zone,
    migration_id character varying(255),
    "position" integer,
    root_account_id bigint
);


--
-- Name: assessment_questions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.assessment_questions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assessment_questions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.assessment_questions_id_seq OWNED BY public.assessment_questions.id;


--
-- Name: assessment_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assessment_requests (
    id bigint NOT NULL,
    rubric_assessment_id bigint,
    user_id bigint NOT NULL,
    asset_id bigint NOT NULL,
    asset_type character varying(255) NOT NULL,
    assessor_asset_id bigint NOT NULL,
    assessor_asset_type character varying(255) NOT NULL,
    workflow_state character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    uuid character varying(255),
    rubric_association_id bigint,
    assessor_id bigint NOT NULL
);


--
-- Name: assessment_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.assessment_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assessment_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.assessment_requests_id_seq OWNED BY public.assessment_requests.id;


--
-- Name: asset_user_accesses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.asset_user_accesses (
    id bigint NOT NULL,
    asset_code character varying(255),
    asset_group_code character varying(255),
    user_id bigint,
    context_id bigint,
    context_type character varying(255),
    last_access timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    asset_category character varying(255),
    view_score double precision,
    participate_score double precision,
    action_level character varying(255),
    display_name text,
    membership_type character varying(255),
    root_account_id bigint NOT NULL
);


--
-- Name: asset_user_accesses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.asset_user_accesses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: asset_user_accesses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.asset_user_accesses_id_seq OWNED BY public.asset_user_accesses.id;


--
-- Name: assignment_configuration_tool_lookups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assignment_configuration_tool_lookups (
    id bigint NOT NULL,
    assignment_id bigint NOT NULL,
    tool_id bigint,
    tool_type character varying(255) NOT NULL,
    subscription_id character varying,
    tool_product_code character varying,
    tool_vendor_code character varying,
    tool_resource_type_code character varying,
    context_type character varying DEFAULT 'Account'::character varying NOT NULL
);


--
-- Name: assignment_configuration_tool_lookups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.assignment_configuration_tool_lookups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assignment_configuration_tool_lookups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.assignment_configuration_tool_lookups_id_seq OWNED BY public.assignment_configuration_tool_lookups.id;


--
-- Name: assignment_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assignment_groups (
    id bigint NOT NULL,
    name character varying(255),
    rules text,
    default_assignment_name character varying(255),
    "position" integer,
    assignment_weighting_scheme character varying(255),
    group_weight double precision,
    context_id bigint NOT NULL,
    context_type character varying(255) NOT NULL,
    workflow_state character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    cloned_item_id bigint,
    context_code character varying(255),
    migration_id character varying(255),
    sis_source_id character varying(255),
    integration_data text,
    root_account_id bigint
);


--
-- Name: assignment_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.assignment_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assignment_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.assignment_groups_id_seq OWNED BY public.assignment_groups.id;


--
-- Name: assignment_override_students; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assignment_override_students (
    id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    assignment_id bigint,
    assignment_override_id bigint NOT NULL,
    user_id bigint NOT NULL,
    quiz_id bigint,
    workflow_state character varying DEFAULT 'active'::character varying NOT NULL,
    root_account_id bigint,
    context_module_id bigint,
    wiki_page_id bigint,
    discussion_topic_id bigint,
    attachment_id bigint
);


--
-- Name: assignment_override_students_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.assignment_override_students_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assignment_override_students_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.assignment_override_students_id_seq OWNED BY public.assignment_override_students.id;


--
-- Name: assignment_overrides; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assignment_overrides (
    id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    assignment_id bigint,
    assignment_version integer,
    set_type character varying(255),
    set_id bigint,
    title character varying(255) NOT NULL,
    workflow_state character varying(255) NOT NULL,
    due_at_overridden boolean DEFAULT false NOT NULL,
    due_at timestamp without time zone,
    all_day boolean,
    all_day_date date,
    unlock_at_overridden boolean DEFAULT false NOT NULL,
    unlock_at timestamp without time zone,
    lock_at_overridden boolean DEFAULT false NOT NULL,
    lock_at timestamp without time zone,
    quiz_id bigint,
    quiz_version integer,
    root_account_id bigint,
    context_module_id bigint,
    unassign_item boolean DEFAULT false NOT NULL,
    wiki_page_id bigint,
    discussion_topic_id bigint,
    attachment_id bigint,
    CONSTRAINT require_association CHECK ((((workflow_state)::text = 'deleted'::text) OR (assignment_id IS NOT NULL) OR (quiz_id IS NOT NULL) OR (context_module_id IS NOT NULL) OR (wiki_page_id IS NOT NULL) OR (discussion_topic_id IS NOT NULL) OR (attachment_id IS NOT NULL)))
);


--
-- Name: assignment_overrides_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.assignment_overrides_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assignment_overrides_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.assignment_overrides_id_seq OWNED BY public.assignment_overrides.id;


--
-- Name: assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assignments (
    id bigint NOT NULL,
    title character varying(255),
    description text,
    due_at timestamp without time zone,
    unlock_at timestamp without time zone,
    lock_at timestamp without time zone,
    points_possible double precision,
    min_score double precision,
    max_score double precision,
    mastery_score double precision,
    grading_type character varying(255),
    submission_types character varying(255),
    workflow_state character varying(255) DEFAULT 'published'::character varying NOT NULL,
    context_id bigint NOT NULL,
    context_type character varying(255) NOT NULL,
    assignment_group_id bigint,
    grading_standard_id bigint,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    group_category character varying(255),
    submissions_downloads integer DEFAULT 0,
    peer_review_count integer DEFAULT 0,
    peer_reviews_due_at timestamp without time zone,
    peer_reviews_assigned boolean DEFAULT false NOT NULL,
    peer_reviews boolean DEFAULT false NOT NULL,
    automatic_peer_reviews boolean DEFAULT false NOT NULL,
    all_day boolean DEFAULT false NOT NULL,
    all_day_date date,
    could_be_locked boolean DEFAULT false NOT NULL,
    cloned_item_id bigint,
    "position" integer,
    migration_id character varying(255),
    grade_group_students_individually boolean DEFAULT false NOT NULL,
    anonymous_peer_reviews boolean DEFAULT false NOT NULL,
    time_zone_edited character varying(255),
    turnitin_enabled boolean DEFAULT false NOT NULL,
    allowed_extensions character varying(255),
    turnitin_settings text,
    muted boolean DEFAULT false NOT NULL,
    group_category_id bigint,
    freeze_on_copy boolean DEFAULT false NOT NULL,
    copied boolean DEFAULT false NOT NULL,
    only_visible_to_overrides boolean DEFAULT false NOT NULL,
    post_to_sis boolean DEFAULT false NOT NULL,
    integration_id character varying(255),
    integration_data text,
    turnitin_id bigint,
    moderated_grading boolean DEFAULT false NOT NULL,
    grades_published_at timestamp without time zone,
    omit_from_final_grade boolean DEFAULT false NOT NULL,
    vericite_enabled boolean DEFAULT false NOT NULL,
    intra_group_peer_reviews boolean DEFAULT false NOT NULL,
    lti_context_id character varying,
    anonymous_instructor_annotations boolean DEFAULT false NOT NULL,
    duplicate_of_id bigint,
    anonymous_grading boolean DEFAULT false,
    graders_anonymous_to_graders boolean DEFAULT false,
    grader_count integer DEFAULT 0,
    grader_comments_visible_to_graders boolean DEFAULT true,
    grader_section_id bigint,
    final_grader_id bigint,
    grader_names_visible_to_final_grader boolean DEFAULT true,
    duplication_started_at timestamp without time zone,
    importing_started_at timestamp without time zone,
    allowed_attempts integer,
    root_account_id bigint NOT NULL,
    sis_source_id character varying,
    migrate_from_id bigint,
    settings jsonb,
    annotatable_attachment_id bigint,
    important_dates boolean DEFAULT false NOT NULL,
    hide_in_gradebook boolean DEFAULT false NOT NULL,
    ab_guid character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    parent_assignment_id bigint,
    type character varying(255) DEFAULT 'Assignment'::character varying NOT NULL,
    sub_assignment_tag character varying(255),
    has_sub_assignments boolean DEFAULT false NOT NULL
);


--
-- Name: enrollments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.enrollments (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    course_id bigint NOT NULL,
    type character varying(255) NOT NULL,
    uuid character varying(255),
    workflow_state character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    associated_user_id bigint,
    sis_batch_id bigint,
    start_at timestamp without time zone,
    end_at timestamp without time zone,
    course_section_id bigint NOT NULL,
    root_account_id bigint NOT NULL,
    completed_at timestamp without time zone,
    self_enrolled boolean,
    grade_publishing_status character varying(255) DEFAULT 'unpublished'::character varying,
    last_publish_attempt_at timestamp without time zone,
    stuck_sis_fields text,
    grade_publishing_message text,
    limit_privileges_to_course_section boolean DEFAULT false NOT NULL,
    last_activity_at timestamp without time zone,
    total_activity_time integer,
    role_id bigint NOT NULL,
    graded_at timestamp without time zone,
    sis_pseudonym_id bigint,
    last_attended_at timestamp without time zone,
    temporary_enrollment_source_user_id bigint,
    temporary_enrollment_pairing_id bigint
);


--
-- Name: group_memberships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.group_memberships (
    id bigint NOT NULL,
    group_id bigint NOT NULL,
    workflow_state character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id bigint NOT NULL,
    uuid character varying(255) NOT NULL,
    sis_batch_id bigint,
    moderator boolean,
    root_account_id bigint NOT NULL
);


--
-- Name: groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.groups (
    id bigint NOT NULL,
    name character varying(255),
    workflow_state character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    context_id bigint NOT NULL,
    context_type character varying(255) NOT NULL,
    category character varying(255),
    max_membership integer,
    is_public boolean,
    account_id bigint NOT NULL,
    wiki_id bigint,
    deleted_at timestamp without time zone,
    join_level character varying(255),
    default_view character varying(255) DEFAULT 'feed'::character varying,
    migration_id character varying(255),
    storage_quota bigint,
    uuid character varying(255) NOT NULL,
    root_account_id bigint NOT NULL,
    sis_source_id character varying(255),
    sis_batch_id bigint,
    stuck_sis_fields text,
    group_category_id bigint,
    description text,
    avatar_attachment_id bigint,
    leader_id bigint,
    lti_context_id character varying(255)
);


--
-- Name: assignment_student_visibilities; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.assignment_student_visibilities AS
 SELECT DISTINCT a.id AS assignment_id,
    e.user_id,
    e.course_id
   FROM (public.assignments a
     JOIN public.enrollments e ON (((e.course_id = a.context_id) AND ((a.context_type)::text = 'Course'::text) AND ((e.type)::text = ANY ((ARRAY['StudentEnrollment'::character varying, 'StudentViewEnrollment'::character varying])::text[])) AND ((e.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'rejected'::character varying, 'inactive'::character varying])::text[])))))
  WHERE (((a.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'unpublished'::character varying])::text[])) AND (COALESCE(a.only_visible_to_overrides, false) = false))
UNION
 SELECT DISTINCT a.id AS assignment_id,
    e.user_id,
    e.course_id
   FROM (((public.assignments a
     JOIN public.enrollments e ON (((e.course_id = a.context_id) AND ((a.context_type)::text = 'Course'::text) AND ((e.type)::text = ANY ((ARRAY['StudentEnrollment'::character varying, 'StudentViewEnrollment'::character varying])::text[])) AND ((e.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'rejected'::character varying, 'inactive'::character varying])::text[])))))
     JOIN public.assignment_overrides ao ON (((a.id = ao.assignment_id) AND ((ao.set_type)::text = 'ADHOC'::text))))
     JOIN public.assignment_override_students aos ON (((ao.id = aos.assignment_override_id) AND (aos.user_id = e.user_id))))
  WHERE (((ao.workflow_state)::text = 'active'::text) AND ((aos.workflow_state)::text <> 'deleted'::text) AND ((a.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'unpublished'::character varying])::text[])) AND (a.only_visible_to_overrides = true))
UNION
 SELECT DISTINCT a.id AS assignment_id,
    e.user_id,
    e.course_id
   FROM ((((public.assignments a
     JOIN public.enrollments e ON (((e.course_id = a.context_id) AND ((a.context_type)::text = 'Course'::text) AND ((e.type)::text = ANY ((ARRAY['StudentEnrollment'::character varying, 'StudentViewEnrollment'::character varying])::text[])) AND ((e.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'rejected'::character varying, 'inactive'::character varying])::text[])))))
     JOIN public.assignment_overrides ao ON (((a.id = ao.assignment_id) AND ((ao.set_type)::text = 'Group'::text))))
     JOIN public.groups g ON ((g.id = ao.set_id)))
     JOIN public.group_memberships gm ON (((gm.group_id = g.id) AND (gm.user_id = e.user_id))))
  WHERE (((gm.workflow_state)::text <> 'deleted'::text) AND ((g.workflow_state)::text <> 'deleted'::text) AND ((ao.workflow_state)::text = 'active'::text) AND ((a.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'unpublished'::character varying])::text[])) AND (a.only_visible_to_overrides = true))
UNION
 SELECT DISTINCT a.id AS assignment_id,
    e.user_id,
    e.course_id
   FROM ((public.assignments a
     JOIN public.enrollments e ON (((e.course_id = a.context_id) AND ((a.context_type)::text = 'Course'::text) AND ((e.type)::text = ANY ((ARRAY['StudentEnrollment'::character varying, 'StudentViewEnrollment'::character varying])::text[])) AND ((e.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'rejected'::character varying, 'inactive'::character varying])::text[])))))
     JOIN public.assignment_overrides ao ON (((e.course_section_id = ao.set_id) AND ((ao.set_type)::text = 'CourseSection'::text) AND (ao.assignment_id = a.id))))
  WHERE (((a.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'unpublished'::character varying])::text[])) AND (a.only_visible_to_overrides = true) AND ((ao.workflow_state)::text = 'active'::text));


--
-- Name: content_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.content_tags (
    id bigint NOT NULL,
    content_id bigint,
    content_type character varying(255),
    context_id bigint NOT NULL,
    context_type character varying(255) NOT NULL,
    title text,
    tag character varying(255),
    url text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    comments text,
    tag_type character varying(255) DEFAULT 'default'::character varying,
    context_module_id bigint,
    "position" integer,
    indent integer,
    migration_id character varying(255),
    learning_outcome_id bigint,
    context_code character varying(255),
    mastery_score double precision,
    rubric_association_id bigint,
    workflow_state character varying(255) DEFAULT 'active'::character varying NOT NULL,
    cloned_item_id bigint,
    associated_asset_id bigint,
    associated_asset_type character varying(255),
    new_tab boolean,
    link_settings jsonb,
    root_account_id bigint NOT NULL,
    external_data jsonb
);


--
-- Name: context_modules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.context_modules (
    id bigint NOT NULL,
    context_id bigint NOT NULL,
    context_type character varying(255) NOT NULL,
    name text,
    "position" integer,
    prerequisites text,
    completion_requirements text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    workflow_state character varying(255) DEFAULT 'active'::character varying NOT NULL,
    deleted_at timestamp without time zone,
    unlock_at timestamp without time zone,
    migration_id character varying(255),
    require_sequential_progress boolean,
    cloned_item_id bigint,
    completion_events text,
    requirement_count integer,
    root_account_id bigint
);


--
-- Name: quizzes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quizzes (
    id bigint NOT NULL,
    title character varying(255),
    description text,
    quiz_data text,
    points_possible double precision,
    context_id bigint NOT NULL,
    context_type character varying(255) NOT NULL,
    assignment_id bigint,
    workflow_state character varying(255) NOT NULL,
    shuffle_answers boolean DEFAULT false NOT NULL,
    show_correct_answers boolean DEFAULT true NOT NULL,
    time_limit integer,
    allowed_attempts integer,
    scoring_policy character varying(255),
    quiz_type character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    lock_at timestamp without time zone,
    unlock_at timestamp without time zone,
    deleted_at timestamp without time zone,
    could_be_locked boolean DEFAULT false NOT NULL,
    cloned_item_id bigint,
    access_code character varying(255),
    migration_id character varying(255),
    unpublished_question_count integer DEFAULT 0,
    due_at timestamp without time zone,
    question_count integer,
    last_assignment_id bigint,
    published_at timestamp without time zone,
    last_edited_at timestamp without time zone,
    anonymous_submissions boolean DEFAULT false NOT NULL,
    assignment_group_id bigint,
    hide_results character varying(255),
    ip_filter character varying(255),
    require_lockdown_browser boolean DEFAULT false NOT NULL,
    require_lockdown_browser_for_results boolean DEFAULT false NOT NULL,
    one_question_at_a_time boolean DEFAULT false NOT NULL,
    cant_go_back boolean DEFAULT false NOT NULL,
    show_correct_answers_at timestamp without time zone,
    hide_correct_answers_at timestamp without time zone,
    require_lockdown_browser_monitor boolean DEFAULT false NOT NULL,
    lockdown_browser_monitor_data text,
    only_visible_to_overrides boolean DEFAULT false NOT NULL,
    one_time_results boolean DEFAULT false NOT NULL,
    show_correct_answers_last_attempt boolean DEFAULT false NOT NULL,
    root_account_id bigint,
    disable_timer_autosubmission boolean DEFAULT false NOT NULL
);


--
-- Name: assignment_student_visibilities_v2; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.assignment_student_visibilities_v2 AS
 WITH all_tags AS (
         SELECT a.id AS assignment_id,
            COALESCE(t.context_module_id, qt.context_module_id) AS context_module_id
           FROM (((public.assignments a
             LEFT JOIN public.content_tags t ON (((t.content_id = a.id) AND ((t.content_type)::text = 'Assignment'::text))))
             LEFT JOIN public.quizzes q ON ((q.assignment_id = a.id)))
             LEFT JOIN public.content_tags qt ON (((qt.content_id = q.id) AND ((qt.content_type)::text = 'Quizzes::Quiz'::text))))
          WHERE (((COALESCE(t.tag_type, qt.tag_type))::text = 'context_module'::text) AND ((COALESCE(t.workflow_state, qt.workflow_state))::text <> 'deleted'::text))
        )
(
        (
                (
                        (
                                 SELECT DISTINCT o.id AS assignment_id,
                                    e.user_id,
                                    e.course_id
                                   FROM ((((public.assignments o
                                     JOIN public.enrollments e ON (((e.course_id = o.context_id) AND ((o.context_type)::text = 'Course'::text) AND ((e.type)::text = ANY ((ARRAY['StudentEnrollment'::character varying, 'StudentViewEnrollment'::character varying])::text[])) AND ((e.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'rejected'::character varying, 'inactive'::character varying])::text[])))))
                                     LEFT JOIN all_tags t ON ((o.id = t.assignment_id)))
                                     LEFT JOIN public.context_modules m ON (((m.id = t.context_module_id) AND ((m.workflow_state)::text <> 'deleted'::text))))
                                     LEFT JOIN public.assignment_overrides ao ON (((m.id = ao.context_module_id) AND ((ao.workflow_state)::text = 'active'::text))))
                                  WHERE (((o.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'unpublished'::character varying])::text[])) AND (COALESCE(o.only_visible_to_overrides, false) = false) AND ((m.id IS NULL) OR ((ao.context_module_id IS NULL) AND ((m.workflow_state)::text <> 'deleted'::text))))
                                UNION
                                 SELECT DISTINCT a.id AS assignment_id,
                                    e.user_id,
                                    e.course_id
                                   FROM ((((public.assignments a
                                     JOIN public.enrollments e ON (((e.course_id = a.context_id) AND ((a.context_type)::text = 'Course'::text) AND ((e.type)::text = ANY ((ARRAY['StudentEnrollment'::character varying, 'StudentViewEnrollment'::character varying])::text[])) AND ((e.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'rejected'::character varying, 'inactive'::character varying])::text[])))))
                                     JOIN public.assignment_overrides ao ON (((a.id = ao.assignment_id) AND ((ao.set_type)::text = 'Group'::text))))
                                     JOIN public.groups g ON ((g.id = ao.set_id)))
                                     JOIN public.group_memberships gm ON (((gm.group_id = g.id) AND (gm.user_id = e.user_id))))
                                  WHERE (((gm.workflow_state)::text <> 'deleted'::text) AND ((g.workflow_state)::text <> 'deleted'::text) AND ((ao.workflow_state)::text = 'active'::text) AND ((a.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'unpublished'::character varying])::text[])) AND (a.only_visible_to_overrides = true))
                                UNION
                                 SELECT DISTINCT o.id AS assignment_id,
                                    e.user_id,
                                    e.course_id
                                   FROM ((((public.assignments o
                                     JOIN public.enrollments e ON (((e.course_id = o.context_id) AND ((o.context_type)::text = 'Course'::text) AND ((e.type)::text = ANY ((ARRAY['StudentEnrollment'::character varying, 'StudentViewEnrollment'::character varying])::text[])) AND ((e.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'rejected'::character varying, 'inactive'::character varying])::text[])))))
                                     LEFT JOIN all_tags t ON ((o.id = t.assignment_id)))
                                     LEFT JOIN public.context_modules m ON (((m.id = t.context_module_id) AND ((m.workflow_state)::text <> 'deleted'::text))))
                                     JOIN public.assignment_overrides ao ON (((e.course_section_id = ao.set_id) AND ((ao.set_type)::text = 'CourseSection'::text) AND ((ao.assignment_id = o.id) OR (m.id = ao.context_module_id)) AND ((ao.workflow_state)::text = 'active'::text))))
                                  WHERE (((o.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'unpublished'::character varying])::text[])) AND ((m.id IS NOT NULL) OR (o.only_visible_to_overrides = true)) AND (ao.unassign_item = false))
                        ) EXCEPT
                         SELECT DISTINCT o.id AS assignment_id,
                            e.user_id,
                            e.course_id
                           FROM ((public.assignments o
                             JOIN public.enrollments e ON (((e.course_id = o.context_id) AND ((o.context_type)::text = 'Course'::text) AND ((e.type)::text = ANY ((ARRAY['StudentEnrollment'::character varying, 'StudentViewEnrollment'::character varying])::text[])) AND ((e.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'rejected'::character varying, 'inactive'::character varying])::text[])))))
                             JOIN public.assignment_overrides ao ON (((e.course_section_id = ao.set_id) AND ((ao.set_type)::text = 'CourseSection'::text) AND (ao.assignment_id = o.id) AND ((ao.workflow_state)::text = 'active'::text))))
                          WHERE (((o.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'unpublished'::character varying])::text[])) AND (ao.unassign_item = true))
                ) UNION
                 SELECT DISTINCT o.id AS assignment_id,
                    e.user_id,
                    e.course_id
                   FROM (((((public.assignments o
                     JOIN public.enrollments e ON (((e.course_id = o.context_id) AND ((o.context_type)::text = 'Course'::text) AND ((e.type)::text = ANY ((ARRAY['StudentEnrollment'::character varying, 'StudentViewEnrollment'::character varying])::text[])) AND ((e.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'rejected'::character varying, 'inactive'::character varying])::text[])))))
                     LEFT JOIN all_tags t ON ((o.id = t.assignment_id)))
                     LEFT JOIN public.context_modules m ON (((m.id = t.context_module_id) AND ((m.workflow_state)::text <> 'deleted'::text))))
                     JOIN public.assignment_overrides ao ON ((((ao.assignment_id = o.id) OR (m.id = ao.context_module_id)) AND ((ao.set_type)::text = 'ADHOC'::text) AND ((ao.workflow_state)::text = 'active'::text))))
                     JOIN public.assignment_override_students aos ON (((ao.id = aos.assignment_override_id) AND (aos.user_id = e.user_id) AND ((aos.workflow_state)::text <> 'deleted'::text))))
                  WHERE (((o.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'unpublished'::character varying])::text[])) AND ((m.id IS NOT NULL) OR (o.only_visible_to_overrides = true)) AND (ao.unassign_item = false))
        ) EXCEPT
         SELECT DISTINCT o.id AS assignment_id,
            e.user_id,
            e.course_id
           FROM (((public.assignments o
             JOIN public.enrollments e ON (((e.course_id = o.context_id) AND ((o.context_type)::text = 'Course'::text) AND ((e.type)::text = ANY ((ARRAY['StudentEnrollment'::character varying, 'StudentViewEnrollment'::character varying])::text[])) AND ((e.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'rejected'::character varying, 'inactive'::character varying])::text[])))))
             JOIN public.assignment_overrides ao ON (((o.id = ao.assignment_id) AND ((ao.set_type)::text = 'ADHOC'::text) AND ((ao.workflow_state)::text = 'active'::text))))
             JOIN public.assignment_override_students aos ON (((ao.id = aos.assignment_override_id) AND (aos.user_id = e.user_id) AND ((aos.workflow_state)::text <> 'deleted'::text))))
          WHERE (((o.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'unpublished'::character varying])::text[])) AND (ao.unassign_item = true))
) UNION
 SELECT DISTINCT o.id AS assignment_id,
    e.user_id,
    e.course_id
   FROM ((public.assignments o
     JOIN public.enrollments e ON (((e.course_id = o.context_id) AND ((o.context_type)::text = 'Course'::text) AND ((e.type)::text = ANY ((ARRAY['StudentEnrollment'::character varying, 'StudentViewEnrollment'::character varying])::text[])) AND ((e.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'rejected'::character varying, 'inactive'::character varying])::text[])))))
     JOIN public.assignment_overrides ao ON (((e.course_id = ao.set_id) AND ((ao.set_type)::text = 'Course'::text) AND (o.id = ao.assignment_id))))
  WHERE (((o.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'unpublished'::character varying])::text[])) AND ((ao.workflow_state)::text = 'active'::text));


--
-- Name: assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.assignments_id_seq OWNED BY public.assignments.id;


--
-- Name: attachment_associations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.attachment_associations (
    id bigint NOT NULL,
    attachment_id bigint,
    context_id bigint,
    context_type character varying(255),
    root_account_id bigint
);


--
-- Name: attachment_associations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.attachment_associations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: attachment_associations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.attachment_associations_id_seq OWNED BY public.attachment_associations.id;


--
-- Name: attachment_upload_statuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.attachment_upload_statuses (
    id bigint NOT NULL,
    attachment_id bigint NOT NULL,
    error text NOT NULL,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: attachment_upload_statuses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.attachment_upload_statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: attachment_upload_statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.attachment_upload_statuses_id_seq OWNED BY public.attachment_upload_statuses.id;


--
-- Name: attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.attachments (
    id bigint NOT NULL,
    context_id bigint,
    context_type character varying(255),
    size bigint,
    folder_id bigint,
    content_type character varying(255),
    filename text,
    uuid character varying(255),
    display_name text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    workflow_state character varying(255),
    user_id bigint,
    locked boolean DEFAULT false,
    file_state character varying(255),
    deleted_at timestamp without time zone,
    "position" integer,
    lock_at timestamp without time zone,
    unlock_at timestamp without time zone,
    could_be_locked boolean,
    root_attachment_id bigint,
    cloned_item_id bigint,
    migration_id character varying(255),
    namespace character varying(255),
    media_entry_id character varying(255),
    md5 character varying(255),
    encoding character varying(255),
    need_notify boolean,
    upload_error_message text,
    replacement_attachment_id bigint,
    usage_rights_id bigint,
    modified_at timestamp without time zone,
    viewed_at timestamp without time zone,
    instfs_uuid character varying,
    root_account_id bigint,
    category character varying DEFAULT 'uncategorized'::character varying NOT NULL,
    word_count integer,
    visibility_level character varying(32) DEFAULT 'inherit'::character varying NOT NULL,
    only_visible_to_overrides boolean DEFAULT false NOT NULL
);


--
-- Name: attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.attachments_id_seq OWNED BY public.attachments.id;


--
-- Name: aua_logs_0; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.aua_logs_0 (
    id bigint NOT NULL,
    asset_user_access_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: aua_logs_0_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.aua_logs_0_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: aua_logs_0_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.aua_logs_0_id_seq OWNED BY public.aua_logs_0.id;


--
-- Name: aua_logs_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.aua_logs_1 (
    id bigint NOT NULL,
    asset_user_access_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: aua_logs_1_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.aua_logs_1_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: aua_logs_1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.aua_logs_1_id_seq OWNED BY public.aua_logs_1.id;


--
-- Name: aua_logs_2; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.aua_logs_2 (
    id bigint NOT NULL,
    asset_user_access_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: aua_logs_2_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.aua_logs_2_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: aua_logs_2_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.aua_logs_2_id_seq OWNED BY public.aua_logs_2.id;


--
-- Name: aua_logs_3; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.aua_logs_3 (
    id bigint NOT NULL,
    asset_user_access_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: aua_logs_3_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.aua_logs_3_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: aua_logs_3_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.aua_logs_3_id_seq OWNED BY public.aua_logs_3.id;


--
-- Name: aua_logs_4; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.aua_logs_4 (
    id bigint NOT NULL,
    asset_user_access_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: aua_logs_4_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.aua_logs_4_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: aua_logs_4_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.aua_logs_4_id_seq OWNED BY public.aua_logs_4.id;


--
-- Name: aua_logs_5; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.aua_logs_5 (
    id bigint NOT NULL,
    asset_user_access_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: aua_logs_5_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.aua_logs_5_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: aua_logs_5_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.aua_logs_5_id_seq OWNED BY public.aua_logs_5.id;


--
-- Name: aua_logs_6; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.aua_logs_6 (
    id bigint NOT NULL,
    asset_user_access_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: aua_logs_6_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.aua_logs_6_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: aua_logs_6_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.aua_logs_6_id_seq OWNED BY public.aua_logs_6.id;


--
-- Name: auditor_authentication_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auditor_authentication_records (
    id bigint NOT NULL,
    uuid character varying NOT NULL,
    account_id bigint NOT NULL,
    event_type character varying NOT NULL,
    pseudonym_id bigint NOT NULL,
    request_id character varying NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: auditor_authentication_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.auditor_authentication_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: auditor_authentication_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.auditor_authentication_records_id_seq OWNED BY public.auditor_authentication_records.id;


--
-- Name: auditor_authentication_records_2025_5; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auditor_authentication_records_2025_5 (
    id bigint DEFAULT nextval('public.auditor_authentication_records_id_seq'::regclass),
    uuid character varying,
    account_id bigint,
    event_type character varying,
    pseudonym_id bigint,
    request_id character varying,
    user_id bigint,
    created_at timestamp without time zone,
    CONSTRAINT auditor_authentication_records_2025_5_created_at_check CHECK (((created_at >= '2025-05-01 00:00:00'::timestamp without time zone) AND (created_at < '2025-06-01 00:00:00'::timestamp without time zone)))
)
INHERITS (public.auditor_authentication_records);


--
-- Name: auditor_authentication_records_2025_6; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auditor_authentication_records_2025_6 (
    id bigint DEFAULT nextval('public.auditor_authentication_records_id_seq'::regclass),
    uuid character varying,
    account_id bigint,
    event_type character varying,
    pseudonym_id bigint,
    request_id character varying,
    user_id bigint,
    created_at timestamp without time zone,
    CONSTRAINT auditor_authentication_records_2025_6_created_at_check CHECK (((created_at >= '2025-06-01 00:00:00'::timestamp without time zone) AND (created_at < '2025-07-01 00:00:00'::timestamp without time zone)))
)
INHERITS (public.auditor_authentication_records);


--
-- Name: auditor_course_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auditor_course_records (
    id bigint NOT NULL,
    uuid character varying NOT NULL,
    account_id bigint NOT NULL,
    course_id bigint NOT NULL,
    data text,
    event_source character varying NOT NULL,
    event_type character varying NOT NULL,
    request_id character varying NOT NULL,
    sis_batch_id bigint,
    user_id bigint,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: auditor_course_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.auditor_course_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: auditor_course_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.auditor_course_records_id_seq OWNED BY public.auditor_course_records.id;


--
-- Name: auditor_course_records_2025_5; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auditor_course_records_2025_5 (
    id bigint DEFAULT nextval('public.auditor_course_records_id_seq'::regclass),
    uuid character varying,
    account_id bigint,
    course_id bigint,
    data text,
    event_source character varying,
    event_type character varying,
    request_id character varying,
    sis_batch_id bigint,
    user_id bigint,
    created_at timestamp without time zone,
    CONSTRAINT auditor_course_records_2025_5_created_at_check CHECK (((created_at >= '2025-05-01 00:00:00'::timestamp without time zone) AND (created_at < '2025-06-01 00:00:00'::timestamp without time zone)))
)
INHERITS (public.auditor_course_records);


--
-- Name: auditor_course_records_2025_6; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auditor_course_records_2025_6 (
    id bigint DEFAULT nextval('public.auditor_course_records_id_seq'::regclass),
    uuid character varying,
    account_id bigint,
    course_id bigint,
    data text,
    event_source character varying,
    event_type character varying,
    request_id character varying,
    sis_batch_id bigint,
    user_id bigint,
    created_at timestamp without time zone,
    CONSTRAINT auditor_course_records_2025_6_created_at_check CHECK (((created_at >= '2025-06-01 00:00:00'::timestamp without time zone) AND (created_at < '2025-07-01 00:00:00'::timestamp without time zone)))
)
INHERITS (public.auditor_course_records);


--
-- Name: auditor_feature_flag_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auditor_feature_flag_records (
    id bigint NOT NULL,
    uuid character varying NOT NULL,
    feature_flag_id bigint NOT NULL,
    root_account_id bigint NOT NULL,
    context_type character varying,
    context_id bigint,
    feature_name character varying,
    event_type character varying NOT NULL,
    state_before character varying NOT NULL,
    state_after character varying NOT NULL,
    request_id character varying NOT NULL,
    user_id bigint,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: auditor_feature_flag_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.auditor_feature_flag_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: auditor_feature_flag_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.auditor_feature_flag_records_id_seq OWNED BY public.auditor_feature_flag_records.id;


--
-- Name: auditor_feature_flag_records_2025_5; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auditor_feature_flag_records_2025_5 (
    id bigint DEFAULT nextval('public.auditor_feature_flag_records_id_seq'::regclass),
    uuid character varying,
    feature_flag_id bigint,
    root_account_id bigint,
    context_type character varying,
    context_id bigint,
    feature_name character varying,
    event_type character varying,
    state_before character varying,
    state_after character varying,
    request_id character varying,
    user_id bigint,
    created_at timestamp without time zone,
    CONSTRAINT auditor_feature_flag_records_2025_5_created_at_check CHECK (((created_at >= '2025-05-01 00:00:00'::timestamp without time zone) AND (created_at < '2025-06-01 00:00:00'::timestamp without time zone)))
)
INHERITS (public.auditor_feature_flag_records);


--
-- Name: auditor_feature_flag_records_2025_6; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auditor_feature_flag_records_2025_6 (
    id bigint DEFAULT nextval('public.auditor_feature_flag_records_id_seq'::regclass),
    uuid character varying,
    feature_flag_id bigint,
    root_account_id bigint,
    context_type character varying,
    context_id bigint,
    feature_name character varying,
    event_type character varying,
    state_before character varying,
    state_after character varying,
    request_id character varying,
    user_id bigint,
    created_at timestamp without time zone,
    CONSTRAINT auditor_feature_flag_records_2025_6_created_at_check CHECK (((created_at >= '2025-06-01 00:00:00'::timestamp without time zone) AND (created_at < '2025-07-01 00:00:00'::timestamp without time zone)))
)
INHERITS (public.auditor_feature_flag_records);


--
-- Name: auditor_grade_change_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auditor_grade_change_records (
    id bigint NOT NULL,
    uuid character varying NOT NULL,
    account_id bigint NOT NULL,
    root_account_id bigint NOT NULL,
    assignment_id bigint,
    context_id bigint NOT NULL,
    context_type character varying NOT NULL,
    event_type character varying NOT NULL,
    excused_after boolean NOT NULL,
    excused_before boolean NOT NULL,
    grade_after character varying,
    grade_before character varying,
    graded_anonymously boolean,
    grader_id bigint,
    points_possible_after double precision,
    points_possible_before double precision,
    request_id character varying NOT NULL,
    score_after double precision,
    score_before double precision,
    student_id bigint NOT NULL,
    submission_id bigint,
    submission_version_number integer,
    created_at timestamp without time zone NOT NULL,
    grading_period_id bigint
);


--
-- Name: auditor_grade_change_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.auditor_grade_change_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: auditor_grade_change_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.auditor_grade_change_records_id_seq OWNED BY public.auditor_grade_change_records.id;


--
-- Name: auditor_grade_change_records_2025_5; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auditor_grade_change_records_2025_5 (
    id bigint DEFAULT nextval('public.auditor_grade_change_records_id_seq'::regclass),
    uuid character varying,
    account_id bigint,
    root_account_id bigint,
    assignment_id bigint,
    context_id bigint,
    context_type character varying,
    event_type character varying,
    excused_after boolean,
    excused_before boolean,
    grade_after character varying,
    grade_before character varying,
    graded_anonymously boolean,
    grader_id bigint,
    points_possible_after double precision,
    points_possible_before double precision,
    request_id character varying,
    score_after double precision,
    score_before double precision,
    student_id bigint,
    submission_id bigint,
    submission_version_number integer,
    created_at timestamp without time zone,
    grading_period_id bigint,
    CONSTRAINT auditor_grade_change_records_2025_5_created_at_check CHECK (((created_at >= '2025-05-01 00:00:00'::timestamp without time zone) AND (created_at < '2025-06-01 00:00:00'::timestamp without time zone)))
)
INHERITS (public.auditor_grade_change_records);


--
-- Name: auditor_grade_change_records_2025_6; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auditor_grade_change_records_2025_6 (
    id bigint DEFAULT nextval('public.auditor_grade_change_records_id_seq'::regclass),
    uuid character varying,
    account_id bigint,
    root_account_id bigint,
    assignment_id bigint,
    context_id bigint,
    context_type character varying,
    event_type character varying,
    excused_after boolean,
    excused_before boolean,
    grade_after character varying,
    grade_before character varying,
    graded_anonymously boolean,
    grader_id bigint,
    points_possible_after double precision,
    points_possible_before double precision,
    request_id character varying,
    score_after double precision,
    score_before double precision,
    student_id bigint,
    submission_id bigint,
    submission_version_number integer,
    created_at timestamp without time zone,
    grading_period_id bigint,
    CONSTRAINT auditor_grade_change_records_2025_6_created_at_check CHECK (((created_at >= '2025-06-01 00:00:00'::timestamp without time zone) AND (created_at < '2025-07-01 00:00:00'::timestamp without time zone)))
)
INHERITS (public.auditor_grade_change_records);


--
-- Name: auditor_pseudonym_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auditor_pseudonym_records (
    id bigint NOT NULL,
    pseudonym_id bigint NOT NULL,
    root_account_id bigint NOT NULL,
    performing_user_id bigint NOT NULL,
    action character varying NOT NULL,
    hostname character varying NOT NULL,
    pid character varying NOT NULL,
    uuid character varying NOT NULL,
    event_type character varying NOT NULL,
    request_id character varying,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: auditor_pseudonym_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.auditor_pseudonym_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: auditor_pseudonym_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.auditor_pseudonym_records_id_seq OWNED BY public.auditor_pseudonym_records.id;


--
-- Name: auditor_pseudonym_records_2025_5; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auditor_pseudonym_records_2025_5 (
    id bigint DEFAULT nextval('public.auditor_pseudonym_records_id_seq'::regclass),
    pseudonym_id bigint,
    root_account_id bigint,
    performing_user_id bigint,
    action character varying,
    hostname character varying,
    pid character varying,
    uuid character varying,
    event_type character varying,
    request_id character varying,
    created_at timestamp without time zone,
    CONSTRAINT auditor_pseudonym_records_2025_5_created_at_check CHECK (((created_at >= '2025-05-01 00:00:00'::timestamp without time zone) AND (created_at < '2025-06-01 00:00:00'::timestamp without time zone)))
)
INHERITS (public.auditor_pseudonym_records);


--
-- Name: auditor_pseudonym_records_2025_6; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auditor_pseudonym_records_2025_6 (
    id bigint DEFAULT nextval('public.auditor_pseudonym_records_id_seq'::regclass),
    pseudonym_id bigint,
    root_account_id bigint,
    performing_user_id bigint,
    action character varying,
    hostname character varying,
    pid character varying,
    uuid character varying,
    event_type character varying,
    request_id character varying,
    created_at timestamp without time zone,
    CONSTRAINT auditor_pseudonym_records_2025_6_created_at_check CHECK (((created_at >= '2025-06-01 00:00:00'::timestamp without time zone) AND (created_at < '2025-07-01 00:00:00'::timestamp without time zone)))
)
INHERITS (public.auditor_pseudonym_records);


--
-- Name: authentication_providers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.authentication_providers (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    auth_port integer,
    auth_host character varying(255),
    auth_base character varying(255),
    auth_username character varying(255),
    auth_crypted_password character varying(2048),
    auth_password_salt character varying(255),
    auth_type character varying(255),
    auth_over_tls character varying(255) DEFAULT 'start_tls'::character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    log_in_url character varying(255),
    log_out_url character varying(255),
    identifier_format character varying(255),
    certificate_fingerprint text,
    entity_id character varying(255),
    auth_filter text,
    requested_authn_context character varying(255),
    last_timeout_failure timestamp without time zone,
    login_attribute text,
    idp_entity_id character varying(255),
    "position" integer,
    parent_registration boolean DEFAULT false NOT NULL,
    workflow_state character varying(255) DEFAULT 'active'::character varying NOT NULL,
    jit_provisioning boolean DEFAULT false NOT NULL,
    metadata_uri character varying(255),
    settings json DEFAULT '{}'::json NOT NULL,
    internal_ca text,
    verify_tls_cert_opt_in boolean DEFAULT false NOT NULL
);


--
-- Name: authentication_providers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.authentication_providers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: authentication_providers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.authentication_providers_id_seq OWNED BY public.authentication_providers.id;


--
-- Name: blackout_dates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blackout_dates (
    id bigint NOT NULL,
    context_type character varying NOT NULL,
    context_id bigint NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    event_title character varying(255) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    root_account_id bigint NOT NULL
);


--
-- Name: blackout_dates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.blackout_dates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: blackout_dates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.blackout_dates_id_seq OWNED BY public.blackout_dates.id;


--
-- Name: block_editors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.block_editors (
    id bigint NOT NULL,
    root_account_id bigint NOT NULL,
    context_type character varying NOT NULL,
    context_id bigint NOT NULL,
    "time" bigint,
    blocks jsonb DEFAULT '[]'::jsonb NOT NULL,
    editor_version character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: block_editors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.block_editors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: block_editors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.block_editors_id_seq OWNED BY public.block_editors.id;


--
-- Name: bookmarks_bookmarks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bookmarks_bookmarks (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    name text NOT NULL,
    url text NOT NULL,
    "position" integer,
    json text
);


--
-- Name: bookmarks_bookmarks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bookmarks_bookmarks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bookmarks_bookmarks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bookmarks_bookmarks_id_seq OWNED BY public.bookmarks_bookmarks.id;


--
-- Name: brand_configs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.brand_configs (
    md5 character varying(32) NOT NULL,
    variables text,
    share boolean DEFAULT false NOT NULL,
    name character varying(255),
    created_at timestamp without time zone NOT NULL,
    js_overrides text,
    css_overrides text,
    mobile_js_overrides text,
    mobile_css_overrides text,
    parent_md5 character varying(255)
);


--
-- Name: calendar_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.calendar_events (
    id bigint NOT NULL,
    title character varying(255),
    description text,
    location_name text,
    location_address text,
    start_at timestamp without time zone,
    end_at timestamp without time zone,
    context_id bigint NOT NULL,
    context_type character varying(255) NOT NULL,
    workflow_state character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id bigint,
    all_day boolean,
    all_day_date date,
    deleted_at timestamp without time zone,
    cloned_item_id bigint,
    context_code character varying(255),
    migration_id character varying(255),
    time_zone_edited character varying(255),
    parent_calendar_event_id bigint,
    effective_context_code character varying(255),
    participants_per_appointment integer,
    override_participants_per_appointment boolean,
    comments text,
    timetable_code character varying(255),
    web_conference_id bigint,
    root_account_id bigint,
    important_dates boolean DEFAULT false NOT NULL,
    rrule character varying(255),
    series_uuid uuid,
    series_head boolean,
    blackout_date boolean DEFAULT false NOT NULL
);


--
-- Name: calendar_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.calendar_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: calendar_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.calendar_events_id_seq OWNED BY public.calendar_events.id;


--
-- Name: canvadocs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.canvadocs (
    id bigint NOT NULL,
    document_id character varying(255),
    process_state character varying(255),
    attachment_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    has_annotations boolean
);


--
-- Name: canvadocs_annotation_contexts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.canvadocs_annotation_contexts (
    id bigint NOT NULL,
    attachment_id bigint NOT NULL,
    submission_id bigint NOT NULL,
    root_account_id bigint NOT NULL,
    launch_id character varying NOT NULL,
    submission_attempt integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: canvadocs_annotation_contexts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.canvadocs_annotation_contexts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: canvadocs_annotation_contexts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.canvadocs_annotation_contexts_id_seq OWNED BY public.canvadocs_annotation_contexts.id;


--
-- Name: canvadocs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.canvadocs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: canvadocs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.canvadocs_id_seq OWNED BY public.canvadocs.id;


--
-- Name: canvadocs_submissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.canvadocs_submissions (
    id bigint NOT NULL,
    canvadoc_id bigint,
    crocodoc_document_id bigint,
    submission_id bigint NOT NULL
);


--
-- Name: canvadocs_submissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.canvadocs_submissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: canvadocs_submissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.canvadocs_submissions_id_seq OWNED BY public.canvadocs_submissions.id;


--
-- Name: canvas_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.canvas_metadata (
    id bigint NOT NULL,
    key character varying NOT NULL,
    payload jsonb NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: canvas_metadata_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.canvas_metadata_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: canvas_metadata_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.canvas_metadata_id_seq OWNED BY public.canvas_metadata.id;


--
-- Name: cloned_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cloned_items (
    id bigint NOT NULL,
    original_item_id bigint,
    original_item_type character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: cloned_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cloned_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cloned_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cloned_items_id_seq OWNED BY public.cloned_items.id;


--
-- Name: collaborations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.collaborations (
    id bigint NOT NULL,
    collaboration_type character varying(255),
    document_id character varying(255),
    user_id bigint,
    context_id bigint,
    context_type character varying(255),
    url character varying(255),
    uuid character varying(255),
    data text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    description text,
    title character varying(255) NOT NULL,
    workflow_state character varying(255) DEFAULT 'active'::character varying NOT NULL,
    deleted_at timestamp without time zone,
    context_code character varying(255),
    type character varying(255),
    resource_link_lookup_uuid uuid
);


--
-- Name: collaborations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.collaborations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: collaborations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.collaborations_id_seq OWNED BY public.collaborations.id;


--
-- Name: collaborators; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.collaborators (
    id bigint NOT NULL,
    user_id bigint,
    collaboration_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    authorized_service_user_id character varying(255),
    group_id bigint
);


--
-- Name: collaborators_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.collaborators_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: collaborators_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.collaborators_id_seq OWNED BY public.collaborators.id;


--
-- Name: comment_bank_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.comment_bank_items (
    id bigint NOT NULL,
    course_id bigint NOT NULL,
    root_account_id bigint NOT NULL,
    user_id bigint NOT NULL,
    comment text NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    workflow_state character varying DEFAULT 'active'::character varying NOT NULL
);


--
-- Name: comment_bank_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.comment_bank_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comment_bank_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.comment_bank_items_id_seq OWNED BY public.comment_bank_items.id;


--
-- Name: communication_channels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.communication_channels (
    id bigint NOT NULL,
    path character varying(255) NOT NULL,
    path_type character varying(255) DEFAULT 'email'::character varying NOT NULL,
    "position" integer,
    user_id bigint NOT NULL,
    pseudonym_id bigint,
    bounce_count integer DEFAULT 0,
    workflow_state character varying(255) NOT NULL,
    confirmation_code character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    build_pseudonym_on_confirm boolean,
    last_bounce_at timestamp without time zone,
    last_bounce_details text,
    last_suppression_bounce_at timestamp without time zone,
    last_transient_bounce_at timestamp without time zone,
    last_transient_bounce_details text,
    confirmation_code_expires_at timestamp without time zone,
    confirmation_sent_count integer DEFAULT 0 NOT NULL,
    root_account_ids bigint[],
    confirmation_redirect character varying
);


--
-- Name: communication_channels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.communication_channels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: communication_channels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.communication_channels_id_seq OWNED BY public.communication_channels.id;


--
-- Name: conditional_release_assignment_set_actions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conditional_release_assignment_set_actions (
    id bigint NOT NULL,
    action character varying NOT NULL,
    source character varying NOT NULL,
    student_id bigint NOT NULL,
    actor_id bigint NOT NULL,
    assignment_set_id bigint,
    deleted_at timestamp without time zone,
    root_account_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: conditional_release_assignment_set_actions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.conditional_release_assignment_set_actions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: conditional_release_assignment_set_actions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.conditional_release_assignment_set_actions_id_seq OWNED BY public.conditional_release_assignment_set_actions.id;


--
-- Name: conditional_release_assignment_set_associations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conditional_release_assignment_set_associations (
    id bigint NOT NULL,
    assignment_set_id bigint,
    assignment_id bigint,
    "position" integer,
    deleted_at timestamp without time zone,
    root_account_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: conditional_release_assignment_set_associations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.conditional_release_assignment_set_associations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: conditional_release_assignment_set_associations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.conditional_release_assignment_set_associations_id_seq OWNED BY public.conditional_release_assignment_set_associations.id;


--
-- Name: conditional_release_assignment_sets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conditional_release_assignment_sets (
    id bigint NOT NULL,
    scoring_range_id bigint NOT NULL,
    "position" integer,
    deleted_at timestamp without time zone,
    root_account_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: conditional_release_assignment_sets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.conditional_release_assignment_sets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: conditional_release_assignment_sets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.conditional_release_assignment_sets_id_seq OWNED BY public.conditional_release_assignment_sets.id;


--
-- Name: conditional_release_rules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conditional_release_rules (
    id bigint NOT NULL,
    course_id bigint,
    trigger_assignment_id bigint,
    deleted_at timestamp without time zone,
    root_account_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: conditional_release_rules_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.conditional_release_rules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: conditional_release_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.conditional_release_rules_id_seq OWNED BY public.conditional_release_rules.id;


--
-- Name: conditional_release_scoring_ranges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conditional_release_scoring_ranges (
    id bigint NOT NULL,
    rule_id bigint NOT NULL,
    lower_bound numeric,
    upper_bound numeric,
    "position" integer,
    deleted_at timestamp without time zone,
    root_account_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: conditional_release_scoring_ranges_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.conditional_release_scoring_ranges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: conditional_release_scoring_ranges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.conditional_release_scoring_ranges_id_seq OWNED BY public.conditional_release_scoring_ranges.id;


--
-- Name: content_exports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.content_exports (
    id bigint NOT NULL,
    user_id bigint,
    attachment_id bigint,
    export_type character varying(255),
    settings text,
    progress double precision,
    workflow_state character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    content_migration_id bigint,
    context_type character varying(255),
    context_id bigint,
    global_identifiers boolean DEFAULT false NOT NULL
);


--
-- Name: content_exports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.content_exports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: content_exports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.content_exports_id_seq OWNED BY public.content_exports.id;


--
-- Name: content_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.content_migrations (
    id bigint NOT NULL,
    context_id bigint NOT NULL,
    user_id bigint,
    workflow_state character varying(255) NOT NULL,
    migration_settings text,
    started_at timestamp without time zone,
    finished_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    progress double precision,
    context_type character varying(255),
    attachment_id bigint,
    overview_attachment_id bigint,
    exported_attachment_id bigint,
    source_course_id bigint,
    migration_type character varying(255),
    child_subscription_id bigint,
    root_account_id bigint,
    asset_map_attachment_id bigint
);


--
-- Name: content_migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.content_migrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: content_migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.content_migrations_id_seq OWNED BY public.content_migrations.id;


--
-- Name: content_participation_counts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.content_participation_counts (
    id bigint NOT NULL,
    content_type character varying(255),
    context_type character varying(255),
    context_id bigint,
    user_id bigint,
    unread_count integer DEFAULT 0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    root_account_id bigint
);


--
-- Name: content_participation_counts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.content_participation_counts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: content_participation_counts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.content_participation_counts_id_seq OWNED BY public.content_participation_counts.id;


--
-- Name: content_participations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.content_participations (
    id bigint NOT NULL,
    content_type character varying(255) NOT NULL,
    content_id bigint NOT NULL,
    user_id bigint NOT NULL,
    workflow_state character varying(255) NOT NULL,
    root_account_id bigint,
    content_item character varying DEFAULT 'grade'::character varying NOT NULL
);


--
-- Name: content_participations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.content_participations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: content_participations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.content_participations_id_seq OWNED BY public.content_participations.id;


--
-- Name: content_shares; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.content_shares (
    id bigint NOT NULL,
    name text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id bigint NOT NULL,
    content_export_id bigint NOT NULL,
    sender_id bigint,
    read_state character varying(255) NOT NULL,
    type character varying(255) NOT NULL,
    root_account_id bigint
);


--
-- Name: content_shares_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.content_shares_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: content_shares_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.content_shares_id_seq OWNED BY public.content_shares.id;


--
-- Name: content_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.content_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: content_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.content_tags_id_seq OWNED BY public.content_tags.id;


--
-- Name: context_external_tool_placements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.context_external_tool_placements (
    id bigint NOT NULL,
    placement_type character varying(255),
    context_external_tool_id bigint NOT NULL
);


--
-- Name: context_external_tool_placements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.context_external_tool_placements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: context_external_tool_placements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.context_external_tool_placements_id_seq OWNED BY public.context_external_tool_placements.id;


--
-- Name: context_external_tools; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.context_external_tools (
    id bigint NOT NULL,
    context_id bigint,
    context_type character varying(255),
    domain character varying(255),
    url character varying(4096),
    shared_secret text NOT NULL,
    consumer_key text NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    settings text,
    workflow_state character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    migration_id character varying(255),
    cloned_item_id bigint,
    tool_id character varying(255),
    not_selectable boolean,
    app_center_id character varying(255),
    allow_membership_service_access boolean DEFAULT false NOT NULL,
    developer_key_id bigint,
    root_account_id bigint NOT NULL,
    is_rce_favorite boolean DEFAULT false NOT NULL,
    identity_hash character varying(64),
    lti_version character varying(8) DEFAULT '1.1'::character varying NOT NULL
);


--
-- Name: context_external_tools_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.context_external_tools_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: context_external_tools_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.context_external_tools_id_seq OWNED BY public.context_external_tools.id;


--
-- Name: context_module_progressions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.context_module_progressions (
    id bigint NOT NULL,
    context_module_id bigint,
    user_id bigint,
    requirements_met text,
    workflow_state character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    collapsed boolean,
    current_position integer,
    completed_at timestamp without time zone,
    current boolean,
    lock_version integer DEFAULT 0 NOT NULL,
    evaluated_at timestamp without time zone,
    incomplete_requirements text,
    root_account_id bigint
);


--
-- Name: context_module_progressions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.context_module_progressions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: context_module_progressions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.context_module_progressions_id_seq OWNED BY public.context_module_progressions.id;


--
-- Name: context_modules_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.context_modules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: context_modules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.context_modules_id_seq OWNED BY public.context_modules.id;


--
-- Name: conversation_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conversation_batches (
    id bigint NOT NULL,
    workflow_state character varying(255) NOT NULL,
    user_id bigint NOT NULL,
    recipient_ids text,
    root_conversation_message_id bigint NOT NULL,
    conversation_message_ids text,
    tags text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    context_type character varying(255),
    context_id bigint,
    subject character varying(255),
    "group" boolean,
    generate_user_note boolean
);


--
-- Name: conversation_batches_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.conversation_batches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: conversation_batches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.conversation_batches_id_seq OWNED BY public.conversation_batches.id;


--
-- Name: conversation_message_participants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conversation_message_participants (
    id bigint NOT NULL,
    conversation_message_id bigint,
    conversation_participant_id bigint,
    tags text,
    user_id bigint,
    workflow_state character varying(255),
    deleted_at timestamp without time zone,
    root_account_ids text
);


--
-- Name: conversation_message_participants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.conversation_message_participants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: conversation_message_participants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.conversation_message_participants_id_seq OWNED BY public.conversation_message_participants.id;


--
-- Name: conversation_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conversation_messages (
    id bigint NOT NULL,
    conversation_id bigint,
    author_id bigint,
    created_at timestamp without time zone,
    generated boolean,
    body text,
    forwarded_message_ids text,
    media_comment_id character varying(255),
    media_comment_type character varying(255),
    context_id bigint,
    context_type character varying(255),
    asset_id bigint,
    asset_type character varying(255),
    attachment_ids text,
    has_attachments boolean,
    has_media_objects boolean,
    root_account_ids text
);


--
-- Name: conversation_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.conversation_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: conversation_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.conversation_messages_id_seq OWNED BY public.conversation_messages.id;


--
-- Name: conversation_participants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conversation_participants (
    id bigint NOT NULL,
    conversation_id bigint NOT NULL,
    user_id bigint NOT NULL,
    last_message_at timestamp without time zone,
    subscribed boolean DEFAULT true,
    workflow_state character varying(255) NOT NULL,
    last_authored_at timestamp without time zone,
    has_attachments boolean DEFAULT false NOT NULL,
    has_media_objects boolean DEFAULT false NOT NULL,
    message_count integer DEFAULT 0,
    label character varying(255),
    tags text,
    visible_last_authored_at timestamp without time zone,
    root_account_ids text,
    private_hash character varying(255),
    updated_at timestamp without time zone
);


--
-- Name: conversation_participants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.conversation_participants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: conversation_participants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.conversation_participants_id_seq OWNED BY public.conversation_participants.id;


--
-- Name: conversations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conversations (
    id bigint NOT NULL,
    private_hash character varying(255),
    has_attachments boolean DEFAULT false NOT NULL,
    has_media_objects boolean DEFAULT false NOT NULL,
    tags text,
    root_account_ids text,
    subject character varying(255),
    context_type character varying(255),
    context_id bigint,
    updated_at timestamp without time zone
);


--
-- Name: conversations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.conversations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: conversations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.conversations_id_seq OWNED BY public.conversations.id;


--
-- Name: course_account_associations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.course_account_associations (
    id bigint NOT NULL,
    course_id bigint NOT NULL,
    account_id bigint NOT NULL,
    depth integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    course_section_id bigint,
    root_account_id bigint NOT NULL
);


--
-- Name: course_account_associations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.course_account_associations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: course_account_associations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.course_account_associations_id_seq OWNED BY public.course_account_associations.id;


--
-- Name: course_pace_module_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.course_pace_module_items (
    id bigint NOT NULL,
    course_pace_id bigint,
    duration integer DEFAULT 0 NOT NULL,
    module_item_id bigint,
    root_account_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    migration_id character varying
);


--
-- Name: course_pace_module_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.course_pace_module_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: course_pace_module_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.course_pace_module_items_id_seq OWNED BY public.course_pace_module_items.id;


--
-- Name: course_paces; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.course_paces (
    id bigint NOT NULL,
    course_id bigint NOT NULL,
    course_section_id bigint,
    user_id bigint,
    workflow_state character varying(255) DEFAULT 'unpublished'::character varying NOT NULL,
    end_date date,
    exclude_weekends boolean DEFAULT true NOT NULL,
    hard_end_dates boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    published_at timestamp without time zone,
    root_account_id bigint NOT NULL,
    migration_id character varying
);


--
-- Name: course_paces_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.course_paces_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: course_paces_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.course_paces_id_seq OWNED BY public.course_paces.id;


--
-- Name: course_score_statistics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.course_score_statistics (
    id bigint NOT NULL,
    course_id bigint NOT NULL,
    average numeric(8,2) NOT NULL,
    score_count integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: course_score_statistics_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.course_score_statistics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: course_score_statistics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.course_score_statistics_id_seq OWNED BY public.course_score_statistics.id;


--
-- Name: course_sections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.course_sections (
    id bigint NOT NULL,
    sis_source_id character varying(255),
    sis_batch_id bigint,
    course_id bigint NOT NULL,
    root_account_id bigint NOT NULL,
    enrollment_term_id bigint,
    name character varying(255) NOT NULL,
    default_section boolean,
    accepting_enrollments boolean,
    can_manually_enroll boolean,
    start_at timestamp without time zone,
    end_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    workflow_state character varying(255) DEFAULT 'active'::character varying NOT NULL,
    restrict_enrollments_to_section_dates boolean,
    nonxlist_course_id bigint,
    stuck_sis_fields text,
    integration_id character varying(255)
);


--
-- Name: course_sections_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.course_sections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: course_sections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.course_sections_id_seq OWNED BY public.course_sections.id;


--
-- Name: courses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.courses (
    id bigint NOT NULL,
    name character varying(255),
    account_id bigint NOT NULL,
    group_weighting_scheme character varying(255),
    workflow_state character varying(255) NOT NULL,
    uuid character varying(255),
    start_at timestamp without time zone,
    conclude_at timestamp without time zone,
    grading_standard_id bigint,
    is_public boolean,
    allow_student_wiki_edits boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    show_public_context_messages boolean,
    syllabus_body text,
    allow_student_forum_attachments boolean DEFAULT false,
    default_wiki_editing_roles character varying(255),
    wiki_id bigint,
    allow_student_organized_groups boolean DEFAULT true,
    course_code character varying(255),
    default_view character varying(255),
    abstract_course_id bigint,
    root_account_id bigint NOT NULL,
    enrollment_term_id bigint NOT NULL,
    sis_source_id character varying(255),
    sis_batch_id bigint,
    open_enrollment boolean,
    storage_quota bigint,
    tab_configuration text,
    allow_wiki_comments boolean,
    turnitin_comments text,
    self_enrollment boolean,
    license character varying(255),
    indexed boolean,
    restrict_enrollments_to_course_dates boolean,
    template_course_id bigint,
    locale character varying(255),
    settings text,
    replacement_course_id bigint,
    stuck_sis_fields text,
    public_description text,
    self_enrollment_code character varying(255),
    self_enrollment_limit integer,
    integration_id character varying(255),
    time_zone character varying(255),
    lti_context_id character varying(255),
    turnitin_id bigint,
    show_announcements_on_home_page boolean,
    home_page_announcement_limit integer,
    latest_outcome_import_id bigint,
    grade_passback_setting character varying(255),
    template boolean DEFAULT false NOT NULL,
    homeroom_course boolean DEFAULT false NOT NULL,
    sync_enrollments_from_homeroom boolean DEFAULT false NOT NULL,
    homeroom_course_id bigint,
    deleted_at timestamp(6) without time zone
);


--
-- Name: courses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.courses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: courses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.courses_id_seq OWNED BY public.courses.id;


--
-- Name: crocodoc_documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.crocodoc_documents (
    id bigint NOT NULL,
    uuid character varying(255),
    process_state character varying(255),
    attachment_id bigint,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: crocodoc_documents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.crocodoc_documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: crocodoc_documents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.crocodoc_documents_id_seq OWNED BY public.crocodoc_documents.id;


--
-- Name: csp_domains; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.csp_domains (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    domain character varying(255) NOT NULL,
    workflow_state character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: csp_domains_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.csp_domains_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: csp_domains_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.csp_domains_id_seq OWNED BY public.csp_domains.id;


--
-- Name: custom_data; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.custom_data (
    id bigint NOT NULL,
    data text,
    namespace character varying(255),
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: custom_data_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.custom_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: custom_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.custom_data_id_seq OWNED BY public.custom_data.id;


--
-- Name: custom_grade_statuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.custom_grade_statuses (
    id bigint NOT NULL,
    color character varying(7) NOT NULL,
    name character varying(14) NOT NULL,
    workflow_state character varying(255) DEFAULT 'active'::character varying NOT NULL,
    root_account_id bigint NOT NULL,
    created_by_id bigint NOT NULL,
    deleted_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    applies_to_submissions boolean DEFAULT true NOT NULL,
    applies_to_final_grade boolean DEFAULT true NOT NULL,
    allow_final_grade_value boolean DEFAULT true NOT NULL
);


--
-- Name: custom_grade_statuses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.custom_grade_statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: custom_grade_statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.custom_grade_statuses_id_seq OWNED BY public.custom_grade_statuses.id;


--
-- Name: custom_gradebook_column_data; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.custom_gradebook_column_data (
    id bigint NOT NULL,
    content character varying(255) NOT NULL,
    user_id bigint NOT NULL,
    custom_gradebook_column_id bigint NOT NULL,
    root_account_id bigint
);


--
-- Name: custom_gradebook_column_data_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.custom_gradebook_column_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: custom_gradebook_column_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.custom_gradebook_column_data_id_seq OWNED BY public.custom_gradebook_column_data.id;


--
-- Name: custom_gradebook_columns; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.custom_gradebook_columns (
    id bigint NOT NULL,
    title character varying(255) NOT NULL,
    "position" integer NOT NULL,
    workflow_state character varying(255) DEFAULT 'active'::character varying NOT NULL,
    course_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    teacher_notes boolean DEFAULT false NOT NULL,
    read_only boolean DEFAULT false NOT NULL,
    root_account_id bigint
);


--
-- Name: custom_gradebook_columns_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.custom_gradebook_columns_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: custom_gradebook_columns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.custom_gradebook_columns_id_seq OWNED BY public.custom_gradebook_columns.id;


--
-- Name: delayed_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.delayed_jobs (
    id bigint NOT NULL,
    priority integer DEFAULT 0,
    attempts integer DEFAULT 0,
    handler text,
    last_error text,
    queue character varying(255) NOT NULL,
    run_at timestamp without time zone NOT NULL,
    locked_at timestamp without time zone,
    failed_at timestamp without time zone,
    locked_by character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    tag character varying(255),
    max_attempts integer,
    strand character varying(255),
    next_in_strand boolean DEFAULT true NOT NULL,
    shard_id bigint,
    source character varying(255),
    max_concurrent integer DEFAULT 1 NOT NULL,
    expires_at timestamp without time zone,
    strand_order_override integer DEFAULT 0 NOT NULL,
    singleton character varying
);


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.delayed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.delayed_jobs_id_seq OWNED BY public.delayed_jobs.id;


--
-- Name: delayed_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.delayed_messages (
    id bigint NOT NULL,
    notification_id bigint,
    notification_policy_id bigint,
    context_id bigint,
    context_type character varying(255),
    communication_channel_id bigint,
    frequency character varying(255),
    workflow_state character varying(255),
    batched_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    send_at timestamp without time zone,
    link text,
    name_of_topic text,
    summary text,
    root_account_id bigint,
    notification_policy_override_id bigint
);


--
-- Name: delayed_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.delayed_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delayed_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.delayed_messages_id_seq OWNED BY public.delayed_messages.id;


--
-- Name: delayed_notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.delayed_notifications (
    id bigint NOT NULL,
    notification_id bigint NOT NULL,
    asset_id bigint NOT NULL,
    asset_type character varying(255) NOT NULL,
    recipient_keys text,
    workflow_state character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: delayed_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.delayed_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delayed_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.delayed_notifications_id_seq OWNED BY public.delayed_notifications.id;


--
-- Name: developer_key_account_bindings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.developer_key_account_bindings (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    developer_key_id bigint NOT NULL,
    workflow_state character varying DEFAULT 'off'::character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    root_account_id bigint NOT NULL
);


--
-- Name: developer_key_account_bindings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.developer_key_account_bindings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: developer_key_account_bindings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.developer_key_account_bindings_id_seq OWNED BY public.developer_key_account_bindings.id;


--
-- Name: developer_keys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.developer_keys (
    id bigint NOT NULL,
    api_key character varying(255),
    email character varying(255),
    user_name character varying(255),
    account_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id bigint,
    name character varying(255),
    redirect_uri character varying(255),
    icon_url character varying(255),
    sns_arn character varying(255),
    trusted boolean,
    force_token_reuse boolean,
    workflow_state character varying(255) DEFAULT 'active'::character varying NOT NULL,
    replace_tokens boolean,
    auto_expire_tokens boolean DEFAULT false NOT NULL,
    redirect_uris character varying(4096)[] DEFAULT '{}'::character varying[] NOT NULL,
    notes text,
    access_token_count integer DEFAULT 0 NOT NULL,
    vendor_code character varying,
    visible boolean DEFAULT false NOT NULL,
    scopes text,
    require_scopes boolean DEFAULT false NOT NULL,
    test_cluster_only boolean DEFAULT false NOT NULL,
    public_jwk jsonb,
    internal_service boolean DEFAULT false NOT NULL,
    oidc_initiation_url text,
    public_jwk_url character varying,
    is_lti_key boolean DEFAULT false NOT NULL,
    allow_includes boolean DEFAULT false NOT NULL,
    root_account_id bigint NOT NULL,
    client_credentials_audience character varying,
    service_user_id bigint
);


--
-- Name: developer_keys_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.developer_keys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: developer_keys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.developer_keys_id_seq OWNED BY public.developer_keys.id;


--
-- Name: discussion_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.discussion_entries (
    id bigint NOT NULL,
    message text,
    discussion_topic_id bigint,
    user_id bigint,
    parent_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    attachment_id bigint,
    workflow_state character varying(255) DEFAULT 'active'::character varying,
    deleted_at timestamp without time zone,
    migration_id character varying(255),
    editor_id bigint,
    root_entry_id bigint,
    depth integer,
    rating_count integer,
    rating_sum integer,
    root_account_id bigint NOT NULL,
    legacy boolean DEFAULT true NOT NULL,
    include_reply_preview boolean DEFAULT false NOT NULL,
    is_anonymous_author boolean DEFAULT false NOT NULL,
    quoted_entry_id bigint
);


--
-- Name: discussion_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.discussion_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: discussion_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.discussion_entries_id_seq OWNED BY public.discussion_entries.id;


--
-- Name: discussion_entry_drafts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.discussion_entry_drafts (
    id bigint NOT NULL,
    discussion_topic_id bigint NOT NULL,
    discussion_entry_id bigint,
    root_entry_id bigint,
    parent_id bigint,
    attachment_id bigint,
    user_id bigint NOT NULL,
    message text,
    include_reply_preview boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: discussion_entry_drafts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.discussion_entry_drafts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: discussion_entry_drafts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.discussion_entry_drafts_id_seq OWNED BY public.discussion_entry_drafts.id;


--
-- Name: discussion_entry_participants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.discussion_entry_participants (
    id bigint NOT NULL,
    discussion_entry_id bigint NOT NULL,
    user_id bigint NOT NULL,
    workflow_state character varying(255) NOT NULL,
    forced_read_state boolean,
    rating integer,
    root_account_id bigint NOT NULL,
    report_type character varying(255),
    read_at timestamp without time zone
);


--
-- Name: discussion_entry_participants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.discussion_entry_participants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: discussion_entry_participants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.discussion_entry_participants_id_seq OWNED BY public.discussion_entry_participants.id;


--
-- Name: discussion_entry_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.discussion_entry_versions (
    id bigint NOT NULL,
    discussion_entry_id bigint NOT NULL,
    root_account_id bigint NOT NULL,
    user_id bigint,
    version bigint,
    message text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: discussion_entry_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.discussion_entry_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: discussion_entry_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.discussion_entry_versions_id_seq OWNED BY public.discussion_entry_versions.id;


--
-- Name: discussion_topic_materialized_views; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.discussion_topic_materialized_views (
    discussion_topic_id bigint NOT NULL,
    json_structure text,
    participants_array text,
    entry_ids_array text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    generation_started_at timestamp without time zone
);


--
-- Name: discussion_topic_participants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.discussion_topic_participants (
    id bigint NOT NULL,
    discussion_topic_id bigint NOT NULL,
    user_id bigint NOT NULL,
    unread_entry_count integer DEFAULT 0 NOT NULL,
    workflow_state character varying(255) NOT NULL,
    subscribed boolean,
    root_account_id bigint NOT NULL
);


--
-- Name: discussion_topic_participants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.discussion_topic_participants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: discussion_topic_participants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.discussion_topic_participants_id_seq OWNED BY public.discussion_topic_participants.id;


--
-- Name: discussion_topic_section_visibilities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.discussion_topic_section_visibilities (
    id bigint NOT NULL,
    discussion_topic_id bigint NOT NULL,
    course_section_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    workflow_state character varying(255) NOT NULL
);


--
-- Name: discussion_topic_section_visibilities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.discussion_topic_section_visibilities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: discussion_topic_section_visibilities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.discussion_topic_section_visibilities_id_seq OWNED BY public.discussion_topic_section_visibilities.id;


--
-- Name: discussion_topics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.discussion_topics (
    id bigint NOT NULL,
    title character varying(255),
    message text,
    context_id bigint NOT NULL,
    context_type character varying(255) NOT NULL,
    type character varying(255),
    user_id bigint,
    workflow_state character varying(255) NOT NULL,
    last_reply_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    delayed_post_at timestamp without time zone,
    posted_at timestamp without time zone,
    assignment_id bigint,
    attachment_id bigint,
    deleted_at timestamp without time zone,
    root_topic_id bigint,
    could_be_locked boolean DEFAULT false NOT NULL,
    cloned_item_id bigint,
    context_code character varying(255),
    "position" integer,
    migration_id character varying(255),
    old_assignment_id bigint,
    subtopics_refreshed_at timestamp without time zone,
    last_assignment_id bigint,
    external_feed_id bigint,
    editor_id bigint,
    podcast_enabled boolean DEFAULT false NOT NULL,
    podcast_has_student_posts boolean DEFAULT false NOT NULL,
    require_initial_post boolean DEFAULT false NOT NULL,
    discussion_type character varying(255),
    lock_at timestamp without time zone,
    pinned boolean DEFAULT false NOT NULL,
    locked boolean DEFAULT false NOT NULL,
    group_category_id bigint,
    allow_rating boolean DEFAULT false NOT NULL,
    only_graders_can_rate boolean DEFAULT false NOT NULL,
    sort_by_rating boolean DEFAULT false NOT NULL,
    todo_date timestamp without time zone,
    is_section_specific boolean DEFAULT false NOT NULL,
    root_account_id bigint NOT NULL,
    anonymous_state character varying(255),
    is_anonymous_author boolean DEFAULT false NOT NULL,
    reply_to_entry_required_count integer DEFAULT 0 NOT NULL,
    unlock_at timestamp(6) without time zone,
    only_visible_to_overrides boolean DEFAULT false NOT NULL
);


--
-- Name: discussion_topics_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.discussion_topics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: discussion_topics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.discussion_topics_id_seq OWNED BY public.discussion_topics.id;


--
-- Name: enrollment_dates_overrides; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.enrollment_dates_overrides (
    id bigint NOT NULL,
    enrollment_term_id bigint,
    enrollment_type character varying(255),
    context_id bigint NOT NULL,
    context_type character varying(255),
    start_at timestamp without time zone,
    end_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    root_account_id bigint,
    stuck_sis_fields text
);


--
-- Name: enrollment_dates_overrides_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.enrollment_dates_overrides_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: enrollment_dates_overrides_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.enrollment_dates_overrides_id_seq OWNED BY public.enrollment_dates_overrides.id;


--
-- Name: enrollment_states; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.enrollment_states (
    enrollment_id bigint NOT NULL,
    state character varying(255),
    state_is_current boolean DEFAULT false NOT NULL,
    state_started_at timestamp without time zone,
    state_valid_until timestamp without time zone,
    restricted_access boolean DEFAULT false NOT NULL,
    access_is_current boolean DEFAULT false NOT NULL,
    lock_version integer DEFAULT 0 NOT NULL,
    updated_at timestamp without time zone,
    root_account_id bigint NOT NULL
);


--
-- Name: enrollment_terms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.enrollment_terms (
    id bigint NOT NULL,
    root_account_id bigint NOT NULL,
    name character varying(255),
    term_code character varying(255),
    sis_source_id character varying(255),
    sis_batch_id bigint,
    start_at timestamp without time zone,
    end_at timestamp without time zone,
    accepting_enrollments boolean,
    can_manually_enroll boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    workflow_state character varying(255) DEFAULT 'active'::character varying NOT NULL,
    stuck_sis_fields text,
    integration_id character varying(255),
    grading_period_group_id bigint
);


--
-- Name: enrollment_terms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.enrollment_terms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: enrollment_terms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.enrollment_terms_id_seq OWNED BY public.enrollment_terms.id;


--
-- Name: enrollments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.enrollments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: enrollments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.enrollments_id_seq OWNED BY public.enrollments.id;


--
-- Name: eportfolio_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.eportfolio_categories (
    id bigint NOT NULL,
    eportfolio_id bigint NOT NULL,
    name character varying(255),
    "position" integer,
    slug character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: eportfolio_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.eportfolio_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: eportfolio_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.eportfolio_categories_id_seq OWNED BY public.eportfolio_categories.id;


--
-- Name: eportfolio_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.eportfolio_entries (
    id bigint NOT NULL,
    eportfolio_id bigint NOT NULL,
    eportfolio_category_id bigint NOT NULL,
    "position" integer,
    name character varying(255),
    allow_comments boolean,
    show_comments boolean,
    slug character varying(255),
    content text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: eportfolio_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.eportfolio_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: eportfolio_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.eportfolio_entries_id_seq OWNED BY public.eportfolio_entries.id;


--
-- Name: eportfolios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.eportfolios (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    name character varying(255),
    public boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    uuid character varying(255),
    workflow_state character varying(255) DEFAULT 'active'::character varying NOT NULL,
    deleted_at timestamp without time zone,
    spam_status character varying
);


--
-- Name: eportfolios_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.eportfolios_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: eportfolios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.eportfolios_id_seq OWNED BY public.eportfolios.id;


--
-- Name: epub_exports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.epub_exports (
    id bigint NOT NULL,
    content_export_id bigint,
    course_id bigint,
    user_id bigint,
    workflow_state character varying(255) DEFAULT 'created'::character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    type character varying(255)
);


--
-- Name: epub_exports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.epub_exports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: epub_exports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.epub_exports_id_seq OWNED BY public.epub_exports.id;


--
-- Name: error_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.error_reports (
    id bigint NOT NULL,
    backtrace text,
    url text,
    message text,
    comments text,
    user_id bigint,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    email character varying(255),
    during_tests boolean DEFAULT false,
    user_agent text,
    request_method character varying(255),
    http_env text,
    subject text,
    request_context_id character varying(255),
    account_id bigint,
    zendesk_ticket_id bigint,
    data text,
    category character varying(255)
);


--
-- Name: error_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.error_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: error_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.error_reports_id_seq OWNED BY public.error_reports.id;


--
-- Name: event_stream_failures; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.event_stream_failures (
    id bigint NOT NULL,
    operation character varying(255) NOT NULL,
    event_stream character varying(255) NOT NULL,
    record_id character varying(255) NOT NULL,
    payload text NOT NULL,
    exception text,
    backtrace text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: event_stream_failures_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.event_stream_failures_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: event_stream_failures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.event_stream_failures_id_seq OWNED BY public.event_stream_failures.id;


--
-- Name: external_feed_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.external_feed_entries (
    id bigint NOT NULL,
    user_id bigint,
    external_feed_id bigint NOT NULL,
    title text,
    message text,
    source_name character varying(255),
    source_url text,
    posted_at timestamp without time zone,
    workflow_state character varying(255) NOT NULL,
    url text,
    author_name character varying(255),
    author_email character varying(255),
    author_url text,
    asset_id bigint,
    asset_type character varying(255),
    uuid character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: external_feed_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.external_feed_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: external_feed_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.external_feed_entries_id_seq OWNED BY public.external_feed_entries.id;


--
-- Name: external_feeds; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.external_feeds (
    id bigint NOT NULL,
    user_id bigint,
    context_id bigint NOT NULL,
    context_type character varying(255) NOT NULL,
    consecutive_failures integer,
    failures integer,
    refresh_at timestamp without time zone,
    title character varying(255),
    url character varying(255) NOT NULL,
    header_match character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    verbosity character varying(255),
    migration_id character varying(255)
);


--
-- Name: external_feeds_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.external_feeds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: external_feeds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.external_feeds_id_seq OWNED BY public.external_feeds.id;


--
-- Name: external_integration_keys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.external_integration_keys (
    id bigint NOT NULL,
    context_id bigint NOT NULL,
    context_type character varying(255) NOT NULL,
    key_value character varying(255) NOT NULL,
    key_type character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: external_integration_keys_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.external_integration_keys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: external_integration_keys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.external_integration_keys_id_seq OWNED BY public.external_integration_keys.id;


--
-- Name: failed_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.failed_jobs (
    id bigint NOT NULL,
    priority integer DEFAULT 0,
    attempts integer DEFAULT 0,
    handler text,
    last_error text,
    queue character varying(255),
    run_at timestamp without time zone,
    locked_at timestamp without time zone,
    failed_at timestamp without time zone,
    locked_by character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    tag character varying(255),
    max_attempts integer,
    strand character varying(255),
    shard_id bigint,
    original_job_id bigint,
    source character varying(255),
    expires_at timestamp without time zone,
    strand_order_override integer DEFAULT 0 NOT NULL,
    singleton character varying,
    requeued_job_id bigint
);


--
-- Name: failed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.failed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: failed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.failed_jobs_id_seq OWNED BY public.failed_jobs.id;


--
-- Name: favorites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.favorites (
    id bigint NOT NULL,
    user_id bigint,
    context_id bigint,
    context_type character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    root_account_id bigint NOT NULL
);


--
-- Name: favorites_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.favorites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: favorites_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.favorites_id_seq OWNED BY public.favorites.id;


--
-- Name: feature_flags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.feature_flags (
    id bigint NOT NULL,
    context_id bigint NOT NULL,
    context_type character varying(255) NOT NULL,
    feature character varying(255) NOT NULL,
    state character varying(255) DEFAULT 'allowed'::character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: feature_flags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.feature_flags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feature_flags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.feature_flags_id_seq OWNED BY public.feature_flags.id;


--
-- Name: folders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.folders (
    id bigint NOT NULL,
    name character varying(255),
    full_name text,
    context_id bigint NOT NULL,
    context_type character varying(255) NOT NULL,
    parent_folder_id bigint,
    workflow_state character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    locked boolean,
    lock_at timestamp without time zone,
    unlock_at timestamp without time zone,
    cloned_item_id bigint,
    "position" integer,
    submission_context_code character varying(255),
    unique_type character varying,
    root_account_id bigint NOT NULL
);


--
-- Name: folders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.folders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: folders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.folders_id_seq OWNED BY public.folders.id;


--
-- Name: gradebook_csvs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.gradebook_csvs (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    attachment_id bigint NOT NULL,
    progress_id bigint NOT NULL,
    course_id bigint NOT NULL
);


--
-- Name: gradebook_csvs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.gradebook_csvs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: gradebook_csvs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.gradebook_csvs_id_seq OWNED BY public.gradebook_csvs.id;


--
-- Name: gradebook_filters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.gradebook_filters (
    id bigint NOT NULL,
    course_id bigint NOT NULL,
    user_id bigint NOT NULL,
    name character varying(255) NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: gradebook_filters_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.gradebook_filters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: gradebook_filters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.gradebook_filters_id_seq OWNED BY public.gradebook_filters.id;


--
-- Name: gradebook_uploads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.gradebook_uploads (
    id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    course_id bigint NOT NULL,
    user_id bigint NOT NULL,
    progress_id bigint NOT NULL,
    gradebook text
);


--
-- Name: gradebook_uploads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.gradebook_uploads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: gradebook_uploads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.gradebook_uploads_id_seq OWNED BY public.gradebook_uploads.id;


--
-- Name: grading_period_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.grading_period_groups (
    id bigint NOT NULL,
    course_id bigint,
    account_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    workflow_state character varying(255) DEFAULT 'active'::character varying NOT NULL,
    title character varying(255),
    weighted boolean,
    display_totals_for_all_grading_periods boolean DEFAULT false NOT NULL,
    root_account_id bigint
);


--
-- Name: grading_period_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.grading_period_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: grading_period_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.grading_period_groups_id_seq OWNED BY public.grading_period_groups.id;


--
-- Name: grading_periods; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.grading_periods (
    id bigint NOT NULL,
    weight double precision,
    start_date timestamp without time zone NOT NULL,
    end_date timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    title character varying(255),
    workflow_state character varying(255) DEFAULT 'active'::character varying NOT NULL,
    grading_period_group_id bigint NOT NULL,
    close_date timestamp without time zone,
    root_account_id bigint
);


--
-- Name: grading_periods_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.grading_periods_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: grading_periods_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.grading_periods_id_seq OWNED BY public.grading_periods.id;


--
-- Name: grading_standards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.grading_standards (
    id bigint NOT NULL,
    title character varying(255),
    data text,
    context_id bigint NOT NULL,
    context_type character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id bigint,
    usage_count integer,
    context_code character varying(255),
    workflow_state character varying(255) NOT NULL,
    migration_id character varying(255),
    version integer,
    root_account_id bigint,
    points_based boolean DEFAULT false NOT NULL,
    scaling_factor numeric(5,2) DEFAULT 1.0 NOT NULL
);


--
-- Name: grading_standards_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.grading_standards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: grading_standards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.grading_standards_id_seq OWNED BY public.grading_standards.id;


--
-- Name: group_and_membership_importers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.group_and_membership_importers (
    id bigint NOT NULL,
    group_category_id bigint NOT NULL,
    attachment_id bigint,
    workflow_state character varying DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: group_and_membership_importers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.group_and_membership_importers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: group_and_membership_importers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.group_and_membership_importers_id_seq OWNED BY public.group_and_membership_importers.id;


--
-- Name: group_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.group_categories (
    id bigint NOT NULL,
    context_id bigint,
    context_type character varying(255),
    name character varying(255),
    role character varying(255),
    deleted_at timestamp without time zone,
    self_signup character varying(255),
    group_limit integer,
    auto_leader character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    sis_source_id character varying,
    root_account_id bigint NOT NULL,
    sis_batch_id bigint
);


--
-- Name: group_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.group_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: group_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.group_categories_id_seq OWNED BY public.group_categories.id;


--
-- Name: group_memberships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.group_memberships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: group_memberships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.group_memberships_id_seq OWNED BY public.group_memberships.id;


--
-- Name: groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.groups_id_seq OWNED BY public.groups.id;


--
-- Name: ignores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ignores (
    id bigint NOT NULL,
    asset_type character varying(255) NOT NULL,
    asset_id bigint NOT NULL,
    user_id bigint NOT NULL,
    purpose character varying(255) NOT NULL,
    permanent boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ignores_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ignores_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ignores_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ignores_id_seq OWNED BY public.ignores.id;


--
-- Name: late_policies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.late_policies (
    id bigint NOT NULL,
    course_id bigint NOT NULL,
    missing_submission_deduction_enabled boolean DEFAULT false NOT NULL,
    missing_submission_deduction numeric(5,2) DEFAULT 100.0 NOT NULL,
    late_submission_deduction_enabled boolean DEFAULT false NOT NULL,
    late_submission_deduction numeric(5,2) DEFAULT 0.0 NOT NULL,
    late_submission_interval character varying(16) DEFAULT 'day'::character varying NOT NULL,
    late_submission_minimum_percent_enabled boolean DEFAULT false NOT NULL,
    late_submission_minimum_percent numeric(5,2) DEFAULT 0.0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    root_account_id bigint
);


--
-- Name: late_policies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.late_policies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: late_policies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.late_policies_id_seq OWNED BY public.late_policies.id;


--
-- Name: learning_outcome_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.learning_outcome_groups (
    id bigint NOT NULL,
    context_id bigint,
    context_type character varying(255),
    title character varying(255) NOT NULL,
    learning_outcome_group_id bigint,
    root_learning_outcome_group_id bigint,
    workflow_state character varying(255) NOT NULL,
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    migration_id character varying(255),
    vendor_guid character varying(255),
    low_grade character varying(255),
    high_grade character varying(255),
    vendor_guid_2 character varying(255),
    migration_id_2 character varying(255),
    outcome_import_id bigint,
    root_account_id bigint,
    source_outcome_group_id bigint,
    archived_at timestamp(6) without time zone DEFAULT NULL::timestamp without time zone
);


--
-- Name: learning_outcome_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.learning_outcome_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: learning_outcome_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.learning_outcome_groups_id_seq OWNED BY public.learning_outcome_groups.id;


--
-- Name: learning_outcome_question_results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.learning_outcome_question_results (
    id bigint NOT NULL,
    learning_outcome_result_id bigint,
    learning_outcome_id bigint,
    associated_asset_id bigint,
    associated_asset_type character varying(255),
    score double precision,
    possible double precision,
    mastery boolean,
    percent double precision,
    attempt integer,
    title text,
    original_score double precision,
    original_possible double precision,
    original_mastery boolean,
    assessed_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    submitted_at timestamp without time zone,
    root_account_id bigint
);


--
-- Name: learning_outcome_question_results_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.learning_outcome_question_results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: learning_outcome_question_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.learning_outcome_question_results_id_seq OWNED BY public.learning_outcome_question_results.id;


--
-- Name: learning_outcome_results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.learning_outcome_results (
    id bigint NOT NULL,
    context_id bigint,
    context_type character varying(255),
    context_code character varying(255),
    association_id bigint,
    association_type character varying(255),
    content_tag_id bigint,
    learning_outcome_id bigint,
    mastery boolean,
    user_id bigint,
    score double precision,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    attempt integer,
    possible double precision,
    original_score double precision,
    original_possible double precision,
    original_mastery boolean,
    artifact_id bigint,
    artifact_type character varying(255),
    assessed_at timestamp without time zone,
    title character varying(255),
    percent double precision,
    associated_asset_id bigint,
    associated_asset_type character varying(255),
    submitted_at timestamp without time zone,
    hide_points boolean DEFAULT false NOT NULL,
    hidden boolean DEFAULT false NOT NULL,
    user_uuid character varying(255),
    root_account_id bigint,
    workflow_state character varying DEFAULT 'active'::character varying NOT NULL
);


--
-- Name: learning_outcome_results_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.learning_outcome_results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: learning_outcome_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.learning_outcome_results_id_seq OWNED BY public.learning_outcome_results.id;


--
-- Name: learning_outcomes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.learning_outcomes (
    id bigint NOT NULL,
    context_id bigint,
    context_type character varying(255),
    short_description character varying(255) NOT NULL,
    context_code character varying(255),
    description text,
    data text,
    workflow_state character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    migration_id character varying(255),
    vendor_guid character varying(255),
    low_grade character varying(255),
    high_grade character varying(255),
    display_name character varying(255),
    calculation_method character varying(255),
    calculation_int smallint,
    vendor_guid_2 character varying(255),
    migration_id_2 character varying(255),
    outcome_import_id bigint,
    root_account_ids bigint[],
    copied_from_outcome_id bigint,
    archived_at timestamp(6) without time zone DEFAULT NULL::timestamp without time zone
);


--
-- Name: learning_outcomes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.learning_outcomes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: learning_outcomes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.learning_outcomes_id_seq OWNED BY public.learning_outcomes.id;


--
-- Name: live_assessments_assessments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.live_assessments_assessments (
    id bigint NOT NULL,
    key character varying(255) NOT NULL,
    title character varying(255) NOT NULL,
    context_id bigint NOT NULL,
    context_type character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: live_assessments_assessments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.live_assessments_assessments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: live_assessments_assessments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.live_assessments_assessments_id_seq OWNED BY public.live_assessments_assessments.id;


--
-- Name: live_assessments_results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.live_assessments_results (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    assessor_id bigint NOT NULL,
    assessment_id bigint NOT NULL,
    passed boolean NOT NULL,
    assessed_at timestamp without time zone NOT NULL
);


--
-- Name: live_assessments_results_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.live_assessments_results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: live_assessments_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.live_assessments_results_id_seq OWNED BY public.live_assessments_results.id;


--
-- Name: live_assessments_submissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.live_assessments_submissions (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    assessment_id bigint NOT NULL,
    possible double precision,
    score double precision,
    assessed_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: live_assessments_submissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.live_assessments_submissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: live_assessments_submissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.live_assessments_submissions_id_seq OWNED BY public.live_assessments_submissions.id;


--
-- Name: lti_ims_registrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lti_ims_registrations (
    id bigint NOT NULL,
    lti_tool_configuration jsonb NOT NULL,
    developer_key_id bigint NOT NULL,
    application_type character varying NOT NULL,
    grant_types text[] DEFAULT '{}'::text[] NOT NULL,
    response_types text[] DEFAULT '{}'::text[] NOT NULL,
    redirect_uris text[] DEFAULT '{}'::text[] NOT NULL,
    initiate_login_uri text NOT NULL,
    client_name character varying NOT NULL,
    jwks_uri text NOT NULL,
    logo_uri text,
    token_endpoint_auth_method character varying NOT NULL,
    contacts character varying(255)[] DEFAULT '{}'::character varying[] NOT NULL,
    client_uri text,
    policy_uri text,
    tos_uri text,
    scopes text[] DEFAULT '{}'::text[] NOT NULL,
    root_account_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    guid character varying,
    registration_overlay jsonb DEFAULT '{}'::jsonb
);


--
-- Name: lti_ims_registrations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lti_ims_registrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lti_ims_registrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lti_ims_registrations_id_seq OWNED BY public.lti_ims_registrations.id;


--
-- Name: lti_line_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lti_line_items (
    id bigint NOT NULL,
    score_maximum double precision NOT NULL,
    label character varying NOT NULL,
    resource_id character varying,
    tag character varying,
    lti_resource_link_id bigint,
    assignment_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    client_id bigint NOT NULL,
    workflow_state character varying DEFAULT 'active'::character varying NOT NULL,
    extensions jsonb DEFAULT '{}'::jsonb,
    root_account_id bigint NOT NULL,
    coupled boolean DEFAULT true NOT NULL,
    end_date_time timestamp without time zone,
    start_date_time timestamp(6) without time zone
);


--
-- Name: lti_line_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lti_line_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lti_line_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lti_line_items_id_seq OWNED BY public.lti_line_items.id;


--
-- Name: lti_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lti_links (
    id bigint NOT NULL,
    resource_link_id character varying NOT NULL,
    vendor_code character varying NOT NULL,
    product_code character varying NOT NULL,
    resource_type_code character varying NOT NULL,
    linkable_id bigint,
    linkable_type character varying,
    custom_parameters text,
    resource_url text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: lti_links_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lti_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lti_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lti_links_id_seq OWNED BY public.lti_links.id;


--
-- Name: lti_message_handlers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lti_message_handlers (
    id bigint NOT NULL,
    message_type character varying(255) NOT NULL,
    launch_path character varying(255) NOT NULL,
    capabilities text,
    parameters text,
    resource_handler_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    tool_proxy_id bigint
);


--
-- Name: lti_message_handlers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lti_message_handlers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lti_message_handlers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lti_message_handlers_id_seq OWNED BY public.lti_message_handlers.id;


--
-- Name: lti_product_families; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lti_product_families (
    id bigint NOT NULL,
    vendor_code character varying(255) NOT NULL,
    product_code character varying(255) NOT NULL,
    vendor_name character varying(255) NOT NULL,
    vendor_description text,
    website character varying(255),
    vendor_email character varying(255),
    root_account_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    developer_key_id bigint
);


--
-- Name: lti_product_families_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lti_product_families_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lti_product_families_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lti_product_families_id_seq OWNED BY public.lti_product_families.id;


--
-- Name: lti_resource_handlers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lti_resource_handlers (
    id bigint NOT NULL,
    resource_type_code character varying(255) NOT NULL,
    placements character varying(255),
    name character varying(255) NOT NULL,
    description text,
    icon_info text,
    tool_proxy_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: lti_resource_handlers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lti_resource_handlers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lti_resource_handlers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lti_resource_handlers_id_seq OWNED BY public.lti_resource_handlers.id;


--
-- Name: lti_resource_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lti_resource_links (
    id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    context_external_tool_id bigint NOT NULL,
    workflow_state character varying DEFAULT 'active'::character varying NOT NULL,
    root_account_id bigint NOT NULL,
    context_id bigint NOT NULL,
    context_type character varying(255) NOT NULL,
    custom jsonb,
    lookup_uuid uuid NOT NULL,
    resource_link_uuid uuid NOT NULL,
    url character varying,
    lti_1_1_id character varying,
    title character varying
);


--
-- Name: lti_resource_links_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lti_resource_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lti_resource_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lti_resource_links_id_seq OWNED BY public.lti_resource_links.id;


--
-- Name: lti_resource_placements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lti_resource_placements (
    id bigint NOT NULL,
    placement character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    message_handler_id bigint
);


--
-- Name: lti_resource_placements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lti_resource_placements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lti_resource_placements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lti_resource_placements_id_seq OWNED BY public.lti_resource_placements.id;


--
-- Name: lti_results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lti_results (
    id bigint NOT NULL,
    result_score double precision,
    result_maximum double precision,
    comment text,
    activity_progress character varying,
    grading_progress character varying,
    lti_line_item_id bigint NOT NULL,
    submission_id bigint,
    user_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    workflow_state character varying DEFAULT 'active'::character varying NOT NULL,
    extensions jsonb DEFAULT '{}'::jsonb,
    root_account_id bigint NOT NULL
);


--
-- Name: lti_results_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lti_results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lti_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lti_results_id_seq OWNED BY public.lti_results.id;


--
-- Name: lti_tool_configurations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lti_tool_configurations (
    id bigint NOT NULL,
    developer_key_id bigint NOT NULL,
    settings jsonb NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    disabled_placements character varying[] DEFAULT '{}'::character varying[],
    privacy_level character varying
);


--
-- Name: lti_tool_configurations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lti_tool_configurations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lti_tool_configurations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lti_tool_configurations_id_seq OWNED BY public.lti_tool_configurations.id;


--
-- Name: lti_tool_consumer_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lti_tool_consumer_profiles (
    id bigint NOT NULL,
    services text,
    capabilities text,
    uuid character varying NOT NULL,
    developer_key_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: lti_tool_consumer_profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lti_tool_consumer_profiles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lti_tool_consumer_profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lti_tool_consumer_profiles_id_seq OWNED BY public.lti_tool_consumer_profiles.id;


--
-- Name: lti_tool_proxies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lti_tool_proxies (
    id bigint NOT NULL,
    shared_secret text NOT NULL,
    guid character varying(255) NOT NULL,
    product_version character varying(255) NOT NULL,
    lti_version character varying(255) NOT NULL,
    product_family_id bigint NOT NULL,
    context_id bigint NOT NULL,
    workflow_state character varying(255) NOT NULL,
    raw_data text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    context_type character varying(255) DEFAULT 'Account'::character varying NOT NULL,
    name character varying(255),
    description text,
    update_payload text,
    registration_url text,
    subscription_id character varying
);


--
-- Name: lti_tool_proxies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lti_tool_proxies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lti_tool_proxies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lti_tool_proxies_id_seq OWNED BY public.lti_tool_proxies.id;


--
-- Name: lti_tool_proxy_bindings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lti_tool_proxy_bindings (
    id bigint NOT NULL,
    context_id bigint NOT NULL,
    context_type character varying(255) NOT NULL,
    tool_proxy_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    enabled boolean DEFAULT true NOT NULL
);


--
-- Name: lti_tool_proxy_bindings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lti_tool_proxy_bindings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lti_tool_proxy_bindings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lti_tool_proxy_bindings_id_seq OWNED BY public.lti_tool_proxy_bindings.id;


--
-- Name: lti_tool_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lti_tool_settings (
    id bigint NOT NULL,
    tool_proxy_id bigint,
    context_id bigint,
    context_type character varying(255),
    resource_link_id text,
    custom text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    product_code character varying,
    vendor_code character varying,
    resource_type_code character varying,
    custom_parameters text,
    resource_url text
);


--
-- Name: lti_tool_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lti_tool_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lti_tool_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lti_tool_settings_id_seq OWNED BY public.lti_tool_settings.id;


--
-- Name: master_courses_child_content_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.master_courses_child_content_tags (
    id bigint NOT NULL,
    child_subscription_id bigint NOT NULL,
    content_type character varying(255) NOT NULL,
    content_id bigint NOT NULL,
    downstream_changes text,
    migration_id character varying,
    root_account_id bigint
);


--
-- Name: master_courses_child_content_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.master_courses_child_content_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: master_courses_child_content_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.master_courses_child_content_tags_id_seq OWNED BY public.master_courses_child_content_tags.id;


--
-- Name: master_courses_child_subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.master_courses_child_subscriptions (
    id bigint NOT NULL,
    master_template_id bigint NOT NULL,
    child_course_id bigint NOT NULL,
    workflow_state character varying(255) NOT NULL,
    use_selective_copy boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    root_account_id bigint
);


--
-- Name: master_courses_child_subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.master_courses_child_subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: master_courses_child_subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.master_courses_child_subscriptions_id_seq OWNED BY public.master_courses_child_subscriptions.id;


--
-- Name: master_courses_master_content_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.master_courses_master_content_tags (
    id bigint NOT NULL,
    master_template_id bigint NOT NULL,
    content_type character varying(255) NOT NULL,
    content_id bigint NOT NULL,
    current_migration_id bigint,
    restrictions text,
    migration_id character varying,
    use_default_restrictions boolean DEFAULT false NOT NULL,
    root_account_id bigint
);


--
-- Name: master_courses_master_content_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.master_courses_master_content_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: master_courses_master_content_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.master_courses_master_content_tags_id_seq OWNED BY public.master_courses_master_content_tags.id;


--
-- Name: master_courses_master_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.master_courses_master_migrations (
    id bigint NOT NULL,
    master_template_id bigint NOT NULL,
    user_id bigint,
    export_results text,
    exports_started_at timestamp without time zone,
    imports_queued_at timestamp without time zone,
    workflow_state character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    imports_completed_at timestamp without time zone,
    comment text,
    send_notification boolean DEFAULT false NOT NULL,
    migration_settings text,
    root_account_id bigint
);


--
-- Name: master_courses_master_migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.master_courses_master_migrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: master_courses_master_migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.master_courses_master_migrations_id_seq OWNED BY public.master_courses_master_migrations.id;


--
-- Name: master_courses_master_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.master_courses_master_templates (
    id bigint NOT NULL,
    course_id bigint NOT NULL,
    full_course boolean DEFAULT true NOT NULL,
    workflow_state character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    active_migration_id bigint,
    default_restrictions text,
    use_default_restrictions_by_type boolean DEFAULT false NOT NULL,
    default_restrictions_by_type text,
    root_account_id bigint
);


--
-- Name: master_courses_master_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.master_courses_master_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: master_courses_master_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.master_courses_master_templates_id_seq OWNED BY public.master_courses_master_templates.id;


--
-- Name: master_courses_migration_results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.master_courses_migration_results (
    id bigint NOT NULL,
    master_migration_id bigint NOT NULL,
    content_migration_id bigint NOT NULL,
    child_subscription_id bigint NOT NULL,
    import_type character varying NOT NULL,
    state character varying NOT NULL,
    results text,
    root_account_id bigint
);


--
-- Name: master_courses_migration_results_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.master_courses_migration_results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: master_courses_migration_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.master_courses_migration_results_id_seq OWNED BY public.master_courses_migration_results.id;


--
-- Name: media_objects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.media_objects (
    id bigint NOT NULL,
    user_id bigint,
    context_id bigint,
    context_type character varying(255),
    workflow_state character varying(255) NOT NULL,
    user_type character varying(255),
    title character varying(255),
    user_entered_title character varying(255),
    media_id character varying(255) NOT NULL,
    media_type character varying(255),
    duration integer,
    max_size integer,
    root_account_id bigint,
    data text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    attachment_id bigint,
    total_size integer,
    old_media_id character varying(255)
);


--
-- Name: media_objects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.media_objects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: media_objects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.media_objects_id_seq OWNED BY public.media_objects.id;


--
-- Name: media_tracks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.media_tracks (
    id bigint NOT NULL,
    user_id bigint,
    media_object_id bigint NOT NULL,
    kind character varying(255) DEFAULT 'subtitles'::character varying,
    locale character varying(255) DEFAULT 'en'::character varying,
    content text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    webvtt_content text,
    attachment_id bigint
);


--
-- Name: media_tracks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.media_tracks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: media_tracks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.media_tracks_id_seq OWNED BY public.media_tracks.id;


--
-- Name: mentions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mentions (
    id bigint NOT NULL,
    discussion_entry_id bigint NOT NULL,
    user_id bigint NOT NULL,
    root_account_id bigint NOT NULL,
    workflow_state character varying(255) DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: mentions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mentions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mentions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mentions_id_seq OWNED BY public.mentions.id;


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages (
    id bigint NOT NULL,
    "to" text,
    "from" text,
    subject text,
    body text,
    delay_for integer DEFAULT 120,
    dispatch_at timestamp without time zone,
    sent_at timestamp without time zone,
    workflow_state character varying(255),
    transmission_errors text,
    is_bounced boolean,
    notification_id bigint,
    communication_channel_id bigint,
    context_id bigint,
    context_type character varying(255),
    user_id bigint,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    notification_name character varying(255),
    url text,
    path_type character varying(255),
    from_name text,
    to_email boolean,
    html_body text,
    root_account_id bigint,
    reply_to_name character varying(255)
);


--
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.messages_id_seq OWNED BY public.messages.id;


--
-- Name: messages_2025_18; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages_2025_18 (
    id bigint DEFAULT nextval('public.messages_id_seq'::regclass),
    "to" text,
    "from" text,
    subject text,
    body text,
    delay_for integer DEFAULT 120,
    dispatch_at timestamp without time zone,
    sent_at timestamp without time zone,
    workflow_state character varying(255),
    transmission_errors text,
    is_bounced boolean,
    notification_id bigint,
    communication_channel_id bigint,
    context_id bigint,
    context_type character varying(255),
    user_id bigint,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    notification_name character varying(255),
    url text,
    path_type character varying(255),
    from_name text,
    to_email boolean,
    html_body text,
    root_account_id bigint,
    reply_to_name character varying(255),
    CONSTRAINT messages_2025_18_created_at_check CHECK (((created_at >= '2025-04-28 00:00:00'::timestamp without time zone) AND (created_at < '2025-05-05 00:00:00'::timestamp without time zone)))
)
INHERITS (public.messages);


--
-- Name: messages_2025_19; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages_2025_19 (
    id bigint DEFAULT nextval('public.messages_id_seq'::regclass),
    "to" text,
    "from" text,
    subject text,
    body text,
    delay_for integer DEFAULT 120,
    dispatch_at timestamp without time zone,
    sent_at timestamp without time zone,
    workflow_state character varying(255),
    transmission_errors text,
    is_bounced boolean,
    notification_id bigint,
    communication_channel_id bigint,
    context_id bigint,
    context_type character varying(255),
    user_id bigint,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    notification_name character varying(255),
    url text,
    path_type character varying(255),
    from_name text,
    to_email boolean,
    html_body text,
    root_account_id bigint,
    reply_to_name character varying(255),
    CONSTRAINT messages_2025_19_created_at_check CHECK (((created_at >= '2025-05-05 00:00:00'::timestamp without time zone) AND (created_at < '2025-05-12 00:00:00'::timestamp without time zone)))
)
INHERITS (public.messages);


--
-- Name: messages_2025_20; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages_2025_20 (
    id bigint DEFAULT nextval('public.messages_id_seq'::regclass),
    "to" text,
    "from" text,
    subject text,
    body text,
    delay_for integer DEFAULT 120,
    dispatch_at timestamp without time zone,
    sent_at timestamp without time zone,
    workflow_state character varying(255),
    transmission_errors text,
    is_bounced boolean,
    notification_id bigint,
    communication_channel_id bigint,
    context_id bigint,
    context_type character varying(255),
    user_id bigint,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    notification_name character varying(255),
    url text,
    path_type character varying(255),
    from_name text,
    to_email boolean,
    html_body text,
    root_account_id bigint,
    reply_to_name character varying(255),
    CONSTRAINT messages_2025_20_created_at_check CHECK (((created_at >= '2025-05-12 00:00:00'::timestamp without time zone) AND (created_at < '2025-05-19 00:00:00'::timestamp without time zone)))
)
INHERITS (public.messages);


--
-- Name: microsoft_sync_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.microsoft_sync_groups (
    id bigint NOT NULL,
    course_id bigint NOT NULL,
    workflow_state character varying DEFAULT 'pending'::character varying NOT NULL,
    job_state character varying,
    last_synced_at timestamp without time zone,
    last_manually_synced_at timestamp without time zone,
    last_error text,
    root_account_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    ms_group_id character varying,
    last_error_report_id bigint,
    debug_info text
);


--
-- Name: microsoft_sync_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.microsoft_sync_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: microsoft_sync_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.microsoft_sync_groups_id_seq OWNED BY public.microsoft_sync_groups.id;


--
-- Name: microsoft_sync_partial_sync_changes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.microsoft_sync_partial_sync_changes (
    id bigint NOT NULL,
    course_id bigint NOT NULL,
    user_id bigint NOT NULL,
    root_account_id bigint NOT NULL,
    enrollment_type character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: microsoft_sync_partial_sync_changes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.microsoft_sync_partial_sync_changes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: microsoft_sync_partial_sync_changes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.microsoft_sync_partial_sync_changes_id_seq OWNED BY public.microsoft_sync_partial_sync_changes.id;


--
-- Name: microsoft_sync_user_mappings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.microsoft_sync_user_mappings (
    id bigint NOT NULL,
    root_account_id bigint NOT NULL,
    user_id bigint NOT NULL,
    aad_id character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    needs_updating boolean DEFAULT false NOT NULL
);


--
-- Name: microsoft_sync_user_mappings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.microsoft_sync_user_mappings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: microsoft_sync_user_mappings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.microsoft_sync_user_mappings_id_seq OWNED BY public.microsoft_sync_user_mappings.id;


--
-- Name: migration_issues; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.migration_issues (
    id bigint NOT NULL,
    content_migration_id bigint NOT NULL,
    description text,
    workflow_state character varying(255) NOT NULL,
    fix_issue_html_url text,
    issue_type character varying(255) NOT NULL,
    error_report_id bigint,
    error_message text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: migration_issues_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.migration_issues_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: migration_issues_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.migration_issues_id_seq OWNED BY public.migration_issues.id;


--
-- Name: moderated_grading_provisional_grades; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.moderated_grading_provisional_grades (
    id bigint NOT NULL,
    grade character varying(255),
    score double precision,
    graded_at timestamp without time zone,
    scorer_id bigint NOT NULL,
    submission_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    final boolean DEFAULT false NOT NULL,
    source_provisional_grade_id bigint,
    graded_anonymously boolean
);


--
-- Name: moderated_grading_provisional_grades_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.moderated_grading_provisional_grades_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: moderated_grading_provisional_grades_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.moderated_grading_provisional_grades_id_seq OWNED BY public.moderated_grading_provisional_grades.id;


--
-- Name: moderated_grading_selections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.moderated_grading_selections (
    id bigint NOT NULL,
    assignment_id bigint NOT NULL,
    student_id bigint NOT NULL,
    selected_provisional_grade_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: moderated_grading_selections_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.moderated_grading_selections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: moderated_grading_selections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.moderated_grading_selections_id_seq OWNED BY public.moderated_grading_selections.id;


--
-- Name: moderation_graders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.moderation_graders (
    id bigint NOT NULL,
    anonymous_id character varying(5) NOT NULL,
    assignment_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    slot_taken boolean DEFAULT true NOT NULL
);


--
-- Name: moderation_graders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.moderation_graders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: moderation_graders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.moderation_graders_id_seq OWNED BY public.moderation_graders.id;


--
-- Name: module_student_visibilities; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.module_student_visibilities AS
 SELECT DISTINCT o.id AS context_module_id,
    e.user_id,
    e.course_id
   FROM ((public.context_modules o
     JOIN public.enrollments e ON (((e.course_id = o.context_id) AND ((o.context_type)::text = 'Course'::text) AND ((e.type)::text = ANY ((ARRAY['StudentEnrollment'::character varying, 'StudentViewEnrollment'::character varying])::text[])) AND ((e.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'rejected'::character varying, 'inactive'::character varying])::text[])))))
     LEFT JOIN public.assignment_overrides ao ON (((o.id = ao.context_module_id) AND ((ao.workflow_state)::text = 'active'::text))))
  WHERE (((o.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'unpublished'::character varying])::text[])) AND ((o.id IS NULL) OR ((ao.context_module_id IS NULL) AND ((o.workflow_state)::text <> 'deleted'::text))))
UNION
 SELECT DISTINCT o.id AS context_module_id,
    e.user_id,
    e.course_id
   FROM ((public.context_modules o
     JOIN public.enrollments e ON (((e.course_id = o.context_id) AND ((o.context_type)::text = 'Course'::text) AND ((e.type)::text = ANY ((ARRAY['StudentEnrollment'::character varying, 'StudentViewEnrollment'::character varying])::text[])) AND ((e.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'rejected'::character varying, 'inactive'::character varying])::text[])))))
     JOIN public.assignment_overrides ao ON (((e.course_section_id = ao.set_id) AND ((ao.set_type)::text = 'CourseSection'::text) AND (ao.context_module_id = o.id) AND ((ao.workflow_state)::text = 'active'::text))))
  WHERE (((o.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'unpublished'::character varying])::text[])) AND (ao.unassign_item = false))
UNION
 SELECT DISTINCT o.id AS context_module_id,
    e.user_id,
    e.course_id
   FROM (((public.context_modules o
     JOIN public.enrollments e ON (((e.course_id = o.context_id) AND ((o.context_type)::text = 'Course'::text) AND ((e.type)::text = ANY ((ARRAY['StudentEnrollment'::character varying, 'StudentViewEnrollment'::character varying])::text[])) AND ((e.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'rejected'::character varying, 'inactive'::character varying])::text[])))))
     JOIN public.assignment_overrides ao ON (((ao.context_module_id = o.id) AND ((ao.set_type)::text = 'ADHOC'::text) AND ((ao.workflow_state)::text = 'active'::text))))
     JOIN public.assignment_override_students aos ON (((ao.id = aos.assignment_override_id) AND (aos.user_id = e.user_id) AND ((aos.workflow_state)::text <> 'deleted'::text))))
  WHERE (((o.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'unpublished'::character varying])::text[])) AND (ao.unassign_item = false));


--
-- Name: notification_endpoints; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification_endpoints (
    id bigint NOT NULL,
    access_token_id bigint NOT NULL,
    token character varying(255) NOT NULL,
    arn character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    workflow_state character varying DEFAULT 'active'::character varying NOT NULL
);


--
-- Name: notification_endpoints_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notification_endpoints_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notification_endpoints_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notification_endpoints_id_seq OWNED BY public.notification_endpoints.id;


--
-- Name: notification_policies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification_policies (
    id bigint NOT NULL,
    notification_id bigint,
    communication_channel_id bigint NOT NULL,
    frequency character varying(255) DEFAULT 'immediately'::character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: notification_policies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notification_policies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notification_policies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notification_policies_id_seq OWNED BY public.notification_policies.id;


--
-- Name: notification_policy_overrides; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification_policy_overrides (
    id bigint NOT NULL,
    context_type character varying DEFAULT 'Course'::character varying NOT NULL,
    context_id bigint NOT NULL,
    communication_channel_id bigint NOT NULL,
    notification_id bigint,
    workflow_state character varying DEFAULT 'active'::character varying NOT NULL,
    frequency character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: notification_policy_overrides_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notification_policy_overrides_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notification_policy_overrides_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notification_policy_overrides_id_seq OWNED BY public.notification_policy_overrides.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id bigint NOT NULL,
    name character varying(255),
    subject character varying(255),
    category character varying(255),
    delay_for integer DEFAULT 120,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    main_link character varying(255),
    priority boolean DEFAULT false NOT NULL
);


--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- Name: oauth_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_requests (
    id bigint NOT NULL,
    token character varying(255),
    secret character varying(255),
    user_secret character varying(255),
    return_url character varying(4096),
    workflow_state character varying(255),
    user_id bigint,
    original_host_with_port character varying(255),
    service character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: oauth_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.oauth_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.oauth_requests_id_seq OWNED BY public.oauth_requests.id;


--
-- Name: observer_alert_thresholds; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.observer_alert_thresholds (
    id bigint NOT NULL,
    alert_type character varying NOT NULL,
    threshold character varying,
    workflow_state character varying DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id bigint NOT NULL,
    observer_id bigint NOT NULL
);


--
-- Name: observer_alert_thresholds_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.observer_alert_thresholds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: observer_alert_thresholds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.observer_alert_thresholds_id_seq OWNED BY public.observer_alert_thresholds.id;


--
-- Name: observer_alerts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.observer_alerts (
    id bigint NOT NULL,
    observer_alert_threshold_id bigint NOT NULL,
    context_type character varying,
    context_id bigint,
    alert_type character varying NOT NULL,
    workflow_state character varying DEFAULT 'unread'::character varying NOT NULL,
    action_date timestamp without time zone NOT NULL,
    title character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id bigint NOT NULL,
    observer_id bigint NOT NULL
);


--
-- Name: observer_alerts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.observer_alerts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: observer_alerts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.observer_alerts_id_seq OWNED BY public.observer_alerts.id;


--
-- Name: observer_pairing_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.observer_pairing_codes (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    code character varying(10) NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    workflow_state character varying DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: observer_pairing_codes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.observer_pairing_codes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: observer_pairing_codes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.observer_pairing_codes_id_seq OWNED BY public.observer_pairing_codes.id;


--
-- Name: one_time_passwords; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.one_time_passwords (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    code character varying NOT NULL,
    used boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: one_time_passwords_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.one_time_passwords_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: one_time_passwords_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.one_time_passwords_id_seq OWNED BY public.one_time_passwords.id;


--
-- Name: originality_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.originality_reports (
    id bigint NOT NULL,
    attachment_id bigint,
    originality_score double precision,
    originality_report_attachment_id bigint,
    originality_report_url text,
    originality_report_lti_url text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    submission_id bigint NOT NULL,
    workflow_state character varying DEFAULT 'pending'::character varying NOT NULL,
    link_id text,
    error_message text,
    submission_time timestamp without time zone,
    root_account_id bigint NOT NULL
);


--
-- Name: originality_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.originality_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: originality_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.originality_reports_id_seq OWNED BY public.originality_reports.id;


--
-- Name: outcome_calculation_methods; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.outcome_calculation_methods (
    id bigint NOT NULL,
    context_type character varying(255) NOT NULL,
    context_id bigint NOT NULL,
    calculation_int smallint,
    calculation_method character varying(255) NOT NULL,
    workflow_state character varying DEFAULT 'active'::character varying NOT NULL,
    root_account_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: outcome_calculation_methods_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.outcome_calculation_methods_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: outcome_calculation_methods_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.outcome_calculation_methods_id_seq OWNED BY public.outcome_calculation_methods.id;


--
-- Name: outcome_friendly_descriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.outcome_friendly_descriptions (
    id bigint NOT NULL,
    context_type character varying(255) NOT NULL,
    context_id bigint NOT NULL,
    workflow_state character varying DEFAULT 'active'::character varying NOT NULL,
    root_account_id bigint,
    description text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    learning_outcome_id bigint NOT NULL
);


--
-- Name: outcome_friendly_descriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.outcome_friendly_descriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: outcome_friendly_descriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.outcome_friendly_descriptions_id_seq OWNED BY public.outcome_friendly_descriptions.id;


--
-- Name: outcome_import_errors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.outcome_import_errors (
    id bigint NOT NULL,
    outcome_import_id bigint NOT NULL,
    message character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    "row" integer,
    failure boolean DEFAULT false NOT NULL
);


--
-- Name: outcome_import_errors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.outcome_import_errors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: outcome_import_errors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.outcome_import_errors_id_seq OWNED BY public.outcome_import_errors.id;


--
-- Name: outcome_imports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.outcome_imports (
    id bigint NOT NULL,
    workflow_state character varying NOT NULL,
    context_id bigint NOT NULL,
    context_type character varying NOT NULL,
    user_id bigint,
    attachment_id bigint,
    progress integer,
    ended_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    data json,
    learning_outcome_group_id bigint
);


--
-- Name: outcome_imports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.outcome_imports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: outcome_imports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.outcome_imports_id_seq OWNED BY public.outcome_imports.id;


--
-- Name: outcome_proficiencies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.outcome_proficiencies (
    id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    root_account_id bigint,
    context_id bigint NOT NULL,
    context_type character varying(255) NOT NULL,
    workflow_state character varying DEFAULT 'active'::character varying NOT NULL
);


--
-- Name: outcome_proficiencies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.outcome_proficiencies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: outcome_proficiencies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.outcome_proficiencies_id_seq OWNED BY public.outcome_proficiencies.id;


--
-- Name: outcome_proficiency_ratings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.outcome_proficiency_ratings (
    id bigint NOT NULL,
    outcome_proficiency_id bigint NOT NULL,
    description character varying(255) NOT NULL,
    points double precision NOT NULL,
    mastery boolean NOT NULL,
    color character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    root_account_id bigint,
    workflow_state character varying DEFAULT 'active'::character varying NOT NULL
);


--
-- Name: outcome_proficiency_ratings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.outcome_proficiency_ratings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: outcome_proficiency_ratings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.outcome_proficiency_ratings_id_seq OWNED BY public.outcome_proficiency_ratings.id;


--
-- Name: page_comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.page_comments (
    id bigint NOT NULL,
    message text,
    page_id bigint,
    page_type character varying(255),
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: page_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.page_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: page_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.page_comments_id_seq OWNED BY public.page_comments.id;


--
-- Name: page_views; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.page_views (
    request_id character varying(255) NOT NULL,
    session_id character varying(255),
    user_id bigint NOT NULL,
    url text,
    context_id bigint,
    context_type character varying(255),
    asset_id bigint,
    asset_type character varying(255),
    controller character varying(255),
    action character varying(255),
    interaction_seconds double precision,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    developer_key_id bigint,
    user_request boolean,
    render_time double precision,
    user_agent text,
    asset_user_access_id bigint,
    participated boolean,
    summarized boolean,
    account_id bigint,
    real_user_id bigint,
    http_method character varying(255),
    remote_ip character varying(255)
);


--
-- Name: parallel_importers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.parallel_importers (
    id bigint NOT NULL,
    sis_batch_id bigint NOT NULL,
    workflow_state character varying(255) NOT NULL,
    index bigint NOT NULL,
    batch_size bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    started_at timestamp without time zone,
    ended_at timestamp without time zone,
    importer_type character varying(255) NOT NULL,
    attachment_id bigint NOT NULL,
    rows_processed integer DEFAULT 0 NOT NULL,
    job_ids bigint[] DEFAULT '{}'::bigint[] NOT NULL
);


--
-- Name: parallel_importers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.parallel_importers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: parallel_importers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.parallel_importers_id_seq OWNED BY public.parallel_importers.id;


--
-- Name: planner_notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.planner_notes (
    id bigint NOT NULL,
    todo_date timestamp without time zone NOT NULL,
    title character varying NOT NULL,
    details text,
    user_id bigint NOT NULL,
    course_id bigint,
    workflow_state character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    linked_object_type character varying,
    linked_object_id bigint
);


--
-- Name: planner_notes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.planner_notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: planner_notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.planner_notes_id_seq OWNED BY public.planner_notes.id;


--
-- Name: planner_overrides; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.planner_overrides (
    id bigint NOT NULL,
    plannable_type character varying NOT NULL,
    plannable_id bigint NOT NULL,
    user_id bigint NOT NULL,
    workflow_state character varying,
    marked_complete boolean DEFAULT false NOT NULL,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    dismissed boolean DEFAULT false NOT NULL
);


--
-- Name: planner_overrides_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.planner_overrides_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: planner_overrides_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.planner_overrides_id_seq OWNED BY public.planner_overrides.id;


--
-- Name: plugin_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.plugin_settings (
    id bigint NOT NULL,
    name character varying(255) DEFAULT ''::character varying NOT NULL,
    settings text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    disabled boolean
);


--
-- Name: plugin_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.plugin_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: plugin_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.plugin_settings_id_seq OWNED BY public.plugin_settings.id;


--
-- Name: polling_poll_choices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.polling_poll_choices (
    id bigint NOT NULL,
    text character varying(255),
    is_correct boolean DEFAULT false NOT NULL,
    poll_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    "position" integer
);


--
-- Name: polling_poll_choices_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.polling_poll_choices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: polling_poll_choices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.polling_poll_choices_id_seq OWNED BY public.polling_poll_choices.id;


--
-- Name: polling_poll_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.polling_poll_sessions (
    id bigint NOT NULL,
    is_published boolean DEFAULT false NOT NULL,
    has_public_results boolean DEFAULT false NOT NULL,
    course_id bigint NOT NULL,
    course_section_id bigint,
    poll_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: polling_poll_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.polling_poll_sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: polling_poll_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.polling_poll_sessions_id_seq OWNED BY public.polling_poll_sessions.id;


--
-- Name: polling_poll_submissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.polling_poll_submissions (
    id bigint NOT NULL,
    poll_id bigint NOT NULL,
    poll_choice_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    poll_session_id bigint NOT NULL
);


--
-- Name: polling_poll_submissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.polling_poll_submissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: polling_poll_submissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.polling_poll_submissions_id_seq OWNED BY public.polling_poll_submissions.id;


--
-- Name: polling_polls; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.polling_polls (
    id bigint NOT NULL,
    question character varying(255),
    description character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id bigint NOT NULL
);


--
-- Name: polling_polls_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.polling_polls_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: polling_polls_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.polling_polls_id_seq OWNED BY public.polling_polls.id;


--
-- Name: post_policies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.post_policies (
    id bigint NOT NULL,
    post_manually boolean DEFAULT false NOT NULL,
    course_id bigint,
    assignment_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    root_account_id bigint
);


--
-- Name: post_policies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.post_policies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: post_policies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.post_policies_id_seq OWNED BY public.post_policies.id;


--
-- Name: profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profiles (
    id bigint NOT NULL,
    root_account_id bigint NOT NULL,
    context_type character varying(255) NOT NULL,
    context_id bigint NOT NULL,
    title character varying(255),
    path character varying(255),
    description text,
    data text,
    visibility character varying(255),
    "position" integer
);


--
-- Name: profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.profiles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.profiles_id_seq OWNED BY public.profiles.id;


--
-- Name: progresses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.progresses (
    id bigint NOT NULL,
    context_id bigint NOT NULL,
    context_type character varying(255) NOT NULL,
    user_id bigint,
    tag character varying(255) NOT NULL,
    completion double precision,
    delayed_job_id character varying(255),
    workflow_state character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    message text,
    cache_key_context character varying(255),
    results text
);


--
-- Name: progresses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.progresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: progresses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.progresses_id_seq OWNED BY public.progresses.id;


--
-- Name: pseudonyms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pseudonyms (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    account_id bigint NOT NULL,
    workflow_state character varying(255) NOT NULL,
    unique_id character varying(255) NOT NULL,
    crypted_password character varying(255) NOT NULL,
    password_salt character varying(255) NOT NULL,
    persistence_token character varying(255) NOT NULL,
    single_access_token character varying(255) NOT NULL,
    perishable_token character varying(255) NOT NULL,
    login_count integer DEFAULT 0 NOT NULL,
    failed_login_count integer DEFAULT 0 NOT NULL,
    last_request_at timestamp without time zone,
    last_login_at timestamp without time zone,
    current_login_at timestamp without time zone,
    last_login_ip character varying(255),
    current_login_ip character varying(255),
    reset_password_token character varying(255) DEFAULT ''::character varying NOT NULL,
    "position" integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    password_auto_generated boolean,
    deleted_at timestamp without time zone,
    sis_batch_id bigint,
    sis_user_id character varying(255),
    sis_ssha character varying(255),
    communication_channel_id bigint,
    sis_communication_channel_id bigint,
    stuck_sis_fields text,
    integration_id character varying(255),
    authentication_provider_id bigint,
    declared_user_type character varying(255)
);


--
-- Name: pseudonyms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pseudonyms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pseudonyms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pseudonyms_id_seq OWNED BY public.pseudonyms.id;


--
-- Name: purgatories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.purgatories (
    id bigint NOT NULL,
    attachment_id bigint NOT NULL,
    deleted_by_user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    workflow_state character varying DEFAULT 'active'::character varying NOT NULL,
    old_filename character varying NOT NULL,
    old_display_name character varying(255),
    old_content_type character varying(255),
    new_instfs_uuid character varying,
    old_file_state character varying,
    old_workflow_state character varying
);


--
-- Name: purgatories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.purgatories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: purgatories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.purgatories_id_seq OWNED BY public.purgatories.id;


--
-- Name: quiz_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quiz_groups (
    id bigint NOT NULL,
    quiz_id bigint NOT NULL,
    name character varying(255),
    pick_count integer,
    question_points double precision,
    "position" integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    migration_id character varying(255),
    assessment_question_bank_id bigint,
    root_account_id bigint
);


--
-- Name: quiz_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.quiz_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: quiz_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.quiz_groups_id_seq OWNED BY public.quiz_groups.id;


--
-- Name: quiz_migration_alerts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quiz_migration_alerts (
    id bigint NOT NULL,
    migration_type character varying,
    migration_id bigint,
    user_id bigint NOT NULL,
    course_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: quiz_migration_alerts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.quiz_migration_alerts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: quiz_migration_alerts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.quiz_migration_alerts_id_seq OWNED BY public.quiz_migration_alerts.id;


--
-- Name: quiz_question_regrades; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quiz_question_regrades (
    id bigint NOT NULL,
    quiz_regrade_id bigint NOT NULL,
    quiz_question_id bigint NOT NULL,
    regrade_option character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: quiz_question_regrades_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.quiz_question_regrades_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: quiz_question_regrades_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.quiz_question_regrades_id_seq OWNED BY public.quiz_question_regrades.id;


--
-- Name: quiz_questions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quiz_questions (
    id bigint NOT NULL,
    quiz_id bigint,
    quiz_group_id bigint,
    assessment_question_id bigint,
    question_data text,
    assessment_question_version integer,
    "position" integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    migration_id character varying(255),
    workflow_state character varying(255),
    duplicate_index integer,
    root_account_id bigint
);


--
-- Name: quiz_questions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.quiz_questions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: quiz_questions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.quiz_questions_id_seq OWNED BY public.quiz_questions.id;


--
-- Name: quiz_regrade_runs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quiz_regrade_runs (
    id bigint NOT NULL,
    quiz_regrade_id bigint NOT NULL,
    started_at timestamp without time zone,
    finished_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: quiz_regrade_runs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.quiz_regrade_runs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: quiz_regrade_runs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.quiz_regrade_runs_id_seq OWNED BY public.quiz_regrade_runs.id;


--
-- Name: quiz_regrades; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quiz_regrades (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    quiz_id bigint NOT NULL,
    quiz_version integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: quiz_regrades_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.quiz_regrades_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: quiz_regrades_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.quiz_regrades_id_seq OWNED BY public.quiz_regrades.id;


--
-- Name: quiz_statistics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quiz_statistics (
    id bigint NOT NULL,
    quiz_id bigint,
    includes_all_versions boolean,
    anonymous boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    report_type character varying(255),
    includes_sis_ids boolean
);


--
-- Name: quiz_statistics_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.quiz_statistics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: quiz_statistics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.quiz_statistics_id_seq OWNED BY public.quiz_statistics.id;


--
-- Name: quiz_student_visibilities; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.quiz_student_visibilities AS
 SELECT DISTINCT q.id AS quiz_id,
    e.user_id,
    e.course_id
   FROM (public.quizzes q
     JOIN public.enrollments e ON (((e.course_id = q.context_id) AND ((q.context_type)::text = 'Course'::text) AND ((e.type)::text = ANY ((ARRAY['StudentEnrollment'::character varying, 'StudentViewEnrollment'::character varying])::text[])) AND ((e.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'rejected'::character varying, 'inactive'::character varying])::text[])))))
  WHERE (((q.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'unpublished'::character varying])::text[])) AND (COALESCE(q.only_visible_to_overrides, false) = false))
UNION
 SELECT DISTINCT q.id AS quiz_id,
    e.user_id,
    e.course_id
   FROM (((public.quizzes q
     JOIN public.enrollments e ON (((e.course_id = q.context_id) AND ((q.context_type)::text = 'Course'::text) AND ((e.type)::text = ANY ((ARRAY['StudentEnrollment'::character varying, 'StudentViewEnrollment'::character varying])::text[])) AND ((e.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'rejected'::character varying, 'inactive'::character varying])::text[])))))
     JOIN public.assignment_overrides ao ON (((q.id = ao.quiz_id) AND ((ao.set_type)::text = 'ADHOC'::text))))
     JOIN public.assignment_override_students aos ON (((ao.id = aos.assignment_override_id) AND (aos.user_id = e.user_id))))
  WHERE (((ao.workflow_state)::text = 'active'::text) AND ((aos.workflow_state)::text <> 'deleted'::text) AND ((q.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'unpublished'::character varying])::text[])) AND (q.only_visible_to_overrides = true))
UNION
 SELECT DISTINCT q.id AS quiz_id,
    e.user_id,
    e.course_id
   FROM ((public.quizzes q
     JOIN public.enrollments e ON (((e.course_id = q.context_id) AND ((q.context_type)::text = 'Course'::text) AND ((e.type)::text = ANY ((ARRAY['StudentEnrollment'::character varying, 'StudentViewEnrollment'::character varying])::text[])) AND ((e.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'rejected'::character varying, 'inactive'::character varying])::text[])))))
     JOIN public.assignment_overrides ao ON (((e.course_section_id = ao.set_id) AND ((ao.set_type)::text = 'CourseSection'::text) AND (ao.quiz_id = q.id))))
  WHERE (((q.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'unpublished'::character varying])::text[])) AND (q.only_visible_to_overrides = true) AND ((ao.workflow_state)::text = 'active'::text));


--
-- Name: quiz_student_visibilities_v2; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.quiz_student_visibilities_v2 AS
(
        (
                (
                        (
                                 SELECT DISTINCT o.id AS quiz_id,
                                    e.user_id,
                                    e.course_id
                                   FROM ((((public.quizzes o
                                     JOIN public.enrollments e ON (((e.course_id = o.context_id) AND ((o.context_type)::text = 'Course'::text) AND ((e.type)::text = ANY ((ARRAY['StudentEnrollment'::character varying, 'StudentViewEnrollment'::character varying])::text[])) AND ((e.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'rejected'::character varying, 'inactive'::character varying])::text[])))))
                                     LEFT JOIN public.content_tags t ON (((t.content_id = o.id) AND ((t.content_type)::text = 'Quizzes::Quiz'::text) AND ((t.tag_type)::text = 'context_module'::text) AND ((t.workflow_state)::text <> 'deleted'::text))))
                                     LEFT JOIN public.context_modules m ON (((m.id = t.context_module_id) AND ((m.workflow_state)::text <> 'deleted'::text))))
                                     LEFT JOIN public.assignment_overrides ao ON (((m.id = ao.context_module_id) AND ((ao.workflow_state)::text = 'active'::text))))
                                  WHERE (((o.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'unpublished'::character varying])::text[])) AND (COALESCE(o.only_visible_to_overrides, false) = false) AND ((m.id IS NULL) OR ((ao.context_module_id IS NULL) AND ((m.workflow_state)::text <> 'deleted'::text))))
                                UNION
                                 SELECT DISTINCT o.id AS quiz_id,
                                    e.user_id,
                                    e.course_id
                                   FROM ((((public.quizzes o
                                     JOIN public.enrollments e ON (((e.course_id = o.context_id) AND ((o.context_type)::text = 'Course'::text) AND ((e.type)::text = ANY ((ARRAY['StudentEnrollment'::character varying, 'StudentViewEnrollment'::character varying])::text[])) AND ((e.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'rejected'::character varying, 'inactive'::character varying])::text[])))))
                                     LEFT JOIN public.content_tags t ON (((t.content_id = o.id) AND ((t.content_type)::text = 'Quizzes::Quiz'::text) AND ((t.tag_type)::text = 'context_module'::text) AND ((t.workflow_state)::text <> 'deleted'::text))))
                                     LEFT JOIN public.context_modules m ON (((m.id = t.context_module_id) AND ((m.workflow_state)::text <> 'deleted'::text))))
                                     JOIN public.assignment_overrides ao ON (((e.course_section_id = ao.set_id) AND ((ao.set_type)::text = 'CourseSection'::text) AND ((ao.quiz_id = o.id) OR (m.id = ao.context_module_id)) AND ((ao.workflow_state)::text = 'active'::text))))
                                  WHERE (((o.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'unpublished'::character varying])::text[])) AND ((m.id IS NOT NULL) OR (o.only_visible_to_overrides = true)) AND (ao.unassign_item = false))
                        ) EXCEPT
                         SELECT DISTINCT o.id AS quiz_id,
                            e.user_id,
                            e.course_id
                           FROM ((public.quizzes o
                             JOIN public.enrollments e ON (((e.course_id = o.context_id) AND ((o.context_type)::text = 'Course'::text) AND ((e.type)::text = ANY ((ARRAY['StudentEnrollment'::character varying, 'StudentViewEnrollment'::character varying])::text[])) AND ((e.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'rejected'::character varying, 'inactive'::character varying])::text[])))))
                             JOIN public.assignment_overrides ao ON (((e.course_section_id = ao.set_id) AND ((ao.set_type)::text = 'CourseSection'::text) AND (ao.quiz_id = o.id) AND ((ao.workflow_state)::text = 'active'::text))))
                          WHERE (((o.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'unpublished'::character varying])::text[])) AND (ao.unassign_item = true))
                ) UNION
                 SELECT DISTINCT o.id AS quiz_id,
                    e.user_id,
                    e.course_id
                   FROM (((((public.quizzes o
                     JOIN public.enrollments e ON (((e.course_id = o.context_id) AND ((o.context_type)::text = 'Course'::text) AND ((e.type)::text = ANY ((ARRAY['StudentEnrollment'::character varying, 'StudentViewEnrollment'::character varying])::text[])) AND ((e.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'rejected'::character varying, 'inactive'::character varying])::text[])))))
                     LEFT JOIN public.content_tags t ON (((t.content_id = o.id) AND ((t.content_type)::text = 'Quizzes::Quiz'::text) AND ((t.tag_type)::text = 'context_module'::text) AND ((t.workflow_state)::text <> 'deleted'::text))))
                     LEFT JOIN public.context_modules m ON (((m.id = t.context_module_id) AND ((m.workflow_state)::text <> 'deleted'::text))))
                     JOIN public.assignment_overrides ao ON ((((ao.quiz_id = o.id) OR (m.id = ao.context_module_id)) AND ((ao.set_type)::text = 'ADHOC'::text) AND ((ao.workflow_state)::text = 'active'::text))))
                     JOIN public.assignment_override_students aos ON (((ao.id = aos.assignment_override_id) AND (aos.user_id = e.user_id) AND ((aos.workflow_state)::text <> 'deleted'::text))))
                  WHERE (((o.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'unpublished'::character varying])::text[])) AND ((m.id IS NOT NULL) OR (o.only_visible_to_overrides = true)) AND (ao.unassign_item = false))
        ) EXCEPT
         SELECT DISTINCT o.id AS quiz_id,
            e.user_id,
            e.course_id
           FROM (((public.quizzes o
             JOIN public.enrollments e ON (((e.course_id = o.context_id) AND ((o.context_type)::text = 'Course'::text) AND ((e.type)::text = ANY ((ARRAY['StudentEnrollment'::character varying, 'StudentViewEnrollment'::character varying])::text[])) AND ((e.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'rejected'::character varying, 'inactive'::character varying])::text[])))))
             JOIN public.assignment_overrides ao ON (((o.id = ao.quiz_id) AND ((ao.set_type)::text = 'ADHOC'::text) AND ((ao.workflow_state)::text = 'active'::text))))
             JOIN public.assignment_override_students aos ON (((ao.id = aos.assignment_override_id) AND (aos.user_id = e.user_id) AND ((aos.workflow_state)::text <> 'deleted'::text))))
          WHERE (((o.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'unpublished'::character varying])::text[])) AND (ao.unassign_item = true))
) UNION
 SELECT DISTINCT o.id AS quiz_id,
    e.user_id,
    e.course_id
   FROM ((public.quizzes o
     JOIN public.enrollments e ON (((e.course_id = o.context_id) AND ((o.context_type)::text = 'Course'::text) AND ((e.type)::text = ANY ((ARRAY['StudentEnrollment'::character varying, 'StudentViewEnrollment'::character varying])::text[])) AND ((e.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'rejected'::character varying, 'inactive'::character varying])::text[])))))
     JOIN public.assignment_overrides ao ON (((e.course_id = ao.set_id) AND ((ao.set_type)::text = 'Course'::text) AND (o.id = ao.quiz_id))))
  WHERE (((o.workflow_state)::text <> ALL ((ARRAY['deleted'::character varying, 'unpublished'::character varying])::text[])) AND ((ao.workflow_state)::text = 'active'::text));


--
-- Name: quiz_submission_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quiz_submission_events (
    id bigint NOT NULL,
    attempt integer NOT NULL,
    event_type character varying(255) NOT NULL,
    quiz_submission_id bigint NOT NULL,
    event_data text,
    created_at timestamp without time zone NOT NULL,
    client_timestamp timestamp without time zone,
    root_account_id bigint
);


--
-- Name: quiz_submission_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.quiz_submission_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: quiz_submission_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.quiz_submission_events_id_seq OWNED BY public.quiz_submission_events.id;


--
-- Name: quiz_submission_events_2025_5; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quiz_submission_events_2025_5 (
    id bigint DEFAULT nextval('public.quiz_submission_events_id_seq'::regclass),
    attempt integer,
    event_type character varying(255),
    quiz_submission_id bigint,
    event_data text,
    created_at timestamp without time zone,
    client_timestamp timestamp without time zone,
    root_account_id bigint,
    CONSTRAINT quiz_submission_events_2025_5_created_at_check CHECK (((created_at >= '2025-05-01 00:00:00'::timestamp without time zone) AND (created_at < '2025-06-01 00:00:00'::timestamp without time zone)))
)
INHERITS (public.quiz_submission_events);


--
-- Name: quiz_submission_events_2025_6; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quiz_submission_events_2025_6 (
    id bigint DEFAULT nextval('public.quiz_submission_events_id_seq'::regclass),
    attempt integer,
    event_type character varying(255),
    quiz_submission_id bigint,
    event_data text,
    created_at timestamp without time zone,
    client_timestamp timestamp without time zone,
    root_account_id bigint,
    CONSTRAINT quiz_submission_events_2025_6_created_at_check CHECK (((created_at >= '2025-06-01 00:00:00'::timestamp without time zone) AND (created_at < '2025-07-01 00:00:00'::timestamp without time zone)))
)
INHERITS (public.quiz_submission_events);


--
-- Name: quiz_submission_events_2025_7; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quiz_submission_events_2025_7 (
    id bigint DEFAULT nextval('public.quiz_submission_events_id_seq'::regclass),
    attempt integer,
    event_type character varying(255),
    quiz_submission_id bigint,
    event_data text,
    created_at timestamp without time zone,
    client_timestamp timestamp without time zone,
    root_account_id bigint,
    CONSTRAINT quiz_submission_events_2025_7_created_at_check CHECK (((created_at >= '2025-07-01 00:00:00'::timestamp without time zone) AND (created_at < '2025-08-01 00:00:00'::timestamp without time zone)))
)
INHERITS (public.quiz_submission_events);


--
-- Name: quiz_submission_snapshots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quiz_submission_snapshots (
    id bigint NOT NULL,
    quiz_submission_id bigint,
    attempt integer,
    data text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: quiz_submission_snapshots_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.quiz_submission_snapshots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: quiz_submission_snapshots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.quiz_submission_snapshots_id_seq OWNED BY public.quiz_submission_snapshots.id;


--
-- Name: quiz_submissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quiz_submissions (
    id bigint NOT NULL,
    quiz_id bigint NOT NULL,
    quiz_version integer,
    user_id bigint,
    submission_data text,
    submission_id bigint,
    score double precision,
    kept_score double precision,
    quiz_data text,
    started_at timestamp without time zone,
    end_at timestamp without time zone,
    finished_at timestamp without time zone,
    attempt integer,
    workflow_state character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    fudge_points double precision DEFAULT 0,
    quiz_points_possible double precision,
    extra_attempts integer,
    temporary_user_code character varying(255),
    extra_time integer,
    manually_unlocked boolean,
    manually_scored boolean,
    validation_token character varying(255),
    score_before_regrade double precision,
    was_preview boolean,
    has_seen_results boolean,
    question_references_fixed boolean,
    root_account_id bigint
);


--
-- Name: quiz_submissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.quiz_submissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: quiz_submissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.quiz_submissions_id_seq OWNED BY public.quiz_submissions.id;


--
-- Name: quizzes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.quizzes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: quizzes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.quizzes_id_seq OWNED BY public.quizzes.id;


--
-- Name: report_snapshots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.report_snapshots (
    id bigint NOT NULL,
    report_type character varying(255),
    data text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    account_id bigint
);


--
-- Name: report_snapshots_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.report_snapshots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: report_snapshots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.report_snapshots_id_seq OWNED BY public.report_snapshots.id;


--
-- Name: role_overrides; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.role_overrides (
    id bigint NOT NULL,
    permission character varying(255),
    enabled boolean DEFAULT true NOT NULL,
    locked boolean DEFAULT false NOT NULL,
    context_id bigint NOT NULL,
    context_type character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    applies_to_self boolean DEFAULT true NOT NULL,
    applies_to_descendants boolean DEFAULT true NOT NULL,
    role_id bigint NOT NULL,
    root_account_id bigint NOT NULL
);


--
-- Name: role_overrides_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.role_overrides_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: role_overrides_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.role_overrides_id_seq OWNED BY public.role_overrides.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    base_role_type character varying(255) NOT NULL,
    account_id bigint,
    workflow_state character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    root_account_id bigint NOT NULL
);


--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- Name: rubric_assessments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rubric_assessments (
    id bigint NOT NULL,
    user_id bigint,
    rubric_id bigint NOT NULL,
    rubric_association_id bigint,
    score double precision,
    data text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    artifact_id bigint NOT NULL,
    artifact_type character varying(255) NOT NULL,
    assessment_type character varying(255) NOT NULL,
    assessor_id bigint,
    artifact_attempt integer,
    hide_points boolean DEFAULT false NOT NULL,
    root_account_id bigint
);


--
-- Name: rubric_assessments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rubric_assessments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rubric_assessments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rubric_assessments_id_seq OWNED BY public.rubric_assessments.id;


--
-- Name: rubric_associations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rubric_associations (
    id bigint NOT NULL,
    rubric_id bigint NOT NULL,
    association_id bigint NOT NULL,
    association_type character varying(255) NOT NULL,
    use_for_grading boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    title character varying(255),
    summary_data text,
    purpose character varying(255) NOT NULL,
    url character varying(255),
    context_id bigint NOT NULL,
    context_type character varying(255) NOT NULL,
    hide_score_total boolean,
    bookmarked boolean DEFAULT true,
    context_code character varying(255),
    hide_points boolean DEFAULT false,
    hide_outcome_results boolean DEFAULT false,
    root_account_id bigint,
    workflow_state character varying DEFAULT 'active'::character varying NOT NULL
);


--
-- Name: rubric_associations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rubric_associations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rubric_associations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rubric_associations_id_seq OWNED BY public.rubric_associations.id;


--
-- Name: rubric_criteria; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rubric_criteria (
    id bigint NOT NULL,
    rubric_id bigint NOT NULL,
    root_account_id bigint NOT NULL,
    description text,
    long_description text,
    "order" integer NOT NULL,
    points numeric NOT NULL,
    criterion_use_range boolean DEFAULT false NOT NULL,
    learning_outcome_id bigint,
    mastery_points numeric,
    ignore_for_scoring boolean DEFAULT false NOT NULL,
    workflow_state character varying(255) DEFAULT 'active'::character varying NOT NULL,
    created_by_id bigint NOT NULL,
    deleted_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: rubric_criteria_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rubric_criteria_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rubric_criteria_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rubric_criteria_id_seq OWNED BY public.rubric_criteria.id;


--
-- Name: rubrics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rubrics (
    id bigint NOT NULL,
    user_id bigint,
    rubric_id bigint,
    context_id bigint NOT NULL,
    context_type character varying(255) NOT NULL,
    data text,
    points_possible double precision,
    title character varying(255),
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    reusable boolean DEFAULT false,
    public boolean DEFAULT false,
    read_only boolean DEFAULT false,
    association_count integer DEFAULT 0,
    free_form_criterion_comments boolean,
    context_code character varying(255),
    migration_id character varying(255),
    hide_score_total boolean,
    workflow_state character varying(255) DEFAULT 'active'::character varying NOT NULL,
    root_account_id bigint,
    hide_points boolean DEFAULT false NOT NULL,
    rating_order character varying DEFAULT 'descending'::character varying NOT NULL,
    button_display character varying DEFAULT 'numeric'::character varying NOT NULL,
    CONSTRAINT check_button_display CHECK (((button_display)::text = ANY ((ARRAY['numeric'::character varying, 'emoji'::character varying, 'letter'::character varying])::text[]))),
    CONSTRAINT check_rating_order CHECK (((rating_order)::text = ANY ((ARRAY['descending'::character varying, 'ascending'::character varying])::text[])))
);


--
-- Name: rubrics_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rubrics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rubrics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rubrics_id_seq OWNED BY public.rubrics.id;


--
-- Name: scheduled_smart_alerts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scheduled_smart_alerts (
    id bigint NOT NULL,
    context_type character varying NOT NULL,
    alert_type character varying NOT NULL,
    context_id bigint NOT NULL,
    due_at timestamp without time zone NOT NULL,
    root_account_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: scheduled_smart_alerts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.scheduled_smart_alerts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scheduled_smart_alerts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.scheduled_smart_alerts_id_seq OWNED BY public.scheduled_smart_alerts.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: score_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.score_metadata (
    id bigint NOT NULL,
    score_id bigint NOT NULL,
    calculation_details json DEFAULT '{}'::json NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    workflow_state character varying DEFAULT 'active'::character varying NOT NULL
);


--
-- Name: score_metadata_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.score_metadata_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: score_metadata_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.score_metadata_id_seq OWNED BY public.score_metadata.id;


--
-- Name: score_statistics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.score_statistics (
    id bigint NOT NULL,
    assignment_id bigint NOT NULL,
    minimum double precision NOT NULL,
    maximum double precision NOT NULL,
    mean double precision NOT NULL,
    count integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    root_account_id bigint,
    lower_q double precision,
    median double precision,
    upper_q double precision
);


--
-- Name: score_statistics_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.score_statistics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: score_statistics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.score_statistics_id_seq OWNED BY public.score_statistics.id;


--
-- Name: scores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scores (
    id bigint NOT NULL,
    enrollment_id bigint NOT NULL,
    grading_period_id bigint,
    workflow_state character varying(255) DEFAULT 'active'::character varying NOT NULL,
    current_score double precision,
    final_score double precision,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    assignment_group_id bigint,
    course_score boolean DEFAULT false NOT NULL,
    unposted_current_score double precision,
    unposted_final_score double precision,
    current_points double precision,
    unposted_current_points double precision,
    final_points double precision,
    unposted_final_points double precision,
    override_score double precision,
    root_account_id bigint,
    custom_grade_status_id bigint
);


--
-- Name: scores_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.scores_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scores_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.scores_id_seq OWNED BY public.scores.id;


--
-- Name: session_persistence_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.session_persistence_tokens (
    id bigint NOT NULL,
    token_salt character varying(255) NOT NULL,
    crypted_token character varying(255) NOT NULL,
    pseudonym_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: session_persistence_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.session_persistence_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: session_persistence_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.session_persistence_tokens_id_seq OWNED BY public.session_persistence_tokens.id;


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sessions (
    id bigint NOT NULL,
    session_id character varying(255) NOT NULL,
    data text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sessions_id_seq OWNED BY public.sessions.id;


--
-- Name: settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.settings (
    id bigint NOT NULL,
    name character varying(255),
    value text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    secret boolean DEFAULT false NOT NULL
);


--
-- Name: settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.settings_id_seq OWNED BY public.settings.id;


--
-- Name: shared_brand_configs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shared_brand_configs (
    id bigint NOT NULL,
    name character varying(255),
    account_id bigint,
    brand_config_md5 character varying(32) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: shared_brand_configs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.shared_brand_configs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: shared_brand_configs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.shared_brand_configs_id_seq OWNED BY public.shared_brand_configs.id;


--
-- Name: sis_batch_errors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sis_batch_errors (
    id bigint NOT NULL,
    sis_batch_id bigint NOT NULL,
    root_account_id bigint NOT NULL,
    message text NOT NULL,
    backtrace text,
    file character varying(255),
    failure boolean DEFAULT false NOT NULL,
    "row" integer,
    created_at timestamp without time zone NOT NULL,
    row_info text
);


--
-- Name: sis_batch_errors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sis_batch_errors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sis_batch_errors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sis_batch_errors_id_seq OWNED BY public.sis_batch_errors.id;


--
-- Name: sis_batch_roll_back_data; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sis_batch_roll_back_data (
    id bigint NOT NULL,
    sis_batch_id bigint NOT NULL,
    context_type character varying(255) NOT NULL,
    context_id bigint NOT NULL,
    previous_workflow_state character varying(255) NOT NULL,
    updated_workflow_state character varying(255) NOT NULL,
    batch_mode_delete boolean DEFAULT false NOT NULL,
    workflow_state character varying(255) DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: sis_batch_roll_back_data_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sis_batch_roll_back_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sis_batch_roll_back_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sis_batch_roll_back_data_id_seq OWNED BY public.sis_batch_roll_back_data.id;


--
-- Name: sis_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sis_batches (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    ended_at timestamp without time zone,
    workflow_state character varying(255) NOT NULL,
    data text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    attachment_id bigint,
    progress integer,
    processing_errors text,
    processing_warnings text,
    batch_mode boolean,
    batch_mode_term_id bigint,
    options text,
    user_id bigint,
    started_at timestamp without time zone,
    diffing_data_set_identifier character varying(255),
    diffing_remaster boolean,
    generated_diff_id bigint,
    errors_attachment_id bigint,
    change_threshold integer,
    diffing_threshold_exceeded boolean DEFAULT false NOT NULL,
    job_ids bigint[] DEFAULT '{}'::bigint[] NOT NULL
);


--
-- Name: sis_batches_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sis_batches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sis_batches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sis_batches_id_seq OWNED BY public.sis_batches.id;


--
-- Name: sis_post_grades_statuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sis_post_grades_statuses (
    id bigint NOT NULL,
    course_id bigint NOT NULL,
    course_section_id bigint,
    user_id bigint,
    status character varying(255) NOT NULL,
    message character varying(255) NOT NULL,
    grades_posted_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: sis_post_grades_statuses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sis_post_grades_statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sis_post_grades_statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sis_post_grades_statuses_id_seq OWNED BY public.sis_post_grades_statuses.id;


--
-- Name: standard_grade_statuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.standard_grade_statuses (
    id bigint NOT NULL,
    color character varying(7) NOT NULL,
    status_name character varying NOT NULL,
    hidden boolean DEFAULT false NOT NULL,
    root_account_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: standard_grade_statuses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.standard_grade_statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: standard_grade_statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.standard_grade_statuses_id_seq OWNED BY public.standard_grade_statuses.id;


--
-- Name: stream_item_instances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stream_item_instances (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    stream_item_id bigint NOT NULL,
    hidden boolean DEFAULT false NOT NULL,
    workflow_state character varying(255),
    context_type character varying(255),
    context_id bigint
);


--
-- Name: stream_item_instances_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.stream_item_instances_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stream_item_instances_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.stream_item_instances_id_seq OWNED BY public.stream_item_instances.id;


--
-- Name: stream_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stream_items (
    id bigint NOT NULL,
    data text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    context_type character varying(255),
    context_id bigint,
    asset_type character varying(255) NOT NULL,
    asset_id bigint,
    notification_category character varying(255)
);


--
-- Name: stream_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.stream_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stream_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.stream_items_id_seq OWNED BY public.stream_items.id;


--
-- Name: submission_comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.submission_comments (
    id bigint NOT NULL,
    comment text,
    submission_id bigint,
    author_id bigint,
    author_name character varying(255),
    group_comment_id character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    attachment_ids text,
    assessment_request_id bigint,
    media_comment_id character varying(255),
    media_comment_type character varying(255),
    context_id bigint,
    context_type character varying(255),
    cached_attachments text,
    anonymous boolean,
    teacher_only_comment boolean DEFAULT false,
    hidden boolean DEFAULT false,
    provisional_grade_id bigint,
    draft boolean DEFAULT false NOT NULL,
    edited_at timestamp without time zone,
    attempt integer,
    root_account_id bigint,
    workflow_state character varying DEFAULT 'active'::character varying NOT NULL
);


--
-- Name: submission_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.submission_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: submission_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.submission_comments_id_seq OWNED BY public.submission_comments.id;


--
-- Name: submission_draft_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.submission_draft_attachments (
    id bigint NOT NULL,
    submission_draft_id bigint NOT NULL,
    attachment_id bigint NOT NULL
);


--
-- Name: submission_draft_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.submission_draft_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: submission_draft_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.submission_draft_attachments_id_seq OWNED BY public.submission_draft_attachments.id;


--
-- Name: submission_drafts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.submission_drafts (
    id bigint NOT NULL,
    submission_id bigint NOT NULL,
    submission_attempt integer NOT NULL,
    body text,
    url text,
    active_submission_type character varying,
    media_object_id character varying,
    context_external_tool_id bigint,
    lti_launch_url text,
    resource_link_lookup_uuid uuid
);


--
-- Name: submission_drafts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.submission_drafts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: submission_drafts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.submission_drafts_id_seq OWNED BY public.submission_drafts.id;


--
-- Name: submission_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.submission_versions (
    id bigint NOT NULL,
    context_id bigint,
    context_type character varying(255),
    version_id bigint,
    user_id bigint,
    assignment_id bigint,
    root_account_id bigint
);


--
-- Name: submission_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.submission_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: submission_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.submission_versions_id_seq OWNED BY public.submission_versions.id;


--
-- Name: submissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.submissions (
    id bigint NOT NULL,
    body text,
    url character varying(255),
    attachment_id bigint,
    grade character varying(255),
    score double precision,
    submitted_at timestamp without time zone,
    assignment_id bigint NOT NULL,
    user_id bigint NOT NULL,
    submission_type character varying(255),
    workflow_state character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    group_id bigint,
    attachment_ids text,
    processed boolean,
    grade_matches_current_submission boolean,
    published_score double precision,
    published_grade character varying(255),
    graded_at timestamp without time zone,
    student_entered_score double precision,
    grader_id bigint,
    media_comment_id character varying(255),
    media_comment_type character varying(255),
    quiz_submission_id bigint,
    submission_comments_count integer,
    attempt integer,
    media_object_id bigint,
    turnitin_data text,
    cached_due_date timestamp without time zone,
    excused boolean,
    graded_anonymously boolean,
    late_policy_status character varying(16),
    points_deducted numeric(6,2),
    grading_period_id bigint,
    seconds_late_override bigint,
    lti_user_id character varying,
    anonymous_id character varying(5),
    last_comment_at timestamp without time zone,
    extra_attempts integer,
    posted_at timestamp without time zone,
    cached_quiz_lti boolean DEFAULT false NOT NULL,
    cached_tardiness character varying(16),
    course_id bigint NOT NULL,
    root_account_id bigint,
    redo_request boolean DEFAULT false NOT NULL,
    resource_link_lookup_uuid uuid,
    proxy_submitter_id bigint,
    custom_grade_status_id bigint,
    sticker character varying(255)
);


--
-- Name: submissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.submissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: submissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.submissions_id_seq OWNED BY public.submissions.id;


--
-- Name: switchman_shards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.switchman_shards (
    id bigint NOT NULL,
    name character varying(255),
    database_server_id character varying(255),
    "default" boolean DEFAULT false NOT NULL,
    settings text,
    delayed_jobs_shard_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    block_stranded boolean DEFAULT false,
    jobs_held boolean DEFAULT false
);


--
-- Name: switchman_shards_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.switchman_shards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: switchman_shards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.switchman_shards_id_seq OWNED BY public.switchman_shards.id;


--
-- Name: temporary_enrollment_pairings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.temporary_enrollment_pairings (
    id bigint NOT NULL,
    root_account_id bigint NOT NULL,
    workflow_state character varying(255) DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    created_by_id bigint,
    deleted_by_id bigint,
    ending_enrollment_state text
);


--
-- Name: temporary_enrollment_pairings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.temporary_enrollment_pairings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: temporary_enrollment_pairings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.temporary_enrollment_pairings_id_seq OWNED BY public.temporary_enrollment_pairings.id;


--
-- Name: terms_of_service_contents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.terms_of_service_contents (
    id bigint NOT NULL,
    content text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    terms_updated_at timestamp without time zone NOT NULL,
    workflow_state character varying NOT NULL,
    account_id bigint
);


--
-- Name: terms_of_service_contents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.terms_of_service_contents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: terms_of_service_contents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.terms_of_service_contents_id_seq OWNED BY public.terms_of_service_contents.id;


--
-- Name: terms_of_services; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.terms_of_services (
    id bigint NOT NULL,
    terms_type character varying DEFAULT 'default'::character varying NOT NULL,
    passive boolean DEFAULT true NOT NULL,
    terms_of_service_content_id bigint,
    account_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    workflow_state character varying NOT NULL
);


--
-- Name: terms_of_services_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.terms_of_services_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: terms_of_services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.terms_of_services_id_seq OWNED BY public.terms_of_services.id;


--
-- Name: thumbnails; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.thumbnails (
    id bigint NOT NULL,
    parent_id bigint,
    content_type character varying(255) NOT NULL,
    filename character varying(255) NOT NULL,
    thumbnail character varying(255),
    size integer NOT NULL,
    width integer,
    height integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    uuid character varying(255),
    namespace character varying(255)
);


--
-- Name: thumbnails_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.thumbnails_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: thumbnails_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.thumbnails_id_seq OWNED BY public.thumbnails.id;


--
-- Name: usage_rights; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usage_rights (
    id bigint NOT NULL,
    context_id bigint NOT NULL,
    context_type character varying(255) NOT NULL,
    use_justification character varying(255) NOT NULL,
    license character varying(255) NOT NULL,
    legal_copyright text
);


--
-- Name: usage_rights_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.usage_rights_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: usage_rights_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.usage_rights_id_seq OWNED BY public.usage_rights.id;


--
-- Name: user_account_associations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_account_associations (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    account_id bigint NOT NULL,
    depth integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    root_account_id bigint NOT NULL
);


--
-- Name: user_account_associations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_account_associations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_account_associations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_account_associations_id_seq OWNED BY public.user_account_associations.id;


--
-- Name: user_lmgb_outcome_orderings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_lmgb_outcome_orderings (
    id bigint NOT NULL,
    root_account_id bigint NOT NULL,
    user_id bigint NOT NULL,
    course_id bigint NOT NULL,
    learning_outcome_id bigint NOT NULL,
    "position" integer NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: user_lmgb_outcome_orderings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_lmgb_outcome_orderings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_lmgb_outcome_orderings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_lmgb_outcome_orderings_id_seq OWNED BY public.user_lmgb_outcome_orderings.id;


--
-- Name: user_merge_data; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_merge_data (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    from_user_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    workflow_state character varying(255) DEFAULT 'active'::character varying NOT NULL
);


--
-- Name: user_merge_data_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_merge_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_merge_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_merge_data_id_seq OWNED BY public.user_merge_data.id;


--
-- Name: user_merge_data_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_merge_data_items (
    id bigint NOT NULL,
    user_merge_data_id bigint NOT NULL,
    user_id bigint NOT NULL,
    item_type character varying(255) NOT NULL,
    item text NOT NULL
);


--
-- Name: user_merge_data_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_merge_data_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_merge_data_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_merge_data_items_id_seq OWNED BY public.user_merge_data_items.id;


--
-- Name: user_merge_data_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_merge_data_records (
    id bigint NOT NULL,
    user_merge_data_id bigint NOT NULL,
    context_id bigint NOT NULL,
    previous_user_id bigint NOT NULL,
    context_type character varying(255) NOT NULL,
    previous_workflow_state character varying(255)
);


--
-- Name: user_merge_data_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_merge_data_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_merge_data_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_merge_data_records_id_seq OWNED BY public.user_merge_data_records.id;


--
-- Name: user_notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_notes (
    id bigint NOT NULL,
    user_id bigint,
    note text,
    title character varying(255),
    created_by_id bigint,
    workflow_state character varying(255) DEFAULT 'active'::character varying NOT NULL,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    root_account_id bigint NOT NULL
);


--
-- Name: user_notes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_notes_id_seq OWNED BY public.user_notes.id;


--
-- Name: user_observers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_observers (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    observer_id bigint NOT NULL,
    workflow_state character varying(255) DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    sis_batch_id bigint,
    root_account_id bigint NOT NULL
);


--
-- Name: user_observers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_observers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_observers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_observers_id_seq OWNED BY public.user_observers.id;


--
-- Name: user_past_lti_ids; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_past_lti_ids (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    context_id bigint NOT NULL,
    context_type character varying(255) NOT NULL,
    user_uuid character varying(255) NOT NULL,
    user_lti_id text NOT NULL,
    user_lti_context_id character varying(255)
);


--
-- Name: user_past_lti_ids_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_past_lti_ids_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_past_lti_ids_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_past_lti_ids_id_seq OWNED BY public.user_past_lti_ids.id;


--
-- Name: user_preference_values; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_preference_values (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    key character varying NOT NULL,
    sub_key character varying,
    value text
);


--
-- Name: user_preference_values_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_preference_values_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_preference_values_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_preference_values_id_seq OWNED BY public.user_preference_values.id;


--
-- Name: user_profile_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_profile_links (
    id bigint NOT NULL,
    url character varying(4096),
    title character varying(255),
    user_profile_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: user_profile_links_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_profile_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_profile_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_profile_links_id_seq OWNED BY public.user_profile_links.id;


--
-- Name: user_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_profiles (
    id bigint NOT NULL,
    bio text,
    title character varying(255),
    user_id bigint NOT NULL
);


--
-- Name: user_profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_profiles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_profiles_id_seq OWNED BY public.user_profiles.id;


--
-- Name: user_services; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_services (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    token text,
    secret character varying(255),
    protocol character varying(255),
    service character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    service_user_url character varying(255),
    service_user_id character varying(255) NOT NULL,
    service_user_name character varying(255),
    service_domain character varying(255),
    crypted_password character varying(255),
    password_salt character varying(255),
    type character varying(255),
    workflow_state character varying(255) NOT NULL,
    last_result_id character varying(255),
    refresh_at timestamp without time zone,
    visible boolean
);


--
-- Name: user_services_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_services_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_services_id_seq OWNED BY public.user_services.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    name character varying(255),
    sortable_name character varying(255),
    workflow_state character varying(255) NOT NULL,
    time_zone character varying(255),
    uuid character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    avatar_image_url character varying(255),
    avatar_image_source character varying(255),
    avatar_image_updated_at timestamp without time zone,
    phone character varying(255),
    school_name character varying(255),
    school_position character varying(255),
    short_name character varying(255),
    deleted_at timestamp without time zone,
    show_user_services boolean DEFAULT true,
    page_views_count integer DEFAULT 0,
    reminder_time_for_due_dates integer DEFAULT 172800,
    reminder_time_for_grading integer DEFAULT 0,
    storage_quota bigint,
    visible_inbox_types character varying(255),
    last_user_note timestamp without time zone,
    subscribe_to_emails boolean,
    features_used text,
    preferences text,
    avatar_state character varying(255),
    locale character varying(255),
    browser_locale character varying(255),
    unread_conversations_count integer DEFAULT 0,
    stuck_sis_fields text,
    public boolean,
    otp_secret_key_enc character varying(255),
    otp_secret_key_salt character varying(255),
    otp_communication_channel_id bigint,
    initial_enrollment_type character varying(255),
    crocodoc_id integer,
    last_logged_out timestamp without time zone,
    lti_context_id character varying(255),
    turnitin_id bigint,
    lti_id text,
    pronouns character varying,
    root_account_ids bigint[] DEFAULT '{}'::bigint[] NOT NULL,
    merged_into_user_id bigint
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.versions (
    id bigint NOT NULL,
    versionable_id bigint,
    versionable_type character varying(255),
    number integer,
    yaml text,
    created_at timestamp without time zone
);


--
-- Name: versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.versions_id_seq OWNED BY public.versions.id;


--
-- Name: versions_0; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.versions_0 (
    id bigint DEFAULT nextval('public.versions_id_seq'::regclass),
    versionable_id bigint,
    versionable_type character varying(255),
    number integer,
    yaml text,
    created_at timestamp without time zone,
    CONSTRAINT versions_0_versionable_id_check CHECK ((versionable_id < 5000000))
)
INHERITS (public.versions);


--
-- Name: versions_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.versions_1 (
    id bigint DEFAULT nextval('public.versions_id_seq'::regclass),
    versionable_id bigint,
    versionable_type character varying(255),
    number integer,
    yaml text,
    created_at timestamp without time zone,
    CONSTRAINT versions_1_versionable_id_check CHECK (((versionable_id >= 5000000) AND (versionable_id < 10000000)))
)
INHERITS (public.versions);


--
-- Name: viewed_submission_comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.viewed_submission_comments (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    submission_comment_id bigint NOT NULL,
    viewed_at timestamp without time zone NOT NULL
);


--
-- Name: viewed_submission_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.viewed_submission_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: viewed_submission_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.viewed_submission_comments_id_seq OWNED BY public.viewed_submission_comments.id;


--
-- Name: web_conference_participants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.web_conference_participants (
    id bigint NOT NULL,
    user_id bigint,
    web_conference_id bigint,
    participation_type character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    root_account_id bigint NOT NULL
);


--
-- Name: web_conference_participants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.web_conference_participants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: web_conference_participants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.web_conference_participants_id_seq OWNED BY public.web_conference_participants.id;


--
-- Name: web_conferences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.web_conferences (
    id bigint NOT NULL,
    title character varying(255) NOT NULL,
    conference_type character varying(255) NOT NULL,
    conference_key character varying(255),
    context_id bigint NOT NULL,
    context_type character varying(255) NOT NULL,
    user_ids character varying(255),
    added_user_ids character varying(255),
    user_id bigint NOT NULL,
    started_at timestamp without time zone,
    description text,
    duration double precision,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    uuid character varying(255),
    invited_user_ids character varying(255),
    ended_at timestamp without time zone,
    start_at timestamp without time zone,
    end_at timestamp without time zone,
    context_code character varying(255),
    type character varying(255),
    settings text,
    recording_ready boolean,
    root_account_id bigint NOT NULL
);


--
-- Name: web_conferences_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.web_conferences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: web_conferences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.web_conferences_id_seq OWNED BY public.web_conferences.id;


--
-- Name: wiki_page_lookups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wiki_page_lookups (
    id bigint NOT NULL,
    slug text NOT NULL,
    wiki_page_id bigint NOT NULL,
    root_account_id bigint NOT NULL,
    context_id bigint NOT NULL,
    context_type character varying(255) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: wiki_page_lookups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.wiki_page_lookups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wiki_page_lookups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.wiki_page_lookups_id_seq OWNED BY public.wiki_page_lookups.id;


--
-- Name: wiki_pages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wiki_pages (
    id bigint NOT NULL,
    wiki_id bigint NOT NULL,
    title character varying(255),
    body text,
    workflow_state character varying(255) NOT NULL,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    url text,
    protected_editing boolean DEFAULT false,
    editing_roles character varying(255),
    revised_at timestamp without time zone,
    could_be_locked boolean,
    cloned_item_id bigint,
    migration_id character varying(255),
    assignment_id bigint,
    old_assignment_id bigint,
    todo_date timestamp without time zone,
    context_id bigint NOT NULL,
    context_type character varying NOT NULL,
    root_account_id bigint,
    publish_at timestamp without time zone,
    current_lookup_id bigint,
    unlock_at timestamp(6) without time zone,
    lock_at timestamp(6) without time zone,
    only_visible_to_overrides boolean DEFAULT false NOT NULL
);


--
-- Name: wiki_pages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.wiki_pages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wiki_pages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.wiki_pages_id_seq OWNED BY public.wiki_pages.id;


--
-- Name: wikis; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wikis (
    id bigint NOT NULL,
    title character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    front_page_url text,
    has_no_front_page boolean,
    root_account_id bigint
);


--
-- Name: wikis_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.wikis_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wikis_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.wikis_id_seq OWNED BY public.wikis.id;


--
-- Name: abstract_courses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.abstract_courses ALTER COLUMN id SET DEFAULT nextval('public.abstract_courses_id_seq'::regclass);


--
-- Name: access_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.access_tokens ALTER COLUMN id SET DEFAULT nextval('public.access_tokens_id_seq'::regclass);


--
-- Name: account_notification_roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_notification_roles ALTER COLUMN id SET DEFAULT nextval('public.account_notification_roles_id_seq'::regclass);


--
-- Name: account_notifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_notifications ALTER COLUMN id SET DEFAULT nextval('public.account_notifications_id_seq'::regclass);


--
-- Name: account_report_rows id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_report_rows ALTER COLUMN id SET DEFAULT nextval('public.account_report_rows_id_seq'::regclass);


--
-- Name: account_report_runners id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_report_runners ALTER COLUMN id SET DEFAULT nextval('public.account_report_runners_id_seq'::regclass);


--
-- Name: account_reports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_reports ALTER COLUMN id SET DEFAULT nextval('public.account_reports_id_seq'::regclass);


--
-- Name: account_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_users ALTER COLUMN id SET DEFAULT nextval('public.account_users_id_seq'::regclass);


--
-- Name: accounts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts ALTER COLUMN id SET DEFAULT nextval('public.accounts_id_seq'::regclass);


--
-- Name: alert_criteria id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alert_criteria ALTER COLUMN id SET DEFAULT nextval('public.alert_criteria_id_seq'::regclass);


--
-- Name: alerts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alerts ALTER COLUMN id SET DEFAULT nextval('public.alerts_id_seq'::regclass);


--
-- Name: anonymous_or_moderation_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.anonymous_or_moderation_events ALTER COLUMN id SET DEFAULT nextval('public.anonymous_or_moderation_events_id_seq'::regclass);


--
-- Name: appointment_group_contexts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appointment_group_contexts ALTER COLUMN id SET DEFAULT nextval('public.appointment_group_contexts_id_seq'::regclass);


--
-- Name: appointment_group_sub_contexts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appointment_group_sub_contexts ALTER COLUMN id SET DEFAULT nextval('public.appointment_group_sub_contexts_id_seq'::regclass);


--
-- Name: appointment_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appointment_groups ALTER COLUMN id SET DEFAULT nextval('public.appointment_groups_id_seq'::regclass);


--
-- Name: assessment_question_bank_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessment_question_bank_users ALTER COLUMN id SET DEFAULT nextval('public.assessment_question_bank_users_id_seq'::regclass);


--
-- Name: assessment_question_banks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessment_question_banks ALTER COLUMN id SET DEFAULT nextval('public.assessment_question_banks_id_seq'::regclass);


--
-- Name: assessment_questions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessment_questions ALTER COLUMN id SET DEFAULT nextval('public.assessment_questions_id_seq'::regclass);


--
-- Name: assessment_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessment_requests ALTER COLUMN id SET DEFAULT nextval('public.assessment_requests_id_seq'::regclass);


--
-- Name: asset_user_accesses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_user_accesses ALTER COLUMN id SET DEFAULT nextval('public.asset_user_accesses_id_seq'::regclass);


--
-- Name: assignment_configuration_tool_lookups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_configuration_tool_lookups ALTER COLUMN id SET DEFAULT nextval('public.assignment_configuration_tool_lookups_id_seq'::regclass);


--
-- Name: assignment_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_groups ALTER COLUMN id SET DEFAULT nextval('public.assignment_groups_id_seq'::regclass);


--
-- Name: assignment_override_students id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_override_students ALTER COLUMN id SET DEFAULT nextval('public.assignment_override_students_id_seq'::regclass);


--
-- Name: assignment_overrides id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_overrides ALTER COLUMN id SET DEFAULT nextval('public.assignment_overrides_id_seq'::regclass);


--
-- Name: assignments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignments ALTER COLUMN id SET DEFAULT nextval('public.assignments_id_seq'::regclass);


--
-- Name: attachment_associations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attachment_associations ALTER COLUMN id SET DEFAULT nextval('public.attachment_associations_id_seq'::regclass);


--
-- Name: attachment_upload_statuses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attachment_upload_statuses ALTER COLUMN id SET DEFAULT nextval('public.attachment_upload_statuses_id_seq'::regclass);


--
-- Name: attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attachments ALTER COLUMN id SET DEFAULT nextval('public.attachments_id_seq'::regclass);


--
-- Name: aua_logs_0 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aua_logs_0 ALTER COLUMN id SET DEFAULT nextval('public.aua_logs_0_id_seq'::regclass);


--
-- Name: aua_logs_1 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aua_logs_1 ALTER COLUMN id SET DEFAULT nextval('public.aua_logs_1_id_seq'::regclass);


--
-- Name: aua_logs_2 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aua_logs_2 ALTER COLUMN id SET DEFAULT nextval('public.aua_logs_2_id_seq'::regclass);


--
-- Name: aua_logs_3 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aua_logs_3 ALTER COLUMN id SET DEFAULT nextval('public.aua_logs_3_id_seq'::regclass);


--
-- Name: aua_logs_4 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aua_logs_4 ALTER COLUMN id SET DEFAULT nextval('public.aua_logs_4_id_seq'::regclass);


--
-- Name: aua_logs_5 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aua_logs_5 ALTER COLUMN id SET DEFAULT nextval('public.aua_logs_5_id_seq'::regclass);


--
-- Name: aua_logs_6 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aua_logs_6 ALTER COLUMN id SET DEFAULT nextval('public.aua_logs_6_id_seq'::regclass);


--
-- Name: auditor_authentication_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_authentication_records ALTER COLUMN id SET DEFAULT nextval('public.auditor_authentication_records_id_seq'::regclass);


--
-- Name: auditor_course_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_course_records ALTER COLUMN id SET DEFAULT nextval('public.auditor_course_records_id_seq'::regclass);


--
-- Name: auditor_feature_flag_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_feature_flag_records ALTER COLUMN id SET DEFAULT nextval('public.auditor_feature_flag_records_id_seq'::regclass);


--
-- Name: auditor_grade_change_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_grade_change_records ALTER COLUMN id SET DEFAULT nextval('public.auditor_grade_change_records_id_seq'::regclass);


--
-- Name: auditor_pseudonym_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_pseudonym_records ALTER COLUMN id SET DEFAULT nextval('public.auditor_pseudonym_records_id_seq'::regclass);


--
-- Name: authentication_providers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authentication_providers ALTER COLUMN id SET DEFAULT nextval('public.authentication_providers_id_seq'::regclass);


--
-- Name: blackout_dates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blackout_dates ALTER COLUMN id SET DEFAULT nextval('public.blackout_dates_id_seq'::regclass);


--
-- Name: block_editors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.block_editors ALTER COLUMN id SET DEFAULT nextval('public.block_editors_id_seq'::regclass);


--
-- Name: bookmarks_bookmarks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookmarks_bookmarks ALTER COLUMN id SET DEFAULT nextval('public.bookmarks_bookmarks_id_seq'::regclass);


--
-- Name: calendar_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendar_events ALTER COLUMN id SET DEFAULT nextval('public.calendar_events_id_seq'::regclass);


--
-- Name: canvadocs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.canvadocs ALTER COLUMN id SET DEFAULT nextval('public.canvadocs_id_seq'::regclass);


--
-- Name: canvadocs_annotation_contexts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.canvadocs_annotation_contexts ALTER COLUMN id SET DEFAULT nextval('public.canvadocs_annotation_contexts_id_seq'::regclass);


--
-- Name: canvadocs_submissions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.canvadocs_submissions ALTER COLUMN id SET DEFAULT nextval('public.canvadocs_submissions_id_seq'::regclass);


--
-- Name: canvas_metadata id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.canvas_metadata ALTER COLUMN id SET DEFAULT nextval('public.canvas_metadata_id_seq'::regclass);


--
-- Name: cloned_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cloned_items ALTER COLUMN id SET DEFAULT nextval('public.cloned_items_id_seq'::regclass);


--
-- Name: collaborations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collaborations ALTER COLUMN id SET DEFAULT nextval('public.collaborations_id_seq'::regclass);


--
-- Name: collaborators id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collaborators ALTER COLUMN id SET DEFAULT nextval('public.collaborators_id_seq'::regclass);


--
-- Name: comment_bank_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comment_bank_items ALTER COLUMN id SET DEFAULT nextval('public.comment_bank_items_id_seq'::regclass);


--
-- Name: communication_channels id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.communication_channels ALTER COLUMN id SET DEFAULT nextval('public.communication_channels_id_seq'::regclass);


--
-- Name: conditional_release_assignment_set_actions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conditional_release_assignment_set_actions ALTER COLUMN id SET DEFAULT nextval('public.conditional_release_assignment_set_actions_id_seq'::regclass);


--
-- Name: conditional_release_assignment_set_associations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conditional_release_assignment_set_associations ALTER COLUMN id SET DEFAULT nextval('public.conditional_release_assignment_set_associations_id_seq'::regclass);


--
-- Name: conditional_release_assignment_sets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conditional_release_assignment_sets ALTER COLUMN id SET DEFAULT nextval('public.conditional_release_assignment_sets_id_seq'::regclass);


--
-- Name: conditional_release_rules id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conditional_release_rules ALTER COLUMN id SET DEFAULT nextval('public.conditional_release_rules_id_seq'::regclass);


--
-- Name: conditional_release_scoring_ranges id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conditional_release_scoring_ranges ALTER COLUMN id SET DEFAULT nextval('public.conditional_release_scoring_ranges_id_seq'::regclass);


--
-- Name: content_exports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_exports ALTER COLUMN id SET DEFAULT nextval('public.content_exports_id_seq'::regclass);


--
-- Name: content_migrations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_migrations ALTER COLUMN id SET DEFAULT nextval('public.content_migrations_id_seq'::regclass);


--
-- Name: content_participation_counts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_participation_counts ALTER COLUMN id SET DEFAULT nextval('public.content_participation_counts_id_seq'::regclass);


--
-- Name: content_participations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_participations ALTER COLUMN id SET DEFAULT nextval('public.content_participations_id_seq'::regclass);


--
-- Name: content_shares id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_shares ALTER COLUMN id SET DEFAULT nextval('public.content_shares_id_seq'::regclass);


--
-- Name: content_tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_tags ALTER COLUMN id SET DEFAULT nextval('public.content_tags_id_seq'::regclass);


--
-- Name: context_external_tool_placements id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.context_external_tool_placements ALTER COLUMN id SET DEFAULT nextval('public.context_external_tool_placements_id_seq'::regclass);


--
-- Name: context_external_tools id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.context_external_tools ALTER COLUMN id SET DEFAULT nextval('public.context_external_tools_id_seq'::regclass);


--
-- Name: context_module_progressions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.context_module_progressions ALTER COLUMN id SET DEFAULT nextval('public.context_module_progressions_id_seq'::regclass);


--
-- Name: context_modules id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.context_modules ALTER COLUMN id SET DEFAULT nextval('public.context_modules_id_seq'::regclass);


--
-- Name: conversation_batches id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_batches ALTER COLUMN id SET DEFAULT nextval('public.conversation_batches_id_seq'::regclass);


--
-- Name: conversation_message_participants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_message_participants ALTER COLUMN id SET DEFAULT nextval('public.conversation_message_participants_id_seq'::regclass);


--
-- Name: conversation_messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_messages ALTER COLUMN id SET DEFAULT nextval('public.conversation_messages_id_seq'::regclass);


--
-- Name: conversation_participants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_participants ALTER COLUMN id SET DEFAULT nextval('public.conversation_participants_id_seq'::regclass);


--
-- Name: conversations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations ALTER COLUMN id SET DEFAULT nextval('public.conversations_id_seq'::regclass);


--
-- Name: course_account_associations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_account_associations ALTER COLUMN id SET DEFAULT nextval('public.course_account_associations_id_seq'::regclass);


--
-- Name: course_pace_module_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_pace_module_items ALTER COLUMN id SET DEFAULT nextval('public.course_pace_module_items_id_seq'::regclass);


--
-- Name: course_paces id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_paces ALTER COLUMN id SET DEFAULT nextval('public.course_paces_id_seq'::regclass);


--
-- Name: course_score_statistics id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_score_statistics ALTER COLUMN id SET DEFAULT nextval('public.course_score_statistics_id_seq'::regclass);


--
-- Name: course_sections id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_sections ALTER COLUMN id SET DEFAULT nextval('public.course_sections_id_seq'::regclass);


--
-- Name: courses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courses ALTER COLUMN id SET DEFAULT nextval('public.courses_id_seq'::regclass);


--
-- Name: crocodoc_documents id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crocodoc_documents ALTER COLUMN id SET DEFAULT nextval('public.crocodoc_documents_id_seq'::regclass);


--
-- Name: csp_domains id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.csp_domains ALTER COLUMN id SET DEFAULT nextval('public.csp_domains_id_seq'::regclass);


--
-- Name: custom_data id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_data ALTER COLUMN id SET DEFAULT nextval('public.custom_data_id_seq'::regclass);


--
-- Name: custom_grade_statuses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_grade_statuses ALTER COLUMN id SET DEFAULT nextval('public.custom_grade_statuses_id_seq'::regclass);


--
-- Name: custom_gradebook_column_data id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_gradebook_column_data ALTER COLUMN id SET DEFAULT nextval('public.custom_gradebook_column_data_id_seq'::regclass);


--
-- Name: custom_gradebook_columns id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_gradebook_columns ALTER COLUMN id SET DEFAULT nextval('public.custom_gradebook_columns_id_seq'::regclass);


--
-- Name: delayed_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_jobs ALTER COLUMN id SET DEFAULT nextval('public.delayed_jobs_id_seq'::regclass);


--
-- Name: delayed_messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_messages ALTER COLUMN id SET DEFAULT nextval('public.delayed_messages_id_seq'::regclass);


--
-- Name: delayed_notifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_notifications ALTER COLUMN id SET DEFAULT nextval('public.delayed_notifications_id_seq'::regclass);


--
-- Name: developer_key_account_bindings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.developer_key_account_bindings ALTER COLUMN id SET DEFAULT nextval('public.developer_key_account_bindings_id_seq'::regclass);


--
-- Name: developer_keys id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.developer_keys ALTER COLUMN id SET DEFAULT nextval('public.developer_keys_id_seq'::regclass);


--
-- Name: discussion_entries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_entries ALTER COLUMN id SET DEFAULT nextval('public.discussion_entries_id_seq'::regclass);


--
-- Name: discussion_entry_drafts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_entry_drafts ALTER COLUMN id SET DEFAULT nextval('public.discussion_entry_drafts_id_seq'::regclass);


--
-- Name: discussion_entry_participants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_entry_participants ALTER COLUMN id SET DEFAULT nextval('public.discussion_entry_participants_id_seq'::regclass);


--
-- Name: discussion_entry_versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_entry_versions ALTER COLUMN id SET DEFAULT nextval('public.discussion_entry_versions_id_seq'::regclass);


--
-- Name: discussion_topic_participants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_topic_participants ALTER COLUMN id SET DEFAULT nextval('public.discussion_topic_participants_id_seq'::regclass);


--
-- Name: discussion_topic_section_visibilities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_topic_section_visibilities ALTER COLUMN id SET DEFAULT nextval('public.discussion_topic_section_visibilities_id_seq'::regclass);


--
-- Name: discussion_topics id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_topics ALTER COLUMN id SET DEFAULT nextval('public.discussion_topics_id_seq'::regclass);


--
-- Name: enrollment_dates_overrides id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enrollment_dates_overrides ALTER COLUMN id SET DEFAULT nextval('public.enrollment_dates_overrides_id_seq'::regclass);


--
-- Name: enrollment_terms id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enrollment_terms ALTER COLUMN id SET DEFAULT nextval('public.enrollment_terms_id_seq'::regclass);


--
-- Name: enrollments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enrollments ALTER COLUMN id SET DEFAULT nextval('public.enrollments_id_seq'::regclass);


--
-- Name: eportfolio_categories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eportfolio_categories ALTER COLUMN id SET DEFAULT nextval('public.eportfolio_categories_id_seq'::regclass);


--
-- Name: eportfolio_entries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eportfolio_entries ALTER COLUMN id SET DEFAULT nextval('public.eportfolio_entries_id_seq'::regclass);


--
-- Name: eportfolios id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eportfolios ALTER COLUMN id SET DEFAULT nextval('public.eportfolios_id_seq'::regclass);


--
-- Name: epub_exports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.epub_exports ALTER COLUMN id SET DEFAULT nextval('public.epub_exports_id_seq'::regclass);


--
-- Name: error_reports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.error_reports ALTER COLUMN id SET DEFAULT nextval('public.error_reports_id_seq'::regclass);


--
-- Name: event_stream_failures id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_stream_failures ALTER COLUMN id SET DEFAULT nextval('public.event_stream_failures_id_seq'::regclass);


--
-- Name: external_feed_entries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_feed_entries ALTER COLUMN id SET DEFAULT nextval('public.external_feed_entries_id_seq'::regclass);


--
-- Name: external_feeds id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_feeds ALTER COLUMN id SET DEFAULT nextval('public.external_feeds_id_seq'::regclass);


--
-- Name: external_integration_keys id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_integration_keys ALTER COLUMN id SET DEFAULT nextval('public.external_integration_keys_id_seq'::regclass);


--
-- Name: failed_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.failed_jobs ALTER COLUMN id SET DEFAULT nextval('public.failed_jobs_id_seq'::regclass);


--
-- Name: favorites id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.favorites ALTER COLUMN id SET DEFAULT nextval('public.favorites_id_seq'::regclass);


--
-- Name: feature_flags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feature_flags ALTER COLUMN id SET DEFAULT nextval('public.feature_flags_id_seq'::regclass);


--
-- Name: folders id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.folders ALTER COLUMN id SET DEFAULT nextval('public.folders_id_seq'::regclass);


--
-- Name: gradebook_csvs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gradebook_csvs ALTER COLUMN id SET DEFAULT nextval('public.gradebook_csvs_id_seq'::regclass);


--
-- Name: gradebook_filters id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gradebook_filters ALTER COLUMN id SET DEFAULT nextval('public.gradebook_filters_id_seq'::regclass);


--
-- Name: gradebook_uploads id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gradebook_uploads ALTER COLUMN id SET DEFAULT nextval('public.gradebook_uploads_id_seq'::regclass);


--
-- Name: grading_period_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grading_period_groups ALTER COLUMN id SET DEFAULT nextval('public.grading_period_groups_id_seq'::regclass);


--
-- Name: grading_periods id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grading_periods ALTER COLUMN id SET DEFAULT nextval('public.grading_periods_id_seq'::regclass);


--
-- Name: grading_standards id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grading_standards ALTER COLUMN id SET DEFAULT nextval('public.grading_standards_id_seq'::regclass);


--
-- Name: group_and_membership_importers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_and_membership_importers ALTER COLUMN id SET DEFAULT nextval('public.group_and_membership_importers_id_seq'::regclass);


--
-- Name: group_categories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_categories ALTER COLUMN id SET DEFAULT nextval('public.group_categories_id_seq'::regclass);


--
-- Name: group_memberships id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_memberships ALTER COLUMN id SET DEFAULT nextval('public.group_memberships_id_seq'::regclass);


--
-- Name: groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups ALTER COLUMN id SET DEFAULT nextval('public.groups_id_seq'::regclass);


--
-- Name: ignores id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ignores ALTER COLUMN id SET DEFAULT nextval('public.ignores_id_seq'::regclass);


--
-- Name: late_policies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.late_policies ALTER COLUMN id SET DEFAULT nextval('public.late_policies_id_seq'::regclass);


--
-- Name: learning_outcome_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.learning_outcome_groups ALTER COLUMN id SET DEFAULT nextval('public.learning_outcome_groups_id_seq'::regclass);


--
-- Name: learning_outcome_question_results id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.learning_outcome_question_results ALTER COLUMN id SET DEFAULT nextval('public.learning_outcome_question_results_id_seq'::regclass);


--
-- Name: learning_outcome_results id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.learning_outcome_results ALTER COLUMN id SET DEFAULT nextval('public.learning_outcome_results_id_seq'::regclass);


--
-- Name: learning_outcomes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.learning_outcomes ALTER COLUMN id SET DEFAULT nextval('public.learning_outcomes_id_seq'::regclass);


--
-- Name: live_assessments_assessments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.live_assessments_assessments ALTER COLUMN id SET DEFAULT nextval('public.live_assessments_assessments_id_seq'::regclass);


--
-- Name: live_assessments_results id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.live_assessments_results ALTER COLUMN id SET DEFAULT nextval('public.live_assessments_results_id_seq'::regclass);


--
-- Name: live_assessments_submissions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.live_assessments_submissions ALTER COLUMN id SET DEFAULT nextval('public.live_assessments_submissions_id_seq'::regclass);


--
-- Name: lti_ims_registrations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_ims_registrations ALTER COLUMN id SET DEFAULT nextval('public.lti_ims_registrations_id_seq'::regclass);


--
-- Name: lti_line_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_line_items ALTER COLUMN id SET DEFAULT nextval('public.lti_line_items_id_seq'::regclass);


--
-- Name: lti_links id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_links ALTER COLUMN id SET DEFAULT nextval('public.lti_links_id_seq'::regclass);


--
-- Name: lti_message_handlers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_message_handlers ALTER COLUMN id SET DEFAULT nextval('public.lti_message_handlers_id_seq'::regclass);


--
-- Name: lti_product_families id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_product_families ALTER COLUMN id SET DEFAULT nextval('public.lti_product_families_id_seq'::regclass);


--
-- Name: lti_resource_handlers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_resource_handlers ALTER COLUMN id SET DEFAULT nextval('public.lti_resource_handlers_id_seq'::regclass);


--
-- Name: lti_resource_links id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_resource_links ALTER COLUMN id SET DEFAULT nextval('public.lti_resource_links_id_seq'::regclass);


--
-- Name: lti_resource_placements id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_resource_placements ALTER COLUMN id SET DEFAULT nextval('public.lti_resource_placements_id_seq'::regclass);


--
-- Name: lti_results id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_results ALTER COLUMN id SET DEFAULT nextval('public.lti_results_id_seq'::regclass);


--
-- Name: lti_tool_configurations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_tool_configurations ALTER COLUMN id SET DEFAULT nextval('public.lti_tool_configurations_id_seq'::regclass);


--
-- Name: lti_tool_consumer_profiles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_tool_consumer_profiles ALTER COLUMN id SET DEFAULT nextval('public.lti_tool_consumer_profiles_id_seq'::regclass);


--
-- Name: lti_tool_proxies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_tool_proxies ALTER COLUMN id SET DEFAULT nextval('public.lti_tool_proxies_id_seq'::regclass);


--
-- Name: lti_tool_proxy_bindings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_tool_proxy_bindings ALTER COLUMN id SET DEFAULT nextval('public.lti_tool_proxy_bindings_id_seq'::regclass);


--
-- Name: lti_tool_settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_tool_settings ALTER COLUMN id SET DEFAULT nextval('public.lti_tool_settings_id_seq'::regclass);


--
-- Name: master_courses_child_content_tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.master_courses_child_content_tags ALTER COLUMN id SET DEFAULT nextval('public.master_courses_child_content_tags_id_seq'::regclass);


--
-- Name: master_courses_child_subscriptions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.master_courses_child_subscriptions ALTER COLUMN id SET DEFAULT nextval('public.master_courses_child_subscriptions_id_seq'::regclass);


--
-- Name: master_courses_master_content_tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.master_courses_master_content_tags ALTER COLUMN id SET DEFAULT nextval('public.master_courses_master_content_tags_id_seq'::regclass);


--
-- Name: master_courses_master_migrations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.master_courses_master_migrations ALTER COLUMN id SET DEFAULT nextval('public.master_courses_master_migrations_id_seq'::regclass);


--
-- Name: master_courses_master_templates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.master_courses_master_templates ALTER COLUMN id SET DEFAULT nextval('public.master_courses_master_templates_id_seq'::regclass);


--
-- Name: master_courses_migration_results id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.master_courses_migration_results ALTER COLUMN id SET DEFAULT nextval('public.master_courses_migration_results_id_seq'::regclass);


--
-- Name: media_objects id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media_objects ALTER COLUMN id SET DEFAULT nextval('public.media_objects_id_seq'::regclass);


--
-- Name: media_tracks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media_tracks ALTER COLUMN id SET DEFAULT nextval('public.media_tracks_id_seq'::regclass);


--
-- Name: mentions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mentions ALTER COLUMN id SET DEFAULT nextval('public.mentions_id_seq'::regclass);


--
-- Name: messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages ALTER COLUMN id SET DEFAULT nextval('public.messages_id_seq'::regclass);


--
-- Name: microsoft_sync_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.microsoft_sync_groups ALTER COLUMN id SET DEFAULT nextval('public.microsoft_sync_groups_id_seq'::regclass);


--
-- Name: microsoft_sync_partial_sync_changes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.microsoft_sync_partial_sync_changes ALTER COLUMN id SET DEFAULT nextval('public.microsoft_sync_partial_sync_changes_id_seq'::regclass);


--
-- Name: microsoft_sync_user_mappings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.microsoft_sync_user_mappings ALTER COLUMN id SET DEFAULT nextval('public.microsoft_sync_user_mappings_id_seq'::regclass);


--
-- Name: migration_issues id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.migration_issues ALTER COLUMN id SET DEFAULT nextval('public.migration_issues_id_seq'::regclass);


--
-- Name: moderated_grading_provisional_grades id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.moderated_grading_provisional_grades ALTER COLUMN id SET DEFAULT nextval('public.moderated_grading_provisional_grades_id_seq'::regclass);


--
-- Name: moderated_grading_selections id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.moderated_grading_selections ALTER COLUMN id SET DEFAULT nextval('public.moderated_grading_selections_id_seq'::regclass);


--
-- Name: moderation_graders id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.moderation_graders ALTER COLUMN id SET DEFAULT nextval('public.moderation_graders_id_seq'::regclass);


--
-- Name: notification_endpoints id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_endpoints ALTER COLUMN id SET DEFAULT nextval('public.notification_endpoints_id_seq'::regclass);


--
-- Name: notification_policies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_policies ALTER COLUMN id SET DEFAULT nextval('public.notification_policies_id_seq'::regclass);


--
-- Name: notification_policy_overrides id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_policy_overrides ALTER COLUMN id SET DEFAULT nextval('public.notification_policy_overrides_id_seq'::regclass);


--
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- Name: oauth_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_requests ALTER COLUMN id SET DEFAULT nextval('public.oauth_requests_id_seq'::regclass);


--
-- Name: observer_alert_thresholds id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.observer_alert_thresholds ALTER COLUMN id SET DEFAULT nextval('public.observer_alert_thresholds_id_seq'::regclass);


--
-- Name: observer_alerts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.observer_alerts ALTER COLUMN id SET DEFAULT nextval('public.observer_alerts_id_seq'::regclass);


--
-- Name: observer_pairing_codes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.observer_pairing_codes ALTER COLUMN id SET DEFAULT nextval('public.observer_pairing_codes_id_seq'::regclass);


--
-- Name: one_time_passwords id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.one_time_passwords ALTER COLUMN id SET DEFAULT nextval('public.one_time_passwords_id_seq'::regclass);


--
-- Name: originality_reports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.originality_reports ALTER COLUMN id SET DEFAULT nextval('public.originality_reports_id_seq'::regclass);


--
-- Name: outcome_calculation_methods id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outcome_calculation_methods ALTER COLUMN id SET DEFAULT nextval('public.outcome_calculation_methods_id_seq'::regclass);


--
-- Name: outcome_friendly_descriptions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outcome_friendly_descriptions ALTER COLUMN id SET DEFAULT nextval('public.outcome_friendly_descriptions_id_seq'::regclass);


--
-- Name: outcome_import_errors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outcome_import_errors ALTER COLUMN id SET DEFAULT nextval('public.outcome_import_errors_id_seq'::regclass);


--
-- Name: outcome_imports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outcome_imports ALTER COLUMN id SET DEFAULT nextval('public.outcome_imports_id_seq'::regclass);


--
-- Name: outcome_proficiencies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outcome_proficiencies ALTER COLUMN id SET DEFAULT nextval('public.outcome_proficiencies_id_seq'::regclass);


--
-- Name: outcome_proficiency_ratings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outcome_proficiency_ratings ALTER COLUMN id SET DEFAULT nextval('public.outcome_proficiency_ratings_id_seq'::regclass);


--
-- Name: page_comments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.page_comments ALTER COLUMN id SET DEFAULT nextval('public.page_comments_id_seq'::regclass);


--
-- Name: parallel_importers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parallel_importers ALTER COLUMN id SET DEFAULT nextval('public.parallel_importers_id_seq'::regclass);


--
-- Name: planner_notes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planner_notes ALTER COLUMN id SET DEFAULT nextval('public.planner_notes_id_seq'::regclass);


--
-- Name: planner_overrides id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planner_overrides ALTER COLUMN id SET DEFAULT nextval('public.planner_overrides_id_seq'::regclass);


--
-- Name: plugin_settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plugin_settings ALTER COLUMN id SET DEFAULT nextval('public.plugin_settings_id_seq'::regclass);


--
-- Name: polling_poll_choices id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.polling_poll_choices ALTER COLUMN id SET DEFAULT nextval('public.polling_poll_choices_id_seq'::regclass);


--
-- Name: polling_poll_sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.polling_poll_sessions ALTER COLUMN id SET DEFAULT nextval('public.polling_poll_sessions_id_seq'::regclass);


--
-- Name: polling_poll_submissions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.polling_poll_submissions ALTER COLUMN id SET DEFAULT nextval('public.polling_poll_submissions_id_seq'::regclass);


--
-- Name: polling_polls id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.polling_polls ALTER COLUMN id SET DEFAULT nextval('public.polling_polls_id_seq'::regclass);


--
-- Name: post_policies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_policies ALTER COLUMN id SET DEFAULT nextval('public.post_policies_id_seq'::regclass);


--
-- Name: profiles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles ALTER COLUMN id SET DEFAULT nextval('public.profiles_id_seq'::regclass);


--
-- Name: progresses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.progresses ALTER COLUMN id SET DEFAULT nextval('public.progresses_id_seq'::regclass);


--
-- Name: pseudonyms id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pseudonyms ALTER COLUMN id SET DEFAULT nextval('public.pseudonyms_id_seq'::regclass);


--
-- Name: purgatories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purgatories ALTER COLUMN id SET DEFAULT nextval('public.purgatories_id_seq'::regclass);


--
-- Name: quiz_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_groups ALTER COLUMN id SET DEFAULT nextval('public.quiz_groups_id_seq'::regclass);


--
-- Name: quiz_migration_alerts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_migration_alerts ALTER COLUMN id SET DEFAULT nextval('public.quiz_migration_alerts_id_seq'::regclass);


--
-- Name: quiz_question_regrades id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_question_regrades ALTER COLUMN id SET DEFAULT nextval('public.quiz_question_regrades_id_seq'::regclass);


--
-- Name: quiz_questions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_questions ALTER COLUMN id SET DEFAULT nextval('public.quiz_questions_id_seq'::regclass);


--
-- Name: quiz_regrade_runs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_regrade_runs ALTER COLUMN id SET DEFAULT nextval('public.quiz_regrade_runs_id_seq'::regclass);


--
-- Name: quiz_regrades id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_regrades ALTER COLUMN id SET DEFAULT nextval('public.quiz_regrades_id_seq'::regclass);


--
-- Name: quiz_statistics id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_statistics ALTER COLUMN id SET DEFAULT nextval('public.quiz_statistics_id_seq'::regclass);


--
-- Name: quiz_submission_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_submission_events ALTER COLUMN id SET DEFAULT nextval('public.quiz_submission_events_id_seq'::regclass);


--
-- Name: quiz_submission_snapshots id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_submission_snapshots ALTER COLUMN id SET DEFAULT nextval('public.quiz_submission_snapshots_id_seq'::regclass);


--
-- Name: quiz_submissions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_submissions ALTER COLUMN id SET DEFAULT nextval('public.quiz_submissions_id_seq'::regclass);


--
-- Name: quizzes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quizzes ALTER COLUMN id SET DEFAULT nextval('public.quizzes_id_seq'::regclass);


--
-- Name: report_snapshots id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_snapshots ALTER COLUMN id SET DEFAULT nextval('public.report_snapshots_id_seq'::regclass);


--
-- Name: role_overrides id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_overrides ALTER COLUMN id SET DEFAULT nextval('public.role_overrides_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- Name: rubric_assessments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rubric_assessments ALTER COLUMN id SET DEFAULT nextval('public.rubric_assessments_id_seq'::regclass);


--
-- Name: rubric_associations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rubric_associations ALTER COLUMN id SET DEFAULT nextval('public.rubric_associations_id_seq'::regclass);


--
-- Name: rubric_criteria id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rubric_criteria ALTER COLUMN id SET DEFAULT nextval('public.rubric_criteria_id_seq'::regclass);


--
-- Name: rubrics id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rubrics ALTER COLUMN id SET DEFAULT nextval('public.rubrics_id_seq'::regclass);


--
-- Name: scheduled_smart_alerts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scheduled_smart_alerts ALTER COLUMN id SET DEFAULT nextval('public.scheduled_smart_alerts_id_seq'::regclass);


--
-- Name: score_metadata id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.score_metadata ALTER COLUMN id SET DEFAULT nextval('public.score_metadata_id_seq'::regclass);


--
-- Name: score_statistics id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.score_statistics ALTER COLUMN id SET DEFAULT nextval('public.score_statistics_id_seq'::regclass);


--
-- Name: scores id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scores ALTER COLUMN id SET DEFAULT nextval('public.scores_id_seq'::regclass);


--
-- Name: session_persistence_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session_persistence_tokens ALTER COLUMN id SET DEFAULT nextval('public.session_persistence_tokens_id_seq'::regclass);


--
-- Name: sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions ALTER COLUMN id SET DEFAULT nextval('public.sessions_id_seq'::regclass);


--
-- Name: settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settings ALTER COLUMN id SET DEFAULT nextval('public.settings_id_seq'::regclass);


--
-- Name: shared_brand_configs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shared_brand_configs ALTER COLUMN id SET DEFAULT nextval('public.shared_brand_configs_id_seq'::regclass);


--
-- Name: sis_batch_errors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sis_batch_errors ALTER COLUMN id SET DEFAULT nextval('public.sis_batch_errors_id_seq'::regclass);


--
-- Name: sis_batch_roll_back_data id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sis_batch_roll_back_data ALTER COLUMN id SET DEFAULT nextval('public.sis_batch_roll_back_data_id_seq'::regclass);


--
-- Name: sis_batches id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sis_batches ALTER COLUMN id SET DEFAULT nextval('public.sis_batches_id_seq'::regclass);


--
-- Name: sis_post_grades_statuses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sis_post_grades_statuses ALTER COLUMN id SET DEFAULT nextval('public.sis_post_grades_statuses_id_seq'::regclass);


--
-- Name: standard_grade_statuses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.standard_grade_statuses ALTER COLUMN id SET DEFAULT nextval('public.standard_grade_statuses_id_seq'::regclass);


--
-- Name: stream_item_instances id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stream_item_instances ALTER COLUMN id SET DEFAULT nextval('public.stream_item_instances_id_seq'::regclass);


--
-- Name: stream_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stream_items ALTER COLUMN id SET DEFAULT nextval('public.stream_items_id_seq'::regclass);


--
-- Name: submission_comments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submission_comments ALTER COLUMN id SET DEFAULT nextval('public.submission_comments_id_seq'::regclass);


--
-- Name: submission_draft_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submission_draft_attachments ALTER COLUMN id SET DEFAULT nextval('public.submission_draft_attachments_id_seq'::regclass);


--
-- Name: submission_drafts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submission_drafts ALTER COLUMN id SET DEFAULT nextval('public.submission_drafts_id_seq'::regclass);


--
-- Name: submission_versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submission_versions ALTER COLUMN id SET DEFAULT nextval('public.submission_versions_id_seq'::regclass);


--
-- Name: submissions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submissions ALTER COLUMN id SET DEFAULT nextval('public.submissions_id_seq'::regclass);


--
-- Name: switchman_shards id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.switchman_shards ALTER COLUMN id SET DEFAULT nextval('public.switchman_shards_id_seq'::regclass);


--
-- Name: temporary_enrollment_pairings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.temporary_enrollment_pairings ALTER COLUMN id SET DEFAULT nextval('public.temporary_enrollment_pairings_id_seq'::regclass);


--
-- Name: terms_of_service_contents id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.terms_of_service_contents ALTER COLUMN id SET DEFAULT nextval('public.terms_of_service_contents_id_seq'::regclass);


--
-- Name: terms_of_services id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.terms_of_services ALTER COLUMN id SET DEFAULT nextval('public.terms_of_services_id_seq'::regclass);


--
-- Name: thumbnails id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.thumbnails ALTER COLUMN id SET DEFAULT nextval('public.thumbnails_id_seq'::regclass);


--
-- Name: usage_rights id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usage_rights ALTER COLUMN id SET DEFAULT nextval('public.usage_rights_id_seq'::regclass);


--
-- Name: user_account_associations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_account_associations ALTER COLUMN id SET DEFAULT nextval('public.user_account_associations_id_seq'::regclass);


--
-- Name: user_lmgb_outcome_orderings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_lmgb_outcome_orderings ALTER COLUMN id SET DEFAULT nextval('public.user_lmgb_outcome_orderings_id_seq'::regclass);


--
-- Name: user_merge_data id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_merge_data ALTER COLUMN id SET DEFAULT nextval('public.user_merge_data_id_seq'::regclass);


--
-- Name: user_merge_data_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_merge_data_items ALTER COLUMN id SET DEFAULT nextval('public.user_merge_data_items_id_seq'::regclass);


--
-- Name: user_merge_data_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_merge_data_records ALTER COLUMN id SET DEFAULT nextval('public.user_merge_data_records_id_seq'::regclass);


--
-- Name: user_notes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_notes ALTER COLUMN id SET DEFAULT nextval('public.user_notes_id_seq'::regclass);


--
-- Name: user_observers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_observers ALTER COLUMN id SET DEFAULT nextval('public.user_observers_id_seq'::regclass);


--
-- Name: user_past_lti_ids id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_past_lti_ids ALTER COLUMN id SET DEFAULT nextval('public.user_past_lti_ids_id_seq'::regclass);


--
-- Name: user_preference_values id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_preference_values ALTER COLUMN id SET DEFAULT nextval('public.user_preference_values_id_seq'::regclass);


--
-- Name: user_profile_links id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_profile_links ALTER COLUMN id SET DEFAULT nextval('public.user_profile_links_id_seq'::regclass);


--
-- Name: user_profiles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_profiles ALTER COLUMN id SET DEFAULT nextval('public.user_profiles_id_seq'::regclass);


--
-- Name: user_services id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_services ALTER COLUMN id SET DEFAULT nextval('public.user_services_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions ALTER COLUMN id SET DEFAULT nextval('public.versions_id_seq'::regclass);


--
-- Name: viewed_submission_comments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.viewed_submission_comments ALTER COLUMN id SET DEFAULT nextval('public.viewed_submission_comments_id_seq'::regclass);


--
-- Name: web_conference_participants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.web_conference_participants ALTER COLUMN id SET DEFAULT nextval('public.web_conference_participants_id_seq'::regclass);


--
-- Name: web_conferences id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.web_conferences ALTER COLUMN id SET DEFAULT nextval('public.web_conferences_id_seq'::regclass);


--
-- Name: wiki_page_lookups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wiki_page_lookups ALTER COLUMN id SET DEFAULT nextval('public.wiki_page_lookups_id_seq'::regclass);


--
-- Name: wiki_pages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wiki_pages ALTER COLUMN id SET DEFAULT nextval('public.wiki_pages_id_seq'::regclass);


--
-- Name: wikis id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wikis ALTER COLUMN id SET DEFAULT nextval('public.wikis_id_seq'::regclass);


--
-- Name: abstract_courses abstract_courses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.abstract_courses
    ADD CONSTRAINT abstract_courses_pkey PRIMARY KEY (id);


--
-- Name: access_tokens access_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.access_tokens
    ADD CONSTRAINT access_tokens_pkey PRIMARY KEY (id);


--
-- Name: account_notification_roles account_notification_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_notification_roles
    ADD CONSTRAINT account_notification_roles_pkey PRIMARY KEY (id);


--
-- Name: account_notifications account_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_notifications
    ADD CONSTRAINT account_notifications_pkey PRIMARY KEY (id);


--
-- Name: account_report_rows account_report_rows_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_report_rows
    ADD CONSTRAINT account_report_rows_pkey PRIMARY KEY (id);


--
-- Name: account_report_runners account_report_runners_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_report_runners
    ADD CONSTRAINT account_report_runners_pkey PRIMARY KEY (id);


--
-- Name: account_reports account_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_reports
    ADD CONSTRAINT account_reports_pkey PRIMARY KEY (id);


--
-- Name: account_users account_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_users
    ADD CONSTRAINT account_users_pkey PRIMARY KEY (id);


--
-- Name: accounts accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);


--
-- Name: alert_criteria alert_criteria_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alert_criteria
    ADD CONSTRAINT alert_criteria_pkey PRIMARY KEY (id);


--
-- Name: alerts alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT alerts_pkey PRIMARY KEY (id);


--
-- Name: anonymous_or_moderation_events anonymous_or_moderation_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.anonymous_or_moderation_events
    ADD CONSTRAINT anonymous_or_moderation_events_pkey PRIMARY KEY (id);


--
-- Name: appointment_group_contexts appointment_group_contexts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appointment_group_contexts
    ADD CONSTRAINT appointment_group_contexts_pkey PRIMARY KEY (id);


--
-- Name: appointment_group_sub_contexts appointment_group_sub_contexts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appointment_group_sub_contexts
    ADD CONSTRAINT appointment_group_sub_contexts_pkey PRIMARY KEY (id);


--
-- Name: appointment_groups appointment_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appointment_groups
    ADD CONSTRAINT appointment_groups_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: assessment_question_bank_users assessment_question_bank_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessment_question_bank_users
    ADD CONSTRAINT assessment_question_bank_users_pkey PRIMARY KEY (id);


--
-- Name: assessment_question_banks assessment_question_banks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessment_question_banks
    ADD CONSTRAINT assessment_question_banks_pkey PRIMARY KEY (id);


--
-- Name: assessment_questions assessment_questions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessment_questions
    ADD CONSTRAINT assessment_questions_pkey PRIMARY KEY (id);


--
-- Name: assessment_requests assessment_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessment_requests
    ADD CONSTRAINT assessment_requests_pkey PRIMARY KEY (id);


--
-- Name: asset_user_accesses asset_user_accesses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_user_accesses
    ADD CONSTRAINT asset_user_accesses_pkey PRIMARY KEY (id);


--
-- Name: assignment_configuration_tool_lookups assignment_configuration_tool_lookups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_configuration_tool_lookups
    ADD CONSTRAINT assignment_configuration_tool_lookups_pkey PRIMARY KEY (id);


--
-- Name: assignment_groups assignment_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_groups
    ADD CONSTRAINT assignment_groups_pkey PRIMARY KEY (id);


--
-- Name: assignment_override_students assignment_override_students_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_override_students
    ADD CONSTRAINT assignment_override_students_pkey PRIMARY KEY (id);


--
-- Name: assignment_overrides assignment_overrides_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_overrides
    ADD CONSTRAINT assignment_overrides_pkey PRIMARY KEY (id);


--
-- Name: assignments assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT assignments_pkey PRIMARY KEY (id);


--
-- Name: attachment_associations attachment_associations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attachment_associations
    ADD CONSTRAINT attachment_associations_pkey PRIMARY KEY (id);


--
-- Name: attachment_upload_statuses attachment_upload_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attachment_upload_statuses
    ADD CONSTRAINT attachment_upload_statuses_pkey PRIMARY KEY (id);


--
-- Name: attachments attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attachments
    ADD CONSTRAINT attachments_pkey PRIMARY KEY (id);


--
-- Name: aua_logs_0 aua_logs_0_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aua_logs_0
    ADD CONSTRAINT aua_logs_0_pkey PRIMARY KEY (id);


--
-- Name: aua_logs_1 aua_logs_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aua_logs_1
    ADD CONSTRAINT aua_logs_1_pkey PRIMARY KEY (id);


--
-- Name: aua_logs_2 aua_logs_2_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aua_logs_2
    ADD CONSTRAINT aua_logs_2_pkey PRIMARY KEY (id);


--
-- Name: aua_logs_3 aua_logs_3_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aua_logs_3
    ADD CONSTRAINT aua_logs_3_pkey PRIMARY KEY (id);


--
-- Name: aua_logs_4 aua_logs_4_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aua_logs_4
    ADD CONSTRAINT aua_logs_4_pkey PRIMARY KEY (id);


--
-- Name: aua_logs_5 aua_logs_5_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aua_logs_5
    ADD CONSTRAINT aua_logs_5_pkey PRIMARY KEY (id);


--
-- Name: aua_logs_6 aua_logs_6_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aua_logs_6
    ADD CONSTRAINT aua_logs_6_pkey PRIMARY KEY (id);


--
-- Name: auditor_authentication_records_2025_5 auditor_authentication_records_2025_5_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_authentication_records_2025_5
    ADD CONSTRAINT auditor_authentication_records_2025_5_pkey PRIMARY KEY (id);


--
-- Name: auditor_authentication_records_2025_6 auditor_authentication_records_2025_6_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_authentication_records_2025_6
    ADD CONSTRAINT auditor_authentication_records_2025_6_pkey PRIMARY KEY (id);


--
-- Name: auditor_authentication_records auditor_authentication_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_authentication_records
    ADD CONSTRAINT auditor_authentication_records_pkey PRIMARY KEY (id);


--
-- Name: auditor_course_records_2025_5 auditor_course_records_2025_5_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_course_records_2025_5
    ADD CONSTRAINT auditor_course_records_2025_5_pkey PRIMARY KEY (id);


--
-- Name: auditor_course_records_2025_6 auditor_course_records_2025_6_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_course_records_2025_6
    ADD CONSTRAINT auditor_course_records_2025_6_pkey PRIMARY KEY (id);


--
-- Name: auditor_course_records auditor_course_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_course_records
    ADD CONSTRAINT auditor_course_records_pkey PRIMARY KEY (id);


--
-- Name: auditor_feature_flag_records_2025_5 auditor_feature_flag_records_2025_5_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_feature_flag_records_2025_5
    ADD CONSTRAINT auditor_feature_flag_records_2025_5_pkey PRIMARY KEY (id);


--
-- Name: auditor_feature_flag_records_2025_6 auditor_feature_flag_records_2025_6_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_feature_flag_records_2025_6
    ADD CONSTRAINT auditor_feature_flag_records_2025_6_pkey PRIMARY KEY (id);


--
-- Name: auditor_feature_flag_records auditor_feature_flag_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_feature_flag_records
    ADD CONSTRAINT auditor_feature_flag_records_pkey PRIMARY KEY (id);


--
-- Name: auditor_grade_change_records_2025_5 auditor_grade_change_records_2025_5_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_grade_change_records_2025_5
    ADD CONSTRAINT auditor_grade_change_records_2025_5_pkey PRIMARY KEY (id);


--
-- Name: auditor_grade_change_records_2025_6 auditor_grade_change_records_2025_6_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_grade_change_records_2025_6
    ADD CONSTRAINT auditor_grade_change_records_2025_6_pkey PRIMARY KEY (id);


--
-- Name: auditor_grade_change_records auditor_grade_change_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_grade_change_records
    ADD CONSTRAINT auditor_grade_change_records_pkey PRIMARY KEY (id);


--
-- Name: auditor_pseudonym_records_2025_5 auditor_pseudonym_records_2025_5_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_pseudonym_records_2025_5
    ADD CONSTRAINT auditor_pseudonym_records_2025_5_pkey PRIMARY KEY (id);


--
-- Name: auditor_pseudonym_records_2025_6 auditor_pseudonym_records_2025_6_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_pseudonym_records_2025_6
    ADD CONSTRAINT auditor_pseudonym_records_2025_6_pkey PRIMARY KEY (id);


--
-- Name: auditor_pseudonym_records auditor_pseudonym_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_pseudonym_records
    ADD CONSTRAINT auditor_pseudonym_records_pkey PRIMARY KEY (id);


--
-- Name: authentication_providers authentication_providers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authentication_providers
    ADD CONSTRAINT authentication_providers_pkey PRIMARY KEY (id);


--
-- Name: blackout_dates blackout_dates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blackout_dates
    ADD CONSTRAINT blackout_dates_pkey PRIMARY KEY (id);


--
-- Name: block_editors block_editors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.block_editors
    ADD CONSTRAINT block_editors_pkey PRIMARY KEY (id);


--
-- Name: bookmarks_bookmarks bookmarks_bookmarks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookmarks_bookmarks
    ADD CONSTRAINT bookmarks_bookmarks_pkey PRIMARY KEY (id);


--
-- Name: brand_configs brand_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.brand_configs
    ADD CONSTRAINT brand_configs_pkey PRIMARY KEY (md5);


--
-- Name: calendar_events calendar_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendar_events
    ADD CONSTRAINT calendar_events_pkey PRIMARY KEY (id);


--
-- Name: canvadocs_annotation_contexts canvadocs_annotation_contexts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.canvadocs_annotation_contexts
    ADD CONSTRAINT canvadocs_annotation_contexts_pkey PRIMARY KEY (id);


--
-- Name: canvadocs canvadocs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.canvadocs
    ADD CONSTRAINT canvadocs_pkey PRIMARY KEY (id);


--
-- Name: canvadocs_submissions canvadocs_submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.canvadocs_submissions
    ADD CONSTRAINT canvadocs_submissions_pkey PRIMARY KEY (id);


--
-- Name: canvas_metadata canvas_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.canvas_metadata
    ADD CONSTRAINT canvas_metadata_pkey PRIMARY KEY (id);


--
-- Name: cloned_items cloned_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cloned_items
    ADD CONSTRAINT cloned_items_pkey PRIMARY KEY (id);


--
-- Name: collaborations collaborations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collaborations
    ADD CONSTRAINT collaborations_pkey PRIMARY KEY (id);


--
-- Name: collaborators collaborators_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collaborators
    ADD CONSTRAINT collaborators_pkey PRIMARY KEY (id);


--
-- Name: comment_bank_items comment_bank_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comment_bank_items
    ADD CONSTRAINT comment_bank_items_pkey PRIMARY KEY (id);


--
-- Name: communication_channels communication_channels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.communication_channels
    ADD CONSTRAINT communication_channels_pkey PRIMARY KEY (id);


--
-- Name: conditional_release_assignment_set_actions conditional_release_assignment_set_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conditional_release_assignment_set_actions
    ADD CONSTRAINT conditional_release_assignment_set_actions_pkey PRIMARY KEY (id);


--
-- Name: conditional_release_assignment_set_associations conditional_release_assignment_set_associations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conditional_release_assignment_set_associations
    ADD CONSTRAINT conditional_release_assignment_set_associations_pkey PRIMARY KEY (id);


--
-- Name: conditional_release_assignment_sets conditional_release_assignment_sets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conditional_release_assignment_sets
    ADD CONSTRAINT conditional_release_assignment_sets_pkey PRIMARY KEY (id);


--
-- Name: conditional_release_rules conditional_release_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conditional_release_rules
    ADD CONSTRAINT conditional_release_rules_pkey PRIMARY KEY (id);


--
-- Name: conditional_release_scoring_ranges conditional_release_scoring_ranges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conditional_release_scoring_ranges
    ADD CONSTRAINT conditional_release_scoring_ranges_pkey PRIMARY KEY (id);


--
-- Name: content_exports content_exports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_exports
    ADD CONSTRAINT content_exports_pkey PRIMARY KEY (id);


--
-- Name: content_migrations content_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_migrations
    ADD CONSTRAINT content_migrations_pkey PRIMARY KEY (id);


--
-- Name: content_participation_counts content_participation_counts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_participation_counts
    ADD CONSTRAINT content_participation_counts_pkey PRIMARY KEY (id);


--
-- Name: content_participations content_participations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_participations
    ADD CONSTRAINT content_participations_pkey PRIMARY KEY (id);


--
-- Name: content_shares content_shares_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_shares
    ADD CONSTRAINT content_shares_pkey PRIMARY KEY (id);


--
-- Name: content_tags content_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_tags
    ADD CONSTRAINT content_tags_pkey PRIMARY KEY (id);


--
-- Name: context_external_tool_placements context_external_tool_placements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.context_external_tool_placements
    ADD CONSTRAINT context_external_tool_placements_pkey PRIMARY KEY (id);


--
-- Name: context_external_tools context_external_tools_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.context_external_tools
    ADD CONSTRAINT context_external_tools_pkey PRIMARY KEY (id);


--
-- Name: context_module_progressions context_module_progressions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.context_module_progressions
    ADD CONSTRAINT context_module_progressions_pkey PRIMARY KEY (id);


--
-- Name: context_modules context_modules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.context_modules
    ADD CONSTRAINT context_modules_pkey PRIMARY KEY (id);


--
-- Name: conversation_batches conversation_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_batches
    ADD CONSTRAINT conversation_batches_pkey PRIMARY KEY (id);


--
-- Name: conversation_message_participants conversation_message_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_message_participants
    ADD CONSTRAINT conversation_message_participants_pkey PRIMARY KEY (id);


--
-- Name: conversation_messages conversation_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_messages
    ADD CONSTRAINT conversation_messages_pkey PRIMARY KEY (id);


--
-- Name: conversation_participants conversation_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_participants
    ADD CONSTRAINT conversation_participants_pkey PRIMARY KEY (id);


--
-- Name: conversations conversations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_pkey PRIMARY KEY (id);


--
-- Name: course_account_associations course_account_associations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_account_associations
    ADD CONSTRAINT course_account_associations_pkey PRIMARY KEY (id);


--
-- Name: course_pace_module_items course_pace_module_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_pace_module_items
    ADD CONSTRAINT course_pace_module_items_pkey PRIMARY KEY (id);


--
-- Name: course_paces course_paces_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_paces
    ADD CONSTRAINT course_paces_pkey PRIMARY KEY (id);


--
-- Name: course_score_statistics course_score_statistics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_score_statistics
    ADD CONSTRAINT course_score_statistics_pkey PRIMARY KEY (id);


--
-- Name: course_sections course_sections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_sections
    ADD CONSTRAINT course_sections_pkey PRIMARY KEY (id);


--
-- Name: courses courses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT courses_pkey PRIMARY KEY (id);


--
-- Name: crocodoc_documents crocodoc_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crocodoc_documents
    ADD CONSTRAINT crocodoc_documents_pkey PRIMARY KEY (id);


--
-- Name: csp_domains csp_domains_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.csp_domains
    ADD CONSTRAINT csp_domains_pkey PRIMARY KEY (id);


--
-- Name: custom_data custom_data_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_data
    ADD CONSTRAINT custom_data_pkey PRIMARY KEY (id);


--
-- Name: custom_grade_statuses custom_grade_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_grade_statuses
    ADD CONSTRAINT custom_grade_statuses_pkey PRIMARY KEY (id);


--
-- Name: custom_gradebook_column_data custom_gradebook_column_data_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_gradebook_column_data
    ADD CONSTRAINT custom_gradebook_column_data_pkey PRIMARY KEY (id);


--
-- Name: custom_gradebook_columns custom_gradebook_columns_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_gradebook_columns
    ADD CONSTRAINT custom_gradebook_columns_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs delayed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_jobs
    ADD CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id);


--
-- Name: delayed_messages delayed_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_messages
    ADD CONSTRAINT delayed_messages_pkey PRIMARY KEY (id);


--
-- Name: delayed_notifications delayed_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_notifications
    ADD CONSTRAINT delayed_notifications_pkey PRIMARY KEY (id);


--
-- Name: developer_key_account_bindings developer_key_account_bindings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.developer_key_account_bindings
    ADD CONSTRAINT developer_key_account_bindings_pkey PRIMARY KEY (id);


--
-- Name: developer_keys developer_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.developer_keys
    ADD CONSTRAINT developer_keys_pkey PRIMARY KEY (id);


--
-- Name: discussion_entries discussion_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_entries
    ADD CONSTRAINT discussion_entries_pkey PRIMARY KEY (id);


--
-- Name: discussion_entry_drafts discussion_entry_drafts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_entry_drafts
    ADD CONSTRAINT discussion_entry_drafts_pkey PRIMARY KEY (id);


--
-- Name: discussion_entry_participants discussion_entry_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_entry_participants
    ADD CONSTRAINT discussion_entry_participants_pkey PRIMARY KEY (id);


--
-- Name: discussion_entry_versions discussion_entry_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_entry_versions
    ADD CONSTRAINT discussion_entry_versions_pkey PRIMARY KEY (id);


--
-- Name: discussion_topic_materialized_views discussion_topic_materialized_views_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_topic_materialized_views
    ADD CONSTRAINT discussion_topic_materialized_views_pkey PRIMARY KEY (discussion_topic_id);


--
-- Name: discussion_topic_participants discussion_topic_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_topic_participants
    ADD CONSTRAINT discussion_topic_participants_pkey PRIMARY KEY (id);


--
-- Name: discussion_topic_section_visibilities discussion_topic_section_visibilities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_topic_section_visibilities
    ADD CONSTRAINT discussion_topic_section_visibilities_pkey PRIMARY KEY (id);


--
-- Name: discussion_topics discussion_topics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_topics
    ADD CONSTRAINT discussion_topics_pkey PRIMARY KEY (id);


--
-- Name: enrollment_dates_overrides enrollment_dates_overrides_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enrollment_dates_overrides
    ADD CONSTRAINT enrollment_dates_overrides_pkey PRIMARY KEY (id);


--
-- Name: enrollment_states enrollment_states_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enrollment_states
    ADD CONSTRAINT enrollment_states_pkey PRIMARY KEY (enrollment_id);


--
-- Name: enrollment_terms enrollment_terms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enrollment_terms
    ADD CONSTRAINT enrollment_terms_pkey PRIMARY KEY (id);


--
-- Name: enrollments enrollments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enrollments
    ADD CONSTRAINT enrollments_pkey PRIMARY KEY (id);


--
-- Name: eportfolio_categories eportfolio_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eportfolio_categories
    ADD CONSTRAINT eportfolio_categories_pkey PRIMARY KEY (id);


--
-- Name: eportfolio_entries eportfolio_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eportfolio_entries
    ADD CONSTRAINT eportfolio_entries_pkey PRIMARY KEY (id);


--
-- Name: eportfolios eportfolios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eportfolios
    ADD CONSTRAINT eportfolios_pkey PRIMARY KEY (id);


--
-- Name: epub_exports epub_exports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.epub_exports
    ADD CONSTRAINT epub_exports_pkey PRIMARY KEY (id);


--
-- Name: error_reports error_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.error_reports
    ADD CONSTRAINT error_reports_pkey PRIMARY KEY (id);


--
-- Name: event_stream_failures event_stream_failures_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_stream_failures
    ADD CONSTRAINT event_stream_failures_pkey PRIMARY KEY (id);


--
-- Name: external_feed_entries external_feed_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_feed_entries
    ADD CONSTRAINT external_feed_entries_pkey PRIMARY KEY (id);


--
-- Name: external_feeds external_feeds_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_feeds
    ADD CONSTRAINT external_feeds_pkey PRIMARY KEY (id);


--
-- Name: external_integration_keys external_integration_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_integration_keys
    ADD CONSTRAINT external_integration_keys_pkey PRIMARY KEY (id);


--
-- Name: failed_jobs failed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.failed_jobs
    ADD CONSTRAINT failed_jobs_pkey PRIMARY KEY (id);


--
-- Name: favorites favorites_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.favorites
    ADD CONSTRAINT favorites_pkey PRIMARY KEY (id);


--
-- Name: feature_flags feature_flags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feature_flags
    ADD CONSTRAINT feature_flags_pkey PRIMARY KEY (id);


--
-- Name: folders folders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.folders
    ADD CONSTRAINT folders_pkey PRIMARY KEY (id);


--
-- Name: gradebook_csvs gradebook_csvs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gradebook_csvs
    ADD CONSTRAINT gradebook_csvs_pkey PRIMARY KEY (id);


--
-- Name: gradebook_filters gradebook_filters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gradebook_filters
    ADD CONSTRAINT gradebook_filters_pkey PRIMARY KEY (id);


--
-- Name: gradebook_uploads gradebook_uploads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gradebook_uploads
    ADD CONSTRAINT gradebook_uploads_pkey PRIMARY KEY (id);


--
-- Name: grading_period_groups grading_period_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grading_period_groups
    ADD CONSTRAINT grading_period_groups_pkey PRIMARY KEY (id);


--
-- Name: grading_periods grading_periods_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grading_periods
    ADD CONSTRAINT grading_periods_pkey PRIMARY KEY (id);


--
-- Name: grading_standards grading_standards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grading_standards
    ADD CONSTRAINT grading_standards_pkey PRIMARY KEY (id);


--
-- Name: group_and_membership_importers group_and_membership_importers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_and_membership_importers
    ADD CONSTRAINT group_and_membership_importers_pkey PRIMARY KEY (id);


--
-- Name: group_categories group_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_categories
    ADD CONSTRAINT group_categories_pkey PRIMARY KEY (id);


--
-- Name: group_memberships group_memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_memberships
    ADD CONSTRAINT group_memberships_pkey PRIMARY KEY (id);


--
-- Name: groups groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (id);


--
-- Name: ignores ignores_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ignores
    ADD CONSTRAINT ignores_pkey PRIMARY KEY (id);


--
-- Name: late_policies late_policies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.late_policies
    ADD CONSTRAINT late_policies_pkey PRIMARY KEY (id);


--
-- Name: learning_outcome_groups learning_outcome_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.learning_outcome_groups
    ADD CONSTRAINT learning_outcome_groups_pkey PRIMARY KEY (id);


--
-- Name: learning_outcome_question_results learning_outcome_question_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.learning_outcome_question_results
    ADD CONSTRAINT learning_outcome_question_results_pkey PRIMARY KEY (id);


--
-- Name: learning_outcome_results learning_outcome_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.learning_outcome_results
    ADD CONSTRAINT learning_outcome_results_pkey PRIMARY KEY (id);


--
-- Name: learning_outcomes learning_outcomes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.learning_outcomes
    ADD CONSTRAINT learning_outcomes_pkey PRIMARY KEY (id);


--
-- Name: live_assessments_assessments live_assessments_assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.live_assessments_assessments
    ADD CONSTRAINT live_assessments_assessments_pkey PRIMARY KEY (id);


--
-- Name: live_assessments_results live_assessments_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.live_assessments_results
    ADD CONSTRAINT live_assessments_results_pkey PRIMARY KEY (id);


--
-- Name: live_assessments_submissions live_assessments_submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.live_assessments_submissions
    ADD CONSTRAINT live_assessments_submissions_pkey PRIMARY KEY (id);


--
-- Name: lti_ims_registrations lti_ims_registrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_ims_registrations
    ADD CONSTRAINT lti_ims_registrations_pkey PRIMARY KEY (id);


--
-- Name: lti_line_items lti_line_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_line_items
    ADD CONSTRAINT lti_line_items_pkey PRIMARY KEY (id);


--
-- Name: lti_links lti_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_links
    ADD CONSTRAINT lti_links_pkey PRIMARY KEY (id);


--
-- Name: lti_message_handlers lti_message_handlers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_message_handlers
    ADD CONSTRAINT lti_message_handlers_pkey PRIMARY KEY (id);


--
-- Name: lti_product_families lti_product_families_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_product_families
    ADD CONSTRAINT lti_product_families_pkey PRIMARY KEY (id);


--
-- Name: lti_resource_handlers lti_resource_handlers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_resource_handlers
    ADD CONSTRAINT lti_resource_handlers_pkey PRIMARY KEY (id);


--
-- Name: lti_resource_links lti_resource_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_resource_links
    ADD CONSTRAINT lti_resource_links_pkey PRIMARY KEY (id);


--
-- Name: lti_resource_placements lti_resource_placements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_resource_placements
    ADD CONSTRAINT lti_resource_placements_pkey PRIMARY KEY (id);


--
-- Name: lti_results lti_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_results
    ADD CONSTRAINT lti_results_pkey PRIMARY KEY (id);


--
-- Name: lti_tool_configurations lti_tool_configurations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_tool_configurations
    ADD CONSTRAINT lti_tool_configurations_pkey PRIMARY KEY (id);


--
-- Name: lti_tool_consumer_profiles lti_tool_consumer_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_tool_consumer_profiles
    ADD CONSTRAINT lti_tool_consumer_profiles_pkey PRIMARY KEY (id);


--
-- Name: lti_tool_proxies lti_tool_proxies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_tool_proxies
    ADD CONSTRAINT lti_tool_proxies_pkey PRIMARY KEY (id);


--
-- Name: lti_tool_proxy_bindings lti_tool_proxy_bindings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_tool_proxy_bindings
    ADD CONSTRAINT lti_tool_proxy_bindings_pkey PRIMARY KEY (id);


--
-- Name: lti_tool_settings lti_tool_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_tool_settings
    ADD CONSTRAINT lti_tool_settings_pkey PRIMARY KEY (id);


--
-- Name: master_courses_child_content_tags master_courses_child_content_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.master_courses_child_content_tags
    ADD CONSTRAINT master_courses_child_content_tags_pkey PRIMARY KEY (id);


--
-- Name: master_courses_child_subscriptions master_courses_child_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.master_courses_child_subscriptions
    ADD CONSTRAINT master_courses_child_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: master_courses_master_content_tags master_courses_master_content_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.master_courses_master_content_tags
    ADD CONSTRAINT master_courses_master_content_tags_pkey PRIMARY KEY (id);


--
-- Name: master_courses_master_migrations master_courses_master_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.master_courses_master_migrations
    ADD CONSTRAINT master_courses_master_migrations_pkey PRIMARY KEY (id);


--
-- Name: master_courses_master_templates master_courses_master_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.master_courses_master_templates
    ADD CONSTRAINT master_courses_master_templates_pkey PRIMARY KEY (id);


--
-- Name: master_courses_migration_results master_courses_migration_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.master_courses_migration_results
    ADD CONSTRAINT master_courses_migration_results_pkey PRIMARY KEY (id);


--
-- Name: media_objects media_objects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media_objects
    ADD CONSTRAINT media_objects_pkey PRIMARY KEY (id);


--
-- Name: media_tracks media_tracks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media_tracks
    ADD CONSTRAINT media_tracks_pkey PRIMARY KEY (id);


--
-- Name: mentions mentions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mentions
    ADD CONSTRAINT mentions_pkey PRIMARY KEY (id);


--
-- Name: messages_2025_18 messages_2025_18_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages_2025_18
    ADD CONSTRAINT messages_2025_18_pkey PRIMARY KEY (id);


--
-- Name: messages_2025_19 messages_2025_19_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages_2025_19
    ADD CONSTRAINT messages_2025_19_pkey PRIMARY KEY (id);


--
-- Name: messages_2025_20 messages_2025_20_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages_2025_20
    ADD CONSTRAINT messages_2025_20_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: microsoft_sync_groups microsoft_sync_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.microsoft_sync_groups
    ADD CONSTRAINT microsoft_sync_groups_pkey PRIMARY KEY (id);


--
-- Name: microsoft_sync_partial_sync_changes microsoft_sync_partial_sync_changes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.microsoft_sync_partial_sync_changes
    ADD CONSTRAINT microsoft_sync_partial_sync_changes_pkey PRIMARY KEY (id);


--
-- Name: microsoft_sync_user_mappings microsoft_sync_user_mappings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.microsoft_sync_user_mappings
    ADD CONSTRAINT microsoft_sync_user_mappings_pkey PRIMARY KEY (id);


--
-- Name: migration_issues migration_issues_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.migration_issues
    ADD CONSTRAINT migration_issues_pkey PRIMARY KEY (id);


--
-- Name: moderated_grading_provisional_grades moderated_grading_provisional_grades_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.moderated_grading_provisional_grades
    ADD CONSTRAINT moderated_grading_provisional_grades_pkey PRIMARY KEY (id);


--
-- Name: moderated_grading_selections moderated_grading_selections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.moderated_grading_selections
    ADD CONSTRAINT moderated_grading_selections_pkey PRIMARY KEY (id);


--
-- Name: moderation_graders moderation_graders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.moderation_graders
    ADD CONSTRAINT moderation_graders_pkey PRIMARY KEY (id);


--
-- Name: notification_endpoints notification_endpoints_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_endpoints
    ADD CONSTRAINT notification_endpoints_pkey PRIMARY KEY (id);


--
-- Name: notification_policies notification_policies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_policies
    ADD CONSTRAINT notification_policies_pkey PRIMARY KEY (id);


--
-- Name: notification_policy_overrides notification_policy_overrides_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_policy_overrides
    ADD CONSTRAINT notification_policy_overrides_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: oauth_requests oauth_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_requests
    ADD CONSTRAINT oauth_requests_pkey PRIMARY KEY (id);


--
-- Name: observer_alert_thresholds observer_alert_thresholds_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.observer_alert_thresholds
    ADD CONSTRAINT observer_alert_thresholds_pkey PRIMARY KEY (id);


--
-- Name: observer_alerts observer_alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.observer_alerts
    ADD CONSTRAINT observer_alerts_pkey PRIMARY KEY (id);


--
-- Name: observer_pairing_codes observer_pairing_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.observer_pairing_codes
    ADD CONSTRAINT observer_pairing_codes_pkey PRIMARY KEY (id);


--
-- Name: one_time_passwords one_time_passwords_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.one_time_passwords
    ADD CONSTRAINT one_time_passwords_pkey PRIMARY KEY (id);


--
-- Name: originality_reports originality_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.originality_reports
    ADD CONSTRAINT originality_reports_pkey PRIMARY KEY (id);


--
-- Name: outcome_calculation_methods outcome_calculation_methods_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outcome_calculation_methods
    ADD CONSTRAINT outcome_calculation_methods_pkey PRIMARY KEY (id);


--
-- Name: outcome_friendly_descriptions outcome_friendly_descriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outcome_friendly_descriptions
    ADD CONSTRAINT outcome_friendly_descriptions_pkey PRIMARY KEY (id);


--
-- Name: outcome_import_errors outcome_import_errors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outcome_import_errors
    ADD CONSTRAINT outcome_import_errors_pkey PRIMARY KEY (id);


--
-- Name: outcome_imports outcome_imports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outcome_imports
    ADD CONSTRAINT outcome_imports_pkey PRIMARY KEY (id);


--
-- Name: outcome_proficiencies outcome_proficiencies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outcome_proficiencies
    ADD CONSTRAINT outcome_proficiencies_pkey PRIMARY KEY (id);


--
-- Name: outcome_proficiency_ratings outcome_proficiency_ratings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outcome_proficiency_ratings
    ADD CONSTRAINT outcome_proficiency_ratings_pkey PRIMARY KEY (id);


--
-- Name: page_comments page_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.page_comments
    ADD CONSTRAINT page_comments_pkey PRIMARY KEY (id);


--
-- Name: page_views page_views_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.page_views
    ADD CONSTRAINT page_views_pkey PRIMARY KEY (request_id);


--
-- Name: parallel_importers parallel_importers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parallel_importers
    ADD CONSTRAINT parallel_importers_pkey PRIMARY KEY (id);


--
-- Name: planner_notes planner_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planner_notes
    ADD CONSTRAINT planner_notes_pkey PRIMARY KEY (id);


--
-- Name: planner_overrides planner_overrides_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planner_overrides
    ADD CONSTRAINT planner_overrides_pkey PRIMARY KEY (id);


--
-- Name: plugin_settings plugin_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plugin_settings
    ADD CONSTRAINT plugin_settings_pkey PRIMARY KEY (id);


--
-- Name: polling_poll_choices polling_poll_choices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.polling_poll_choices
    ADD CONSTRAINT polling_poll_choices_pkey PRIMARY KEY (id);


--
-- Name: polling_poll_sessions polling_poll_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.polling_poll_sessions
    ADD CONSTRAINT polling_poll_sessions_pkey PRIMARY KEY (id);


--
-- Name: polling_poll_submissions polling_poll_submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.polling_poll_submissions
    ADD CONSTRAINT polling_poll_submissions_pkey PRIMARY KEY (id);


--
-- Name: polling_polls polling_polls_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.polling_polls
    ADD CONSTRAINT polling_polls_pkey PRIMARY KEY (id);


--
-- Name: post_policies post_policies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_policies
    ADD CONSTRAINT post_policies_pkey PRIMARY KEY (id);


--
-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);


--
-- Name: progresses progresses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.progresses
    ADD CONSTRAINT progresses_pkey PRIMARY KEY (id);


--
-- Name: pseudonyms pseudonyms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pseudonyms
    ADD CONSTRAINT pseudonyms_pkey PRIMARY KEY (id);


--
-- Name: purgatories purgatories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purgatories
    ADD CONSTRAINT purgatories_pkey PRIMARY KEY (id);


--
-- Name: quiz_groups quiz_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_groups
    ADD CONSTRAINT quiz_groups_pkey PRIMARY KEY (id);


--
-- Name: quiz_migration_alerts quiz_migration_alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_migration_alerts
    ADD CONSTRAINT quiz_migration_alerts_pkey PRIMARY KEY (id);


--
-- Name: quiz_question_regrades quiz_question_regrades_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_question_regrades
    ADD CONSTRAINT quiz_question_regrades_pkey PRIMARY KEY (id);


--
-- Name: quiz_questions quiz_questions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_questions
    ADD CONSTRAINT quiz_questions_pkey PRIMARY KEY (id);


--
-- Name: quiz_regrade_runs quiz_regrade_runs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_regrade_runs
    ADD CONSTRAINT quiz_regrade_runs_pkey PRIMARY KEY (id);


--
-- Name: quiz_regrades quiz_regrades_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_regrades
    ADD CONSTRAINT quiz_regrades_pkey PRIMARY KEY (id);


--
-- Name: quiz_statistics quiz_statistics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_statistics
    ADD CONSTRAINT quiz_statistics_pkey PRIMARY KEY (id);


--
-- Name: quiz_submission_events_2025_5 quiz_submission_events_2025_5_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_submission_events_2025_5
    ADD CONSTRAINT quiz_submission_events_2025_5_pkey PRIMARY KEY (id);


--
-- Name: quiz_submission_events_2025_6 quiz_submission_events_2025_6_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_submission_events_2025_6
    ADD CONSTRAINT quiz_submission_events_2025_6_pkey PRIMARY KEY (id);


--
-- Name: quiz_submission_events_2025_7 quiz_submission_events_2025_7_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_submission_events_2025_7
    ADD CONSTRAINT quiz_submission_events_2025_7_pkey PRIMARY KEY (id);


--
-- Name: quiz_submission_events quiz_submission_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_submission_events
    ADD CONSTRAINT quiz_submission_events_pkey PRIMARY KEY (id);


--
-- Name: quiz_submission_snapshots quiz_submission_snapshots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_submission_snapshots
    ADD CONSTRAINT quiz_submission_snapshots_pkey PRIMARY KEY (id);


--
-- Name: quiz_submissions quiz_submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_submissions
    ADD CONSTRAINT quiz_submissions_pkey PRIMARY KEY (id);


--
-- Name: quizzes quizzes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quizzes
    ADD CONSTRAINT quizzes_pkey PRIMARY KEY (id);


--
-- Name: report_snapshots report_snapshots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_snapshots
    ADD CONSTRAINT report_snapshots_pkey PRIMARY KEY (id);


--
-- Name: role_overrides role_overrides_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_overrides
    ADD CONSTRAINT role_overrides_pkey PRIMARY KEY (id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: rubric_assessments rubric_assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rubric_assessments
    ADD CONSTRAINT rubric_assessments_pkey PRIMARY KEY (id);


--
-- Name: rubric_associations rubric_associations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rubric_associations
    ADD CONSTRAINT rubric_associations_pkey PRIMARY KEY (id);


--
-- Name: rubric_criteria rubric_criteria_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rubric_criteria
    ADD CONSTRAINT rubric_criteria_pkey PRIMARY KEY (id);


--
-- Name: rubrics rubrics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rubrics
    ADD CONSTRAINT rubrics_pkey PRIMARY KEY (id);


--
-- Name: scheduled_smart_alerts scheduled_smart_alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scheduled_smart_alerts
    ADD CONSTRAINT scheduled_smart_alerts_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: score_metadata score_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.score_metadata
    ADD CONSTRAINT score_metadata_pkey PRIMARY KEY (id);


--
-- Name: score_statistics score_statistics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.score_statistics
    ADD CONSTRAINT score_statistics_pkey PRIMARY KEY (id);


--
-- Name: scores scores_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scores
    ADD CONSTRAINT scores_pkey PRIMARY KEY (id);


--
-- Name: session_persistence_tokens session_persistence_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session_persistence_tokens
    ADD CONSTRAINT session_persistence_tokens_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: settings settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT settings_pkey PRIMARY KEY (id);


--
-- Name: shared_brand_configs shared_brand_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shared_brand_configs
    ADD CONSTRAINT shared_brand_configs_pkey PRIMARY KEY (id);


--
-- Name: sis_batch_errors sis_batch_errors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sis_batch_errors
    ADD CONSTRAINT sis_batch_errors_pkey PRIMARY KEY (id);


--
-- Name: sis_batch_roll_back_data sis_batch_roll_back_data_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sis_batch_roll_back_data
    ADD CONSTRAINT sis_batch_roll_back_data_pkey PRIMARY KEY (id);


--
-- Name: sis_batches sis_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sis_batches
    ADD CONSTRAINT sis_batches_pkey PRIMARY KEY (id);


--
-- Name: sis_post_grades_statuses sis_post_grades_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sis_post_grades_statuses
    ADD CONSTRAINT sis_post_grades_statuses_pkey PRIMARY KEY (id);


--
-- Name: standard_grade_statuses standard_grade_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.standard_grade_statuses
    ADD CONSTRAINT standard_grade_statuses_pkey PRIMARY KEY (id);


--
-- Name: stream_item_instances stream_item_instances_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stream_item_instances
    ADD CONSTRAINT stream_item_instances_pkey PRIMARY KEY (id);


--
-- Name: stream_items stream_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stream_items
    ADD CONSTRAINT stream_items_pkey PRIMARY KEY (id);


--
-- Name: submission_comments submission_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submission_comments
    ADD CONSTRAINT submission_comments_pkey PRIMARY KEY (id);


--
-- Name: submission_draft_attachments submission_draft_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submission_draft_attachments
    ADD CONSTRAINT submission_draft_attachments_pkey PRIMARY KEY (id);


--
-- Name: submission_drafts submission_drafts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submission_drafts
    ADD CONSTRAINT submission_drafts_pkey PRIMARY KEY (id);


--
-- Name: submission_versions submission_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submission_versions
    ADD CONSTRAINT submission_versions_pkey PRIMARY KEY (id);


--
-- Name: submissions submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submissions
    ADD CONSTRAINT submissions_pkey PRIMARY KEY (id);


--
-- Name: switchman_shards switchman_shards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.switchman_shards
    ADD CONSTRAINT switchman_shards_pkey PRIMARY KEY (id);


--
-- Name: temporary_enrollment_pairings temporary_enrollment_pairings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.temporary_enrollment_pairings
    ADD CONSTRAINT temporary_enrollment_pairings_pkey PRIMARY KEY (id);


--
-- Name: terms_of_service_contents terms_of_service_contents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.terms_of_service_contents
    ADD CONSTRAINT terms_of_service_contents_pkey PRIMARY KEY (id);


--
-- Name: terms_of_services terms_of_services_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.terms_of_services
    ADD CONSTRAINT terms_of_services_pkey PRIMARY KEY (id);


--
-- Name: thumbnails thumbnails_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.thumbnails
    ADD CONSTRAINT thumbnails_pkey PRIMARY KEY (id);


--
-- Name: usage_rights usage_rights_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usage_rights
    ADD CONSTRAINT usage_rights_pkey PRIMARY KEY (id);


--
-- Name: user_account_associations user_account_associations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_account_associations
    ADD CONSTRAINT user_account_associations_pkey PRIMARY KEY (id);


--
-- Name: user_lmgb_outcome_orderings user_lmgb_outcome_orderings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_lmgb_outcome_orderings
    ADD CONSTRAINT user_lmgb_outcome_orderings_pkey PRIMARY KEY (id);


--
-- Name: user_merge_data_items user_merge_data_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_merge_data_items
    ADD CONSTRAINT user_merge_data_items_pkey PRIMARY KEY (id);


--
-- Name: user_merge_data user_merge_data_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_merge_data
    ADD CONSTRAINT user_merge_data_pkey PRIMARY KEY (id);


--
-- Name: user_merge_data_records user_merge_data_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_merge_data_records
    ADD CONSTRAINT user_merge_data_records_pkey PRIMARY KEY (id);


--
-- Name: user_notes user_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_notes
    ADD CONSTRAINT user_notes_pkey PRIMARY KEY (id);


--
-- Name: user_observers user_observers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_observers
    ADD CONSTRAINT user_observers_pkey PRIMARY KEY (id);


--
-- Name: user_past_lti_ids user_past_lti_ids_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_past_lti_ids
    ADD CONSTRAINT user_past_lti_ids_pkey PRIMARY KEY (id);


--
-- Name: user_preference_values user_preference_values_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_preference_values
    ADD CONSTRAINT user_preference_values_pkey PRIMARY KEY (id);


--
-- Name: user_profile_links user_profile_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_profile_links
    ADD CONSTRAINT user_profile_links_pkey PRIMARY KEY (id);


--
-- Name: user_profiles user_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_profiles
    ADD CONSTRAINT user_profiles_pkey PRIMARY KEY (id);


--
-- Name: user_services user_services_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_services
    ADD CONSTRAINT user_services_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: versions_0 versions_0_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions_0
    ADD CONSTRAINT versions_0_pkey PRIMARY KEY (id);


--
-- Name: versions_1 versions_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions_1
    ADD CONSTRAINT versions_1_pkey PRIMARY KEY (id);


--
-- Name: versions versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (id);


--
-- Name: viewed_submission_comments viewed_submission_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.viewed_submission_comments
    ADD CONSTRAINT viewed_submission_comments_pkey PRIMARY KEY (id);


--
-- Name: web_conference_participants web_conference_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.web_conference_participants
    ADD CONSTRAINT web_conference_participants_pkey PRIMARY KEY (id);


--
-- Name: web_conferences web_conferences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.web_conferences
    ADD CONSTRAINT web_conferences_pkey PRIMARY KEY (id);


--
-- Name: wiki_page_lookups wiki_page_lookups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wiki_page_lookups
    ADD CONSTRAINT wiki_page_lookups_pkey PRIMARY KEY (id);


--
-- Name: wiki_pages wiki_pages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wiki_pages
    ADD CONSTRAINT wiki_pages_pkey PRIMARY KEY (id);


--
-- Name: wikis wikis_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wikis
    ADD CONSTRAINT wikis_pkey PRIMARY KEY (id);


--
-- Name: aa_id_and_aa_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX aa_id_and_aa_type ON public.assessment_requests USING btree (assessor_asset_id, assessor_asset_type);


--
-- Name: assessment_qbu_aqb_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX assessment_qbu_aqb_id ON public.assessment_question_bank_users USING btree (assessment_question_bank_id);


--
-- Name: assessment_qbu_u_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX assessment_qbu_u_id ON public.assessment_question_bank_users USING btree (user_id);


--
-- Name: attachment_associations_a_id_a_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX attachment_associations_a_id_a_type ON public.attachment_associations USING btree (context_id, context_type);


--
-- Name: auditor_authentication_records_2025_5_account_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_authentication_records_2025_5_account_id_idx ON public.auditor_authentication_records_2025_5 USING btree (account_id);


--
-- Name: auditor_authentication_records_2025_5_pseudonym_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_authentication_records_2025_5_pseudonym_id_idx ON public.auditor_authentication_records_2025_5 USING btree (pseudonym_id);


--
-- Name: auditor_authentication_records_2025_5_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_authentication_records_2025_5_user_id_idx ON public.auditor_authentication_records_2025_5 USING btree (user_id);


--
-- Name: auditor_authentication_records_2025_5_uuid_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX auditor_authentication_records_2025_5_uuid_idx ON public.auditor_authentication_records_2025_5 USING btree (uuid);


--
-- Name: auditor_authentication_records_2025_6_account_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_authentication_records_2025_6_account_id_idx ON public.auditor_authentication_records_2025_6 USING btree (account_id);


--
-- Name: auditor_authentication_records_2025_6_pseudonym_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_authentication_records_2025_6_pseudonym_id_idx ON public.auditor_authentication_records_2025_6 USING btree (pseudonym_id);


--
-- Name: auditor_authentication_records_2025_6_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_authentication_records_2025_6_user_id_idx ON public.auditor_authentication_records_2025_6 USING btree (user_id);


--
-- Name: auditor_authentication_records_2025_6_uuid_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX auditor_authentication_records_2025_6_uuid_idx ON public.auditor_authentication_records_2025_6 USING btree (uuid);


--
-- Name: auditor_course_records_2025_5_account_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_course_records_2025_5_account_id_idx ON public.auditor_course_records_2025_5 USING btree (account_id);


--
-- Name: auditor_course_records_2025_5_course_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_course_records_2025_5_course_id_idx ON public.auditor_course_records_2025_5 USING btree (course_id);


--
-- Name: auditor_course_records_2025_5_sis_batch_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_course_records_2025_5_sis_batch_id_idx ON public.auditor_course_records_2025_5 USING btree (sis_batch_id);


--
-- Name: auditor_course_records_2025_5_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_course_records_2025_5_user_id_idx ON public.auditor_course_records_2025_5 USING btree (user_id);


--
-- Name: auditor_course_records_2025_5_uuid_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX auditor_course_records_2025_5_uuid_idx ON public.auditor_course_records_2025_5 USING btree (uuid);


--
-- Name: auditor_course_records_2025_6_account_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_course_records_2025_6_account_id_idx ON public.auditor_course_records_2025_6 USING btree (account_id);


--
-- Name: auditor_course_records_2025_6_course_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_course_records_2025_6_course_id_idx ON public.auditor_course_records_2025_6 USING btree (course_id);


--
-- Name: auditor_course_records_2025_6_sis_batch_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_course_records_2025_6_sis_batch_id_idx ON public.auditor_course_records_2025_6 USING btree (sis_batch_id);


--
-- Name: auditor_course_records_2025_6_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_course_records_2025_6_user_id_idx ON public.auditor_course_records_2025_6 USING btree (user_id);


--
-- Name: auditor_course_records_2025_6_uuid_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX auditor_course_records_2025_6_uuid_idx ON public.auditor_course_records_2025_6 USING btree (uuid);


--
-- Name: auditor_feature_flag_records_2025_5_feature_flag_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_feature_flag_records_2025_5_feature_flag_id_idx ON public.auditor_feature_flag_records_2025_5 USING btree (feature_flag_id);


--
-- Name: auditor_feature_flag_records_2025_5_root_account_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_feature_flag_records_2025_5_root_account_id_idx ON public.auditor_feature_flag_records_2025_5 USING btree (root_account_id);


--
-- Name: auditor_feature_flag_records_2025_5_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_feature_flag_records_2025_5_user_id_idx ON public.auditor_feature_flag_records_2025_5 USING btree (user_id);


--
-- Name: auditor_feature_flag_records_2025_5_uuid_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_feature_flag_records_2025_5_uuid_idx ON public.auditor_feature_flag_records_2025_5 USING btree (uuid);


--
-- Name: auditor_feature_flag_records_2025_6_feature_flag_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_feature_flag_records_2025_6_feature_flag_id_idx ON public.auditor_feature_flag_records_2025_6 USING btree (feature_flag_id);


--
-- Name: auditor_feature_flag_records_2025_6_root_account_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_feature_flag_records_2025_6_root_account_id_idx ON public.auditor_feature_flag_records_2025_6 USING btree (root_account_id);


--
-- Name: auditor_feature_flag_records_2025_6_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_feature_flag_records_2025_6_user_id_idx ON public.auditor_feature_flag_records_2025_6 USING btree (user_id);


--
-- Name: auditor_feature_flag_records_2025_6_uuid_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_feature_flag_records_2025_6_uuid_idx ON public.auditor_feature_flag_records_2025_6 USING btree (uuid);


--
-- Name: auditor_grade_change_records_2025_5_account_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_grade_change_records_2025_5_account_id_idx ON public.auditor_grade_change_records_2025_5 USING btree (account_id);


--
-- Name: auditor_grade_change_records_2025_5_assignment_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_grade_change_records_2025_5_assignment_id_idx ON public.auditor_grade_change_records_2025_5 USING btree (assignment_id);


--
-- Name: auditor_grade_change_records_2025_5_grader_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_grade_change_records_2025_5_grader_id_idx ON public.auditor_grade_change_records_2025_5 USING btree (grader_id);


--
-- Name: auditor_grade_change_records_2025_5_grading_period_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_grade_change_records_2025_5_grading_period_id_idx ON public.auditor_grade_change_records_2025_5 USING btree (grading_period_id) WHERE (grading_period_id IS NOT NULL);


--
-- Name: auditor_grade_change_records_2025_5_student_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_grade_change_records_2025_5_student_id_idx ON public.auditor_grade_change_records_2025_5 USING btree (student_id);


--
-- Name: auditor_grade_change_records_2025_5_submission_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_grade_change_records_2025_5_submission_id_idx ON public.auditor_grade_change_records_2025_5 USING btree (submission_id);


--
-- Name: auditor_grade_change_records_2025_5_uuid_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX auditor_grade_change_records_2025_5_uuid_idx ON public.auditor_grade_change_records_2025_5 USING btree (uuid);


--
-- Name: auditor_grade_change_records_2025_6_account_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_grade_change_records_2025_6_account_id_idx ON public.auditor_grade_change_records_2025_6 USING btree (account_id);


--
-- Name: auditor_grade_change_records_2025_6_assignment_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_grade_change_records_2025_6_assignment_id_idx ON public.auditor_grade_change_records_2025_6 USING btree (assignment_id);


--
-- Name: auditor_grade_change_records_2025_6_grader_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_grade_change_records_2025_6_grader_id_idx ON public.auditor_grade_change_records_2025_6 USING btree (grader_id);


--
-- Name: auditor_grade_change_records_2025_6_grading_period_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_grade_change_records_2025_6_grading_period_id_idx ON public.auditor_grade_change_records_2025_6 USING btree (grading_period_id) WHERE (grading_period_id IS NOT NULL);


--
-- Name: auditor_grade_change_records_2025_6_student_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_grade_change_records_2025_6_student_id_idx ON public.auditor_grade_change_records_2025_6 USING btree (student_id);


--
-- Name: auditor_grade_change_records_2025_6_submission_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_grade_change_records_2025_6_submission_id_idx ON public.auditor_grade_change_records_2025_6 USING btree (submission_id);


--
-- Name: auditor_grade_change_records_2025_6_uuid_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX auditor_grade_change_records_2025_6_uuid_idx ON public.auditor_grade_change_records_2025_6 USING btree (uuid);


--
-- Name: auditor_grade_change_records_2025_root_account_id_grader_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_grade_change_records_2025_root_account_id_grader_id_idx ON public.auditor_grade_change_records_2025_5 USING btree (root_account_id, grader_id);


--
-- Name: auditor_grade_change_records_202_root_account_id_grader_id_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_grade_change_records_202_root_account_id_grader_id_idx1 ON public.auditor_grade_change_records_2025_6 USING btree (root_account_id, grader_id);


--
-- Name: auditor_grade_change_records_202_root_account_id_student_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_grade_change_records_202_root_account_id_student_id_idx ON public.auditor_grade_change_records_2025_5 USING btree (root_account_id, student_id);


--
-- Name: auditor_grade_change_records_20_root_account_id_student_id_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_grade_change_records_20_root_account_id_student_id_idx1 ON public.auditor_grade_change_records_2025_6 USING btree (root_account_id, student_id);


--
-- Name: auditor_grade_change_records__context_type_context_id_assi_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_grade_change_records__context_type_context_id_assi_idx1 ON public.auditor_grade_change_records_2025_6 USING btree (context_type, context_id, assignment_id);


--
-- Name: auditor_grade_change_records__context_type_context_id_assig_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_grade_change_records__context_type_context_id_assig_idx ON public.auditor_grade_change_records_2025_5 USING btree (context_type, context_id, assignment_id);


--
-- Name: auditor_grade_change_records__context_type_context_id_grad_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_grade_change_records__context_type_context_id_grad_idx1 ON public.auditor_grade_change_records_2025_6 USING btree (context_type, context_id, grader_id);


--
-- Name: auditor_grade_change_records__context_type_context_id_grade_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_grade_change_records__context_type_context_id_grade_idx ON public.auditor_grade_change_records_2025_5 USING btree (context_type, context_id, grader_id);


--
-- Name: auditor_grade_change_records__context_type_context_id_stud_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_grade_change_records__context_type_context_id_stud_idx1 ON public.auditor_grade_change_records_2025_6 USING btree (context_type, context_id, student_id);


--
-- Name: auditor_grade_change_records__context_type_context_id_stude_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_grade_change_records__context_type_context_id_stude_idx ON public.auditor_grade_change_records_2025_5 USING btree (context_type, context_id, student_id);


--
-- Name: auditor_pseudonym_records_2025_5_pseudonym_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_pseudonym_records_2025_5_pseudonym_id_idx ON public.auditor_pseudonym_records_2025_5 USING btree (pseudonym_id);


--
-- Name: auditor_pseudonym_records_2025_5_root_account_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_pseudonym_records_2025_5_root_account_id_idx ON public.auditor_pseudonym_records_2025_5 USING btree (root_account_id);


--
-- Name: auditor_pseudonym_records_2025_5_uuid_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_pseudonym_records_2025_5_uuid_idx ON public.auditor_pseudonym_records_2025_5 USING btree (uuid);


--
-- Name: auditor_pseudonym_records_2025_6_pseudonym_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_pseudonym_records_2025_6_pseudonym_id_idx ON public.auditor_pseudonym_records_2025_6 USING btree (pseudonym_id);


--
-- Name: auditor_pseudonym_records_2025_6_root_account_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_pseudonym_records_2025_6_root_account_id_idx ON public.auditor_pseudonym_records_2025_6 USING btree (root_account_id);


--
-- Name: auditor_pseudonym_records_2025_6_uuid_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditor_pseudonym_records_2025_6_uuid_idx ON public.auditor_pseudonym_records_2025_6 USING btree (uuid);


--
-- Name: by_sent_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX by_sent_at ON public.delayed_messages USING btree (send_at);


--
-- Name: ccid_raid_ws_sa; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ccid_raid_ws_sa ON public.delayed_messages USING btree (communication_channel_id, root_account_id, workflow_state, send_at);


--
-- Name: course_paces_unique_primary_plan_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX course_paces_unique_primary_plan_index ON public.course_paces USING btree (course_id) WHERE ((course_section_id IS NULL) AND (user_id IS NULL) AND ((workflow_state)::text = 'active'::text));


--
-- Name: error_reports_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX error_reports_created_at ON public.error_reports USING btree (created_at);


--
-- Name: event_predecessor_locator_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX event_predecessor_locator_index ON public.quiz_submission_events USING btree (quiz_submission_id, attempt, created_at);


--
-- Name: existing_undispatched_message; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX existing_undispatched_message ON public.messages USING btree (context_id, context_type, notification_name, "to", user_id);


--
-- Name: external_tool_placements_tool_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX external_tool_placements_tool_id ON public.context_external_tool_placements USING btree (context_external_tool_id);


--
-- Name: external_tool_placements_type_and_tool_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX external_tool_placements_type_and_tool_id ON public.context_external_tool_placements USING btree (placement_type, context_external_tool_id);


--
-- Name: get_delayed_jobs_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX get_delayed_jobs_index ON public.delayed_jobs USING btree (priority, run_at, id) WHERE (((queue)::text = 'canvas_queue'::text) AND (locked_at IS NULL) AND next_in_strand);


--
-- Name: idx_discussion_topic_section_visibility_on_section; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_discussion_topic_section_visibility_on_section ON public.discussion_topic_section_visibilities USING btree (course_section_id);


--
-- Name: idx_discussion_topic_section_visibility_on_topic; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_discussion_topic_section_visibility_on_topic ON public.discussion_topic_section_visibilities USING btree (discussion_topic_id);


--
-- Name: idx_mg_provisional_grades_unique_sub_scorer_when_not_final; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_mg_provisional_grades_unique_sub_scorer_when_not_final ON public.moderated_grading_provisional_grades USING btree (submission_id, scorer_id) WHERE (final = false);


--
-- Name: idx_mg_provisional_grades_unique_submission_when_final; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_mg_provisional_grades_unique_submission_when_final ON public.moderated_grading_provisional_grades USING btree (submission_id) WHERE (final = true);


--
-- Name: idx_mg_selections_unique_on_assignment_and_student; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_mg_selections_unique_on_assignment_and_student ON public.moderated_grading_selections USING btree (assignment_id, student_id);


--
-- Name: idx_qqs_on_quiz_and_aq_ids; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_qqs_on_quiz_and_aq_ids ON public.quiz_questions USING btree (quiz_id, assessment_question_id);


--
-- Name: index_LOQR_on_learning_outcome_result_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_LOQR_on_learning_outcome_result_id" ON public.learning_outcome_question_results USING btree (learning_outcome_result_id);


--
-- Name: index_abstract_courses_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_abstract_courses_on_account_id ON public.abstract_courses USING btree (account_id);


--
-- Name: index_abstract_courses_on_enrollment_term_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_abstract_courses_on_enrollment_term_id ON public.abstract_courses USING btree (enrollment_term_id);


--
-- Name: index_abstract_courses_on_root_account_id_and_sis_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_abstract_courses_on_root_account_id_and_sis_source_id ON public.abstract_courses USING btree (root_account_id, sis_source_id);


--
-- Name: index_abstract_courses_on_sis_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_abstract_courses_on_sis_batch_id ON public.abstract_courses USING btree (sis_batch_id) WHERE (sis_batch_id IS NOT NULL);


--
-- Name: index_abstract_courses_on_sis_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_abstract_courses_on_sis_source_id ON public.abstract_courses USING btree (sis_source_id);


--
-- Name: index_access_tokens_on_crypted_refresh_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_access_tokens_on_crypted_refresh_token ON public.access_tokens USING btree (crypted_refresh_token);


--
-- Name: index_access_tokens_on_crypted_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_access_tokens_on_crypted_token ON public.access_tokens USING btree (crypted_token);


--
-- Name: index_access_tokens_on_developer_key_id_and_last_used_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_access_tokens_on_developer_key_id_and_last_used_at ON public.access_tokens USING btree (developer_key_id, last_used_at);


--
-- Name: index_access_tokens_on_real_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_access_tokens_on_real_user_id ON public.access_tokens USING btree (real_user_id) WHERE (real_user_id IS NOT NULL);


--
-- Name: index_access_tokens_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_access_tokens_on_user_id ON public.access_tokens USING btree (user_id);


--
-- Name: index_access_tokens_on_workflow_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_access_tokens_on_workflow_state ON public.access_tokens USING btree (workflow_state);


--
-- Name: index_access_tokens_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_access_tokens_replica_identity ON public.access_tokens USING btree (root_account_id, id);


--
-- Name: index_account_notification_roles_on_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_account_notification_roles_on_role_id ON public.account_notification_roles USING btree (account_notification_id, role_id);


--
-- Name: index_account_notification_roles_only_on_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_notification_roles_only_on_role_id ON public.account_notification_roles USING btree (role_id) WHERE (role_id IS NOT NULL);


--
-- Name: index_account_notifications_by_account_and_timespan; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_notifications_by_account_and_timespan ON public.account_notifications USING btree (account_id, end_at, start_at);


--
-- Name: index_account_notifications_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_notifications_on_user_id ON public.account_notifications USING btree (user_id);


--
-- Name: index_account_report_rows_on_account_report_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_report_rows_on_account_report_id ON public.account_report_rows USING btree (account_report_id);


--
-- Name: index_account_report_rows_on_account_report_runner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_report_rows_on_account_report_runner_id ON public.account_report_rows USING btree (account_report_runner_id);


--
-- Name: index_account_report_rows_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_report_rows_on_created_at ON public.account_report_rows USING btree (created_at);


--
-- Name: index_account_report_rows_on_file; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_report_rows_on_file ON public.account_report_rows USING btree (file);


--
-- Name: index_account_report_runners_on_account_report_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_report_runners_on_account_report_id ON public.account_report_runners USING btree (account_report_id);


--
-- Name: index_account_reports_latest_of_type_per_account; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_reports_latest_of_type_per_account ON public.account_reports USING btree (account_id, report_type, created_at DESC);


--
-- Name: index_account_reports_on_attachment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_reports_on_attachment_id ON public.account_reports USING btree (attachment_id);


--
-- Name: index_account_reports_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_reports_on_user_id ON public.account_reports USING btree (user_id);


--
-- Name: index_account_users_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_users_on_account_id ON public.account_users USING btree (account_id);


--
-- Name: index_account_users_on_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_users_on_role_id ON public.account_users USING btree (role_id);


--
-- Name: index_account_users_on_sis_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_users_on_sis_batch_id ON public.account_users USING btree (sis_batch_id) WHERE (sis_batch_id IS NOT NULL);


--
-- Name: index_account_users_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_users_on_user_id ON public.account_users USING btree (user_id);


--
-- Name: index_account_users_on_workflow_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_users_on_workflow_state ON public.account_users USING btree (workflow_state);


--
-- Name: index_account_users_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_account_users_replica_identity ON public.account_users USING btree (root_account_id, id);


--
-- Name: index_accounts_on_account_calendar_subscription_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_account_calendar_subscription_type ON public.accounts USING btree (account_calendar_subscription_type) WHERE ((account_calendar_subscription_type)::text <> 'manual'::text);


--
-- Name: index_accounts_on_brand_config_md5; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_brand_config_md5 ON public.accounts USING btree (brand_config_md5) WHERE (brand_config_md5 IS NOT NULL);


--
-- Name: index_accounts_on_course_template_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_course_template_id ON public.accounts USING btree (course_template_id) WHERE (course_template_id IS NOT NULL);


--
-- Name: index_accounts_on_grading_standard_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_grading_standard_id ON public.accounts USING btree (grading_standard_id) WHERE (grading_standard_id IS NOT NULL);


--
-- Name: index_accounts_on_integration_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_accounts_on_integration_id ON public.accounts USING btree (integration_id, root_account_id) WHERE (integration_id IS NOT NULL);


--
-- Name: index_accounts_on_latest_outcome_import_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_latest_outcome_import_id ON public.accounts USING btree (latest_outcome_import_id) WHERE (latest_outcome_import_id IS NOT NULL);


--
-- Name: index_accounts_on_lti_context_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_accounts_on_lti_context_id ON public.accounts USING btree (lti_context_id);


--
-- Name: index_accounts_on_name_and_parent_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_name_and_parent_account_id ON public.accounts USING btree (name, parent_account_id);


--
-- Name: index_accounts_on_parent_account_id_and_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_parent_account_id_and_root_account_id ON public.accounts USING btree (parent_account_id, root_account_id);


--
-- Name: index_accounts_on_sis_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_sis_batch_id ON public.accounts USING btree (sis_batch_id) WHERE (sis_batch_id IS NOT NULL);


--
-- Name: index_accounts_on_sis_source_id_and_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_accounts_on_sis_source_id_and_root_account_id ON public.accounts USING btree (sis_source_id, root_account_id) WHERE (sis_source_id IS NOT NULL);


--
-- Name: index_accounts_on_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_accounts_on_uuid ON public.accounts USING btree (uuid);


--
-- Name: index_accounts_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_accounts_replica_identity ON public.accounts USING btree (root_account_id, id);


--
-- Name: index_active_comment_bank_items_on_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_comment_bank_items_on_user ON public.comment_bank_items USING btree (user_id) WHERE ((workflow_state)::text <> 'deleted'::text);


--
-- Name: index_active_submissions; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_submissions ON public.submissions USING btree (assignment_id, grading_period_id) WHERE ((workflow_state)::text <> 'deleted'::text);


--
-- Name: index_active_submissions_gp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_submissions_gp ON public.submissions USING btree (assignment_id, grading_period_id) WHERE (((workflow_state)::text <> 'deleted'::text) AND (grading_period_id IS NOT NULL));


--
-- Name: index_active_users_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_users_on_id ON public.users USING btree (id) WHERE ((workflow_state)::text <> 'deleted'::text);


--
-- Name: index_alert_criteria_on_alert_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_alert_criteria_on_alert_id ON public.alert_criteria USING btree (alert_id) WHERE (alert_id IS NOT NULL);


--
-- Name: index_ame_on_context_external_tool_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ame_on_context_external_tool_id ON public.anonymous_or_moderation_events USING btree (context_external_tool_id) WHERE (context_external_tool_id IS NOT NULL);


--
-- Name: index_anonymous_or_moderation_events_on_assignment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_anonymous_or_moderation_events_on_assignment_id ON public.anonymous_or_moderation_events USING btree (assignment_id);


--
-- Name: index_anonymous_or_moderation_events_on_canvadoc_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_anonymous_or_moderation_events_on_canvadoc_id ON public.anonymous_or_moderation_events USING btree (canvadoc_id);


--
-- Name: index_anonymous_or_moderation_events_on_quiz_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_anonymous_or_moderation_events_on_quiz_id ON public.anonymous_or_moderation_events USING btree (quiz_id) WHERE (quiz_id IS NOT NULL);


--
-- Name: index_anonymous_or_moderation_events_on_submission_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_anonymous_or_moderation_events_on_submission_id ON public.anonymous_or_moderation_events USING btree (submission_id);


--
-- Name: index_anonymous_or_moderation_events_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_anonymous_or_moderation_events_on_user_id ON public.anonymous_or_moderation_events USING btree (user_id);


--
-- Name: index_appointment_group_contexts_on_appointment_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_appointment_group_contexts_on_appointment_group_id ON public.appointment_group_contexts USING btree (appointment_group_id);


--
-- Name: index_appointment_group_sub_contexts_on_appointment_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_appointment_group_sub_contexts_on_appointment_group_id ON public.appointment_group_sub_contexts USING btree (appointment_group_id);


--
-- Name: index_aqb_context_and_title; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_aqb_context_and_title ON public.assessment_question_banks USING btree (context_id, context_type, title, id);


--
-- Name: index_assessment_question_banks_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assessment_question_banks_on_root_account_id ON public.assessment_question_banks USING btree (root_account_id);


--
-- Name: index_assessment_questions_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assessment_questions_on_root_account_id ON public.assessment_questions USING btree (root_account_id);


--
-- Name: index_assessment_requests_on_assessor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assessment_requests_on_assessor_id ON public.assessment_requests USING btree (assessor_id);


--
-- Name: index_assessment_requests_on_asset_id_and_asset_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assessment_requests_on_asset_id_and_asset_type ON public.assessment_requests USING btree (asset_id, asset_type);


--
-- Name: index_assessment_requests_on_rubric_assessment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assessment_requests_on_rubric_assessment_id ON public.assessment_requests USING btree (rubric_assessment_id);


--
-- Name: index_assessment_requests_on_rubric_association_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assessment_requests_on_rubric_association_id ON public.assessment_requests USING btree (rubric_association_id);


--
-- Name: index_assessment_requests_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assessment_requests_on_user_id ON public.assessment_requests USING btree (user_id);


--
-- Name: index_asset_user_accesses_on_ci_ct_ui_ua; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_asset_user_accesses_on_ci_ct_ui_ua ON public.asset_user_accesses USING btree (context_id, context_type, user_id, updated_at);


--
-- Name: index_asset_user_accesses_on_user_id_and_asset_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_asset_user_accesses_on_user_id_and_asset_code ON public.asset_user_accesses USING btree (user_id, asset_code);


--
-- Name: index_asset_user_accesses_on_user_id_context_id_asset_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_asset_user_accesses_on_user_id_context_id_asset_code ON public.asset_user_accesses USING btree (user_id, context_id, asset_code, id);


--
-- Name: index_asset_user_accesses_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_asset_user_accesses_replica_identity ON public.asset_user_accesses USING btree (root_account_id, id);


--
-- Name: index_assignment_configuration_tool_lookups_on_assignment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignment_configuration_tool_lookups_on_assignment_id ON public.assignment_configuration_tool_lookups USING btree (assignment_id);


--
-- Name: index_assignment_group_scores; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_assignment_group_scores ON public.scores USING btree (enrollment_id, assignment_group_id) WHERE (assignment_group_id IS NOT NULL);


--
-- Name: index_assignment_groups_on_cloned_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignment_groups_on_cloned_item_id ON public.assignment_groups USING btree (cloned_item_id) WHERE (cloned_item_id IS NOT NULL);


--
-- Name: index_assignment_groups_on_context_id_and_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignment_groups_on_context_id_and_context_type ON public.assignment_groups USING btree (context_id, context_type);


--
-- Name: index_assignment_groups_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignment_groups_on_root_account_id ON public.assignment_groups USING btree (root_account_id);


--
-- Name: index_assignment_override_students_on_assignment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignment_override_students_on_assignment_id ON public.assignment_override_students USING btree (assignment_id);


--
-- Name: index_assignment_override_students_on_assignment_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_assignment_override_students_on_assignment_id_and_user_id ON public.assignment_override_students USING btree (assignment_id, user_id) WHERE ((workflow_state)::text = 'active'::text);


--
-- Name: index_assignment_override_students_on_assignment_override_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignment_override_students_on_assignment_override_id ON public.assignment_override_students USING btree (assignment_override_id);


--
-- Name: index_assignment_override_students_on_attachment_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_assignment_override_students_on_attachment_id_and_user_id ON public.assignment_override_students USING btree (attachment_id, user_id) WHERE (attachment_id IS NOT NULL);


--
-- Name: index_assignment_override_students_on_context_module_and_user; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_assignment_override_students_on_context_module_and_user ON public.assignment_override_students USING btree (context_module_id, user_id) WHERE (context_module_id IS NOT NULL);


--
-- Name: index_assignment_override_students_on_discussion_topic_and_user; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_assignment_override_students_on_discussion_topic_and_user ON public.assignment_override_students USING btree (discussion_topic_id, user_id) WHERE (discussion_topic_id IS NOT NULL);


--
-- Name: index_assignment_override_students_on_quiz_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignment_override_students_on_quiz_id ON public.assignment_override_students USING btree (quiz_id);


--
-- Name: index_assignment_override_students_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignment_override_students_on_root_account_id ON public.assignment_override_students USING btree (root_account_id);


--
-- Name: index_assignment_override_students_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignment_override_students_on_user_id ON public.assignment_override_students USING btree (user_id);


--
-- Name: index_assignment_override_students_on_user_id_and_quiz_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignment_override_students_on_user_id_and_quiz_id ON public.assignment_override_students USING btree (user_id, quiz_id);


--
-- Name: index_assignment_override_students_on_wiki_page_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_assignment_override_students_on_wiki_page_id_and_user_id ON public.assignment_override_students USING btree (wiki_page_id, user_id) WHERE (wiki_page_id IS NOT NULL);


--
-- Name: index_assignment_override_students_on_workflow_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignment_override_students_on_workflow_state ON public.assignment_override_students USING btree (workflow_state);


--
-- Name: index_assignment_overrides_due_at_when_overridden; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignment_overrides_due_at_when_overridden ON public.assignment_overrides USING btree (due_at) WHERE due_at_overridden;


--
-- Name: index_assignment_overrides_on_assignment_and_set; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_assignment_overrides_on_assignment_and_set ON public.assignment_overrides USING btree (assignment_id, set_type, set_id) WHERE (((workflow_state)::text = 'active'::text) AND (set_id IS NOT NULL));


--
-- Name: index_assignment_overrides_on_assignment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignment_overrides_on_assignment_id ON public.assignment_overrides USING btree (assignment_id);


--
-- Name: index_assignment_overrides_on_attachment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignment_overrides_on_attachment_id ON public.assignment_overrides USING btree (attachment_id) WHERE (attachment_id IS NOT NULL);


--
-- Name: index_assignment_overrides_on_attachment_id_and_set; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_assignment_overrides_on_attachment_id_and_set ON public.assignment_overrides USING btree (attachment_id, set_id, set_type) WHERE ((attachment_id IS NOT NULL) AND ((workflow_state)::text = 'active'::text) AND (set_id IS NOT NULL));


--
-- Name: index_assignment_overrides_on_context_module_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignment_overrides_on_context_module_id ON public.assignment_overrides USING btree (context_module_id) WHERE (context_module_id IS NOT NULL);


--
-- Name: index_assignment_overrides_on_context_module_id_and_set; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_assignment_overrides_on_context_module_id_and_set ON public.assignment_overrides USING btree (context_module_id, set_id, set_type) WHERE ((context_module_id IS NOT NULL) AND ((workflow_state)::text = 'active'::text) AND (set_id IS NOT NULL));


--
-- Name: index_assignment_overrides_on_discussion_topic_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignment_overrides_on_discussion_topic_id ON public.assignment_overrides USING btree (discussion_topic_id) WHERE (discussion_topic_id IS NOT NULL);


--
-- Name: index_assignment_overrides_on_discussion_topic_id_and_set; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_assignment_overrides_on_discussion_topic_id_and_set ON public.assignment_overrides USING btree (discussion_topic_id, set_id, set_type) WHERE ((discussion_topic_id IS NOT NULL) AND ((workflow_state)::text = 'active'::text) AND (set_id IS NOT NULL));


--
-- Name: index_assignment_overrides_on_quiz_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignment_overrides_on_quiz_id ON public.assignment_overrides USING btree (quiz_id);


--
-- Name: index_assignment_overrides_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignment_overrides_on_root_account_id ON public.assignment_overrides USING btree (root_account_id);


--
-- Name: index_assignment_overrides_on_set_type_and_set_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignment_overrides_on_set_type_and_set_id ON public.assignment_overrides USING btree (set_type, set_id);


--
-- Name: index_assignment_overrides_on_wiki_page_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignment_overrides_on_wiki_page_id ON public.assignment_overrides USING btree (wiki_page_id) WHERE (wiki_page_id IS NOT NULL);


--
-- Name: index_assignment_overrides_on_wiki_page_id_and_set; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_assignment_overrides_on_wiki_page_id_and_set ON public.assignment_overrides USING btree (wiki_page_id, set_id, set_type) WHERE ((wiki_page_id IS NOT NULL) AND ((workflow_state)::text = 'active'::text) AND (set_id IS NOT NULL));


--
-- Name: index_assignments_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignments_active ON public.assignments USING btree (context_id) WHERE (((context_type)::text = 'Course'::text) AND ((workflow_state)::text <> 'deleted'::text));


--
-- Name: index_assignments_duplicating_on_started_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignments_duplicating_on_started_at ON public.assignments USING btree (duplication_started_at) WHERE (((workflow_state)::text = 'migrating'::text) AND (duplication_started_at IS NOT NULL));


--
-- Name: index_assignments_on_annotatable_attachment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignments_on_annotatable_attachment_id ON public.assignments USING btree (annotatable_attachment_id) WHERE (annotatable_attachment_id IS NOT NULL);


--
-- Name: index_assignments_on_assignment_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignments_on_assignment_group_id ON public.assignments USING btree (assignment_group_id);


--
-- Name: index_assignments_on_cloned_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignments_on_cloned_item_id ON public.assignments USING btree (cloned_item_id) WHERE (cloned_item_id IS NOT NULL);


--
-- Name: index_assignments_on_context_grading_standard_grading_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignments_on_context_grading_standard_grading_type ON public.assignments USING btree (context_id, grading_standard_id, grading_type);


--
-- Name: index_assignments_on_context_id_and_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignments_on_context_id_and_context_type ON public.assignments USING btree (context_id, context_type);


--
-- Name: index_assignments_on_duplicate_of_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignments_on_duplicate_of_id ON public.assignments USING btree (duplicate_of_id) WHERE (duplicate_of_id IS NOT NULL);


--
-- Name: index_assignments_on_duplication_started_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignments_on_duplication_started_at ON public.assignments USING btree (duplication_started_at) WHERE ((duplication_started_at IS NOT NULL) AND ((workflow_state)::text = 'duplicating'::text));


--
-- Name: index_assignments_on_final_grader_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignments_on_final_grader_id ON public.assignments USING btree (final_grader_id) WHERE (final_grader_id IS NOT NULL);


--
-- Name: index_assignments_on_grader_section_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignments_on_grader_section_id ON public.assignments USING btree (grader_section_id) WHERE (grader_section_id IS NOT NULL);


--
-- Name: index_assignments_on_grading_standard_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignments_on_grading_standard_id ON public.assignments USING btree (grading_standard_id);


--
-- Name: index_assignments_on_group_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignments_on_group_category_id ON public.assignments USING btree (group_category_id) WHERE (group_category_id IS NOT NULL);


--
-- Name: index_assignments_on_important_dates; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignments_on_important_dates ON public.assignments USING btree (important_dates) WHERE important_dates;


--
-- Name: index_assignments_on_importing_started_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignments_on_importing_started_at ON public.assignments USING btree (importing_started_at) WHERE ((importing_started_at IS NOT NULL) AND ((workflow_state)::text = 'importing'::text));


--
-- Name: index_assignments_on_lti_context_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_assignments_on_lti_context_id ON public.assignments USING btree (lti_context_id);


--
-- Name: index_assignments_on_migrate_from_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignments_on_migrate_from_id ON public.assignments USING btree (migrate_from_id) WHERE (migrate_from_id IS NOT NULL);


--
-- Name: index_assignments_on_parent_assignment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignments_on_parent_assignment_id ON public.assignments USING btree (parent_assignment_id);


--
-- Name: index_assignments_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignments_on_root_account_id ON public.assignments USING btree (root_account_id);


--
-- Name: index_assignments_on_sis_source_id_and_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_assignments_on_sis_source_id_and_root_account_id ON public.assignments USING btree (sis_source_id, root_account_id) WHERE (sis_source_id IS NOT NULL);


--
-- Name: index_assignments_on_turnitin_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_assignments_on_turnitin_id ON public.assignments USING btree (turnitin_id) WHERE (turnitin_id IS NOT NULL);


--
-- Name: index_assignments_on_workflow_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignments_on_workflow_state ON public.assignments USING btree (workflow_state);


--
-- Name: index_attachment_associations_on_attachment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachment_associations_on_attachment_id ON public.attachment_associations USING btree (attachment_id);


--
-- Name: index_attachment_associations_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachment_associations_on_root_account_id ON public.attachment_associations USING btree (root_account_id);


--
-- Name: index_attachment_attempt_submission; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_attachment_attempt_submission ON public.canvadocs_annotation_contexts USING btree (attachment_id, submission_attempt, submission_id);


--
-- Name: index_attachment_submission; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_attachment_submission ON public.canvadocs_annotation_contexts USING btree (attachment_id, submission_id) WHERE (submission_attempt IS NULL);


--
-- Name: index_attachment_upload_statuses_on_attachment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachment_upload_statuses_on_attachment_id ON public.attachment_upload_statuses USING btree (attachment_id);


--
-- Name: index_attachments_on_cloned_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_cloned_item_id ON public.attachments USING btree (cloned_item_id);


--
-- Name: index_attachments_on_context_and_migration_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_context_and_migration_id ON public.attachments USING btree (context_id, context_type, migration_id) WHERE (migration_id IS NOT NULL);


--
-- Name: index_attachments_on_context_and_migration_id_pattern_ops; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_context_and_migration_id_pattern_ops ON public.attachments USING btree (context_id, context_type, migration_id text_pattern_ops) WHERE (migration_id IS NOT NULL);


--
-- Name: index_attachments_on_context_id_and_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_context_id_and_context_type ON public.attachments USING btree (context_id, context_type);


--
-- Name: index_attachments_on_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_context_type ON public.attachments USING btree (context_type) WHERE (((workflow_state)::text = 'deleted'::text) AND ((file_state)::text = 'deleted'::text));


--
-- Name: index_attachments_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_created_at ON public.attachments USING btree (created_at) WHERE (((context_type)::text = ANY ((ARRAY['ContentExport'::character varying, 'ContentMigration'::character varying])::text[])) AND ((file_state)::text <> ALL ((ARRAY['deleted'::character varying, 'broken'::character varying])::text[])) AND (root_attachment_id IS NULL));


--
-- Name: index_attachments_on_folder_id_and_file_state_and_display_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_folder_id_and_file_state_and_display_name ON public.attachments USING btree (folder_id, file_state, display_name COLLATE public."und-u-kn-true") WHERE (folder_id IS NOT NULL);


--
-- Name: index_attachments_on_folder_id_and_file_state_and_position; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_folder_id_and_file_state_and_position ON public.attachments USING btree (folder_id, file_state, "position");


--
-- Name: index_attachments_on_folder_id_and_position; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_folder_id_and_position ON public.attachments USING btree (folder_id, "position") WHERE (folder_id IS NOT NULL);


--
-- Name: index_attachments_on_instfs_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_instfs_uuid ON public.attachments USING btree (instfs_uuid) WHERE (instfs_uuid IS NOT NULL);


--
-- Name: index_attachments_on_md5_and_namespace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_md5_and_namespace ON public.attachments USING btree (md5, namespace);


--
-- Name: index_attachments_on_md5_and_namespace_and_content_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_md5_and_namespace_and_content_type ON public.attachments USING btree (md5, namespace, content_type) WHERE ((root_attachment_id IS NULL) AND (filename IS NOT NULL));


--
-- Name: index_attachments_on_media_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_media_entry_id ON public.attachments USING btree (media_entry_id);


--
-- Name: index_attachments_on_namespace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_namespace ON public.attachments USING btree (namespace);


--
-- Name: index_attachments_on_need_notify; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_need_notify ON public.attachments USING btree (need_notify) WHERE need_notify;


--
-- Name: index_attachments_on_replacement_attachment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_replacement_attachment_id ON public.attachments USING btree (replacement_attachment_id) WHERE (replacement_attachment_id IS NOT NULL);


--
-- Name: index_attachments_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_root_account_id ON public.attachments USING btree (root_account_id);


--
-- Name: index_attachments_on_root_attachment_id_not_null; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_root_attachment_id_not_null ON public.attachments USING btree (root_attachment_id) WHERE (root_attachment_id IS NOT NULL);


--
-- Name: index_attachments_on_usage_rights_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_usage_rights_id ON public.attachments USING btree (usage_rights_id) WHERE (usage_rights_id IS NOT NULL);


--
-- Name: index_attachments_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_user_id ON public.attachments USING btree (user_id);


--
-- Name: index_attachments_on_workflow_state_and_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_workflow_state_and_updated_at ON public.attachments USING btree (workflow_state, updated_at);


--
-- Name: index_auditor_authentication_records_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_auditor_authentication_records_on_account_id ON public.auditor_authentication_records USING btree (account_id);


--
-- Name: index_auditor_authentication_records_on_pseudonym_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_auditor_authentication_records_on_pseudonym_id ON public.auditor_authentication_records USING btree (pseudonym_id);


--
-- Name: index_auditor_authentication_records_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_auditor_authentication_records_on_user_id ON public.auditor_authentication_records USING btree (user_id);


--
-- Name: index_auditor_course_records_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_auditor_course_records_on_account_id ON public.auditor_course_records USING btree (account_id);


--
-- Name: index_auditor_course_records_on_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_auditor_course_records_on_course_id ON public.auditor_course_records USING btree (course_id);


--
-- Name: index_auditor_course_records_on_sis_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_auditor_course_records_on_sis_batch_id ON public.auditor_course_records USING btree (sis_batch_id);


--
-- Name: index_auditor_course_records_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_auditor_course_records_on_user_id ON public.auditor_course_records USING btree (user_id);


--
-- Name: index_auditor_feature_flag_records_on_feature_flag_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_auditor_feature_flag_records_on_feature_flag_id ON public.auditor_feature_flag_records USING btree (feature_flag_id);


--
-- Name: index_auditor_feature_flag_records_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_auditor_feature_flag_records_on_root_account_id ON public.auditor_feature_flag_records USING btree (root_account_id);


--
-- Name: index_auditor_feature_flag_records_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_auditor_feature_flag_records_on_user_id ON public.auditor_feature_flag_records USING btree (user_id);


--
-- Name: index_auditor_feature_flag_records_on_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_auditor_feature_flag_records_on_uuid ON public.auditor_feature_flag_records USING btree (uuid);


--
-- Name: index_auditor_grade_change_records_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_auditor_grade_change_records_on_account_id ON public.auditor_grade_change_records USING btree (account_id);


--
-- Name: index_auditor_grade_change_records_on_assignment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_auditor_grade_change_records_on_assignment_id ON public.auditor_grade_change_records USING btree (assignment_id);


--
-- Name: index_auditor_grade_change_records_on_grader_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_auditor_grade_change_records_on_grader_id ON public.auditor_grade_change_records USING btree (grader_id);


--
-- Name: index_auditor_grade_change_records_on_grading_period_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_auditor_grade_change_records_on_grading_period_id ON public.auditor_grade_change_records USING btree (grading_period_id) WHERE (grading_period_id IS NOT NULL);


--
-- Name: index_auditor_grade_change_records_on_student_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_auditor_grade_change_records_on_student_id ON public.auditor_grade_change_records USING btree (student_id);


--
-- Name: index_auditor_grade_change_records_on_submission_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_auditor_grade_change_records_on_submission_id ON public.auditor_grade_change_records USING btree (submission_id);


--
-- Name: index_auditor_grades_by_account_and_grader; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_auditor_grades_by_account_and_grader ON public.auditor_grade_change_records USING btree (root_account_id, grader_id);


--
-- Name: index_auditor_grades_by_account_and_student; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_auditor_grades_by_account_and_student ON public.auditor_grade_change_records USING btree (root_account_id, student_id);


--
-- Name: index_auditor_grades_by_course_and_assignment; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_auditor_grades_by_course_and_assignment ON public.auditor_grade_change_records USING btree (context_type, context_id, assignment_id);


--
-- Name: index_auditor_grades_by_course_and_grader; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_auditor_grades_by_course_and_grader ON public.auditor_grade_change_records USING btree (context_type, context_id, grader_id);


--
-- Name: index_auditor_grades_by_course_and_student; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_auditor_grades_by_course_and_student ON public.auditor_grade_change_records USING btree (context_type, context_id, student_id);


--
-- Name: index_auditor_pseudonym_records_on_pseudonym_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_auditor_pseudonym_records_on_pseudonym_id ON public.auditor_pseudonym_records USING btree (pseudonym_id);


--
-- Name: index_auditor_pseudonym_records_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_auditor_pseudonym_records_on_root_account_id ON public.auditor_pseudonym_records USING btree (root_account_id);


--
-- Name: index_auditor_pseudonym_records_on_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_auditor_pseudonym_records_on_uuid ON public.auditor_pseudonym_records USING btree (uuid);


--
-- Name: index_auth_audits_on_unique_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_auth_audits_on_unique_uuid ON public.auditor_authentication_records USING btree (uuid);


--
-- Name: index_authentication_providers_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_authentication_providers_on_account_id ON public.authentication_providers USING btree (account_id);


--
-- Name: index_authentication_providers_on_metadata_uri; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_authentication_providers_on_metadata_uri ON public.authentication_providers USING btree (metadata_uri) WHERE (metadata_uri IS NOT NULL);


--
-- Name: index_authentication_providers_on_workflow_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_authentication_providers_on_workflow_state ON public.authentication_providers USING btree (workflow_state);


--
-- Name: index_blackout_dates_on_context_type_and_context_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blackout_dates_on_context_type_and_context_id ON public.blackout_dates USING btree (context_type, context_id);


--
-- Name: index_blackout_dates_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_blackout_dates_replica_identity ON public.blackout_dates USING btree (root_account_id, id);


--
-- Name: index_block_editors_on_context; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_block_editors_on_context ON public.block_editors USING btree (context_type, context_id);


--
-- Name: index_block_editors_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_block_editors_replica_identity ON public.block_editors USING btree (root_account_id, id);

ALTER TABLE ONLY public.block_editors REPLICA IDENTITY USING INDEX index_block_editors_replica_identity;


--
-- Name: index_bookmarks_bookmarks_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bookmarks_bookmarks_on_user_id ON public.bookmarks_bookmarks USING btree (user_id);


--
-- Name: index_brand_configs_on_share; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_brand_configs_on_share ON public.brand_configs USING btree (share);


--
-- Name: index_caa_on_course_id_and_section_id_and_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_caa_on_course_id_and_section_id_and_account_id ON public.course_account_associations USING btree (course_id, course_section_id, account_id);


--
-- Name: index_calendar_events_on_cloned_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_calendar_events_on_cloned_item_id ON public.calendar_events USING btree (cloned_item_id) WHERE (cloned_item_id IS NOT NULL);


--
-- Name: index_calendar_events_on_context_and_timetable_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_calendar_events_on_context_and_timetable_code ON public.calendar_events USING btree (context_id, context_type, timetable_code) WHERE (timetable_code IS NOT NULL);


--
-- Name: index_calendar_events_on_context_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_calendar_events_on_context_code ON public.calendar_events USING btree (context_code);


--
-- Name: index_calendar_events_on_context_id_and_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_calendar_events_on_context_id_and_context_type ON public.calendar_events USING btree (context_id, context_type);


--
-- Name: index_calendar_events_on_effective_context_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_calendar_events_on_effective_context_code ON public.calendar_events USING btree (effective_context_code) WHERE (effective_context_code IS NOT NULL);


--
-- Name: index_calendar_events_on_important_dates; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_calendar_events_on_important_dates ON public.calendar_events USING btree (important_dates) WHERE important_dates;


--
-- Name: index_calendar_events_on_parent_calendar_event_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_calendar_events_on_parent_calendar_event_id ON public.calendar_events USING btree (parent_calendar_event_id);


--
-- Name: index_calendar_events_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_calendar_events_on_root_account_id ON public.calendar_events USING btree (root_account_id);


--
-- Name: index_calendar_events_on_series_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_calendar_events_on_series_uuid ON public.calendar_events USING btree (series_uuid);


--
-- Name: index_calendar_events_on_start_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_calendar_events_on_start_at ON public.calendar_events USING btree (start_at) WHERE ((workflow_state)::text <> 'deleted'::text);


--
-- Name: index_calendar_events_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_calendar_events_on_user_id ON public.calendar_events USING btree (user_id);


--
-- Name: index_calendar_events_on_web_conference_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_calendar_events_on_web_conference_id ON public.calendar_events USING btree (web_conference_id) WHERE (web_conference_id IS NOT NULL);


--
-- Name: index_canvadocs_annotation_contexts_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_canvadocs_annotation_contexts_on_root_account_id ON public.canvadocs_annotation_contexts USING btree (root_account_id);


--
-- Name: index_canvadocs_annotation_contexts_on_submission_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_canvadocs_annotation_contexts_on_submission_id ON public.canvadocs_annotation_contexts USING btree (submission_id);


--
-- Name: index_canvadocs_on_attachment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_canvadocs_on_attachment_id ON public.canvadocs USING btree (attachment_id);


--
-- Name: index_canvadocs_on_document_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_canvadocs_on_document_id ON public.canvadocs USING btree (document_id);


--
-- Name: index_canvadocs_submissions_on_canvadoc_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_canvadocs_submissions_on_canvadoc_id ON public.canvadocs_submissions USING btree (canvadoc_id);


--
-- Name: index_canvadocs_submissions_on_crocodoc_document_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_canvadocs_submissions_on_crocodoc_document_id ON public.canvadocs_submissions USING btree (crocodoc_document_id) WHERE (crocodoc_document_id IS NOT NULL);


--
-- Name: index_canvadocs_submissions_on_submission_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_canvadocs_submissions_on_submission_id ON public.canvadocs_submissions USING btree (submission_id);


--
-- Name: index_canvas_metadata_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_canvas_metadata_on_key ON public.canvas_metadata USING btree (key);


--
-- Name: index_child_content_tags_on_content; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_child_content_tags_on_content ON public.master_courses_child_content_tags USING btree (content_type, content_id);


--
-- Name: index_child_content_tags_on_migration_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_child_content_tags_on_migration_id ON public.master_courses_child_content_tags USING btree (migration_id);


--
-- Name: index_child_content_tags_on_subscription; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_child_content_tags_on_subscription ON public.master_courses_child_content_tags USING btree (child_subscription_id);


--
-- Name: index_child_subscriptions_on_child_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_child_subscriptions_on_child_course_id ON public.master_courses_child_subscriptions USING btree (child_course_id);


--
-- Name: index_cmp_on_cpi_and_cmi; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cmp_on_cpi_and_cmi ON public.conversation_message_participants USING btree (conversation_participant_id, conversation_message_id);


--
-- Name: index_cmp_on_user_id_and_module_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_cmp_on_user_id_and_module_id ON public.context_module_progressions USING btree (user_id, context_module_id);


--
-- Name: index_collaborations_on_context_id_and_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collaborations_on_context_id_and_context_type ON public.collaborations USING btree (context_id, context_type);


--
-- Name: index_collaborations_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collaborations_on_user_id ON public.collaborations USING btree (user_id);


--
-- Name: index_collaborators_on_collaboration_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collaborators_on_collaboration_id ON public.collaborators USING btree (collaboration_id);


--
-- Name: index_collaborators_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collaborators_on_group_id ON public.collaborators USING btree (group_id);


--
-- Name: index_collaborators_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collaborators_on_user_id ON public.collaborators USING btree (user_id);


--
-- Name: index_comment_bank_items_on_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comment_bank_items_on_course_id ON public.comment_bank_items USING btree (course_id);


--
-- Name: index_comment_bank_items_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comment_bank_items_on_user_id ON public.comment_bank_items USING btree (user_id);


--
-- Name: index_comment_bank_items_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_comment_bank_items_replica_identity ON public.comment_bank_items USING btree (root_account_id, id);


--
-- Name: index_communication_channels_on_confirmation_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_communication_channels_on_confirmation_code ON public.communication_channels USING btree (confirmation_code);


--
-- Name: index_communication_channels_on_last_bounce_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_communication_channels_on_last_bounce_at ON public.communication_channels USING btree (last_bounce_at) WHERE (bounce_count > 0);


--
-- Name: index_communication_channels_on_path_and_path_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_communication_channels_on_path_and_path_type ON public.communication_channels USING btree (lower((path)::text), path_type);


--
-- Name: index_communication_channels_on_pseudonym_id_and_position; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_communication_channels_on_pseudonym_id_and_position ON public.communication_channels USING btree (pseudonym_id, "position");


--
-- Name: index_communication_channels_on_user_id_and_path_and_path_type; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_communication_channels_on_user_id_and_path_and_path_type ON public.communication_channels USING btree (user_id, lower((path)::text), path_type);


--
-- Name: index_communication_channels_on_user_id_and_position; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_communication_channels_on_user_id_and_position ON public.communication_channels USING btree (user_id, "position");


--
-- Name: index_conditional_release_assignment_sets_on_scoring_range_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_conditional_release_assignment_sets_on_scoring_range_id ON public.conditional_release_assignment_sets USING btree (scoring_range_id);


--
-- Name: index_conditional_release_rules_on_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_conditional_release_rules_on_course_id ON public.conditional_release_rules USING btree (course_id);


--
-- Name: index_conditional_release_rules_on_trigger_assignment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_conditional_release_rules_on_trigger_assignment_id ON public.conditional_release_rules USING btree (trigger_assignment_id);


--
-- Name: index_conditional_release_scoring_ranges_on_rule_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_conditional_release_scoring_ranges_on_rule_id ON public.conditional_release_scoring_ranges USING btree (rule_id);


--
-- Name: index_content_exports_on_attachment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_exports_on_attachment_id ON public.content_exports USING btree (attachment_id);


--
-- Name: index_content_exports_on_content_migration_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_exports_on_content_migration_id ON public.content_exports USING btree (content_migration_id);


--
-- Name: index_content_exports_on_context_id_and_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_exports_on_context_id_and_context_type ON public.content_exports USING btree (context_id, context_type);


--
-- Name: index_content_exports_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_exports_on_user_id ON public.content_exports USING btree (user_id) WHERE (user_id IS NOT NULL);


--
-- Name: index_content_migrations_blocked_migrations; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_migrations_blocked_migrations ON public.content_migrations USING btree (context_id, started_at) WHERE (started_at IS NOT NULL);


--
-- Name: index_content_migrations_on_asset_map_attachment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_migrations_on_asset_map_attachment_id ON public.content_migrations USING btree (asset_map_attachment_id) WHERE (asset_map_attachment_id IS NOT NULL);


--
-- Name: index_content_migrations_on_attachment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_migrations_on_attachment_id ON public.content_migrations USING btree (attachment_id) WHERE (attachment_id IS NOT NULL);


--
-- Name: index_content_migrations_on_child_subscription_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_migrations_on_child_subscription_id ON public.content_migrations USING btree (child_subscription_id) WHERE (child_subscription_id IS NOT NULL);


--
-- Name: index_content_migrations_on_context_id_and_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_migrations_on_context_id_and_id ON public.content_migrations USING btree (context_id, id) WHERE ((workflow_state)::text = 'queued'::text);


--
-- Name: index_content_migrations_on_context_id_and_id_no_clause; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_migrations_on_context_id_and_id_no_clause ON public.content_migrations USING btree (context_id, id);


--
-- Name: index_content_migrations_on_exported_attachment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_migrations_on_exported_attachment_id ON public.content_migrations USING btree (exported_attachment_id) WHERE (exported_attachment_id IS NOT NULL);


--
-- Name: index_content_migrations_on_overview_attachment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_migrations_on_overview_attachment_id ON public.content_migrations USING btree (overview_attachment_id) WHERE (overview_attachment_id IS NOT NULL);


--
-- Name: index_content_migrations_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_migrations_on_root_account_id ON public.content_migrations USING btree (root_account_id);


--
-- Name: index_content_migrations_on_source_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_migrations_on_source_course_id ON public.content_migrations USING btree (source_course_id) WHERE (source_course_id IS NOT NULL);


--
-- Name: index_content_migrations_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_migrations_on_user_id ON public.content_migrations USING btree (user_id) WHERE (user_id IS NOT NULL);


--
-- Name: index_content_participation_counts_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_participation_counts_on_root_account_id ON public.content_participation_counts USING btree (root_account_id);


--
-- Name: index_content_participation_counts_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_participation_counts_on_user_id ON public.content_participation_counts USING btree (user_id) WHERE (user_id IS NOT NULL);


--
-- Name: index_content_participation_counts_uniquely; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_content_participation_counts_uniquely ON public.content_participation_counts USING btree (context_id, context_type, user_id, content_type);


--
-- Name: index_content_participations_by_type_uniquely; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_content_participations_by_type_uniquely ON public.content_participations USING btree (content_id, content_type, user_id, content_item);


--
-- Name: index_content_participations_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_participations_on_root_account_id ON public.content_participations USING btree (root_account_id);


--
-- Name: index_content_participations_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_participations_on_user_id ON public.content_participations USING btree (user_id);


--
-- Name: index_content_participations_on_user_id_unread; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_participations_on_user_id_unread ON public.content_participations USING btree (user_id) WHERE ((workflow_state)::text = 'unread'::text);


--
-- Name: index_content_shares_on_content_export_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_shares_on_content_export_id ON public.content_shares USING btree (content_export_id);


--
-- Name: index_content_shares_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_shares_on_root_account_id ON public.content_shares USING btree (root_account_id);


--
-- Name: index_content_shares_on_sender_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_shares_on_sender_id ON public.content_shares USING btree (sender_id) WHERE (sender_id IS NOT NULL);


--
-- Name: index_content_shares_on_user_and_content_export_and_sender_ids; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_content_shares_on_user_and_content_export_and_sender_ids ON public.content_shares USING btree (user_id, content_export_id, sender_id);


--
-- Name: index_content_tags_for_due_date_cacher; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_tags_for_due_date_cacher ON public.content_tags USING btree (content_type, context_type, context_id) WHERE ((workflow_state)::text <> 'deleted'::text);


--
-- Name: index_content_tags_on_associated_asset; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_tags_on_associated_asset ON public.content_tags USING btree (associated_asset_id, associated_asset_type);


--
-- Name: index_content_tags_on_cloned_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_tags_on_cloned_item_id ON public.content_tags USING btree (cloned_item_id) WHERE (cloned_item_id IS NOT NULL);


--
-- Name: index_content_tags_on_content_id_and_content_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_tags_on_content_id_and_content_type ON public.content_tags USING btree (content_id, content_type);


--
-- Name: index_content_tags_on_context_id_and_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_tags_on_context_id_and_context_type ON public.content_tags USING btree (context_id, context_type);


--
-- Name: index_content_tags_on_context_module_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_tags_on_context_module_id ON public.content_tags USING btree (context_module_id);


--
-- Name: index_content_tags_on_context_when_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_tags_on_context_when_active ON public.content_tags USING btree (context_id, context_type, content_type) WHERE ((workflow_state)::text = 'active'::text);


--
-- Name: index_content_tags_on_learning_outcome_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_tags_on_learning_outcome_id ON public.content_tags USING btree (learning_outcome_id) WHERE (learning_outcome_id IS NOT NULL);


--
-- Name: index_content_tags_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_content_tags_replica_identity ON public.content_tags USING btree (root_account_id, id);


--
-- Name: index_context_external_tools_on_cloned_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_context_external_tools_on_cloned_item_id ON public.context_external_tools USING btree (cloned_item_id) WHERE (cloned_item_id IS NOT NULL);


--
-- Name: index_context_external_tools_on_consumer_key; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_context_external_tools_on_consumer_key ON public.context_external_tools USING btree (consumer_key);


--
-- Name: index_context_external_tools_on_context_id_and_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_context_external_tools_on_context_id_and_context_type ON public.context_external_tools USING btree (context_id, context_type);


--
-- Name: index_context_external_tools_on_developer_key_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_context_external_tools_on_developer_key_id ON public.context_external_tools USING btree (developer_key_id);


--
-- Name: index_context_external_tools_on_identity_hash; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_context_external_tools_on_identity_hash ON public.context_external_tools USING btree (identity_hash) WHERE ((identity_hash)::text <> 'duplicate'::text);


--
-- Name: index_context_external_tools_on_tool_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_context_external_tools_on_tool_id ON public.context_external_tools USING btree (tool_id);


--
-- Name: index_context_external_tools_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_context_external_tools_replica_identity ON public.context_external_tools USING btree (root_account_id, id);


--
-- Name: index_context_module_progressions_on_context_module_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_context_module_progressions_on_context_module_id ON public.context_module_progressions USING btree (context_module_id);


--
-- Name: index_context_module_progressions_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_context_module_progressions_on_root_account_id ON public.context_module_progressions USING btree (root_account_id);


--
-- Name: index_context_modules_on_cloned_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_context_modules_on_cloned_item_id ON public.context_modules USING btree (cloned_item_id) WHERE (cloned_item_id IS NOT NULL);


--
-- Name: index_context_modules_on_context_id_and_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_context_modules_on_context_id_and_context_type ON public.context_modules USING btree (context_id, context_type);


--
-- Name: index_context_modules_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_context_modules_on_root_account_id ON public.context_modules USING btree (root_account_id);


--
-- Name: index_conversation_batches_on_root_conversation_message_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_conversation_batches_on_root_conversation_message_id ON public.conversation_batches USING btree (root_conversation_message_id);


--
-- Name: index_conversation_batches_on_user_id_and_workflow_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_conversation_batches_on_user_id_and_workflow_state ON public.conversation_batches USING btree (user_id, workflow_state);


--
-- Name: index_conversation_message_participants_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_conversation_message_participants_on_deleted_at ON public.conversation_message_participants USING btree (deleted_at);


--
-- Name: index_conversation_message_participants_on_message_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_conversation_message_participants_on_message_id ON public.conversation_message_participants USING btree (conversation_message_id);


--
-- Name: index_conversation_message_participants_on_uid_and_message_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_conversation_message_participants_on_uid_and_message_id ON public.conversation_message_participants USING btree (user_id, conversation_message_id);


--
-- Name: index_conversation_messages_on_author_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_conversation_messages_on_author_id ON public.conversation_messages USING btree (author_id);


--
-- Name: index_conversation_messages_on_conversation_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_conversation_messages_on_conversation_id_and_created_at ON public.conversation_messages USING btree (conversation_id, created_at);


--
-- Name: index_conversation_participants_on_conversation_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_conversation_participants_on_conversation_id_and_user_id ON public.conversation_participants USING btree (conversation_id, user_id);


--
-- Name: index_conversation_participants_on_private_hash_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_conversation_participants_on_private_hash_and_user_id ON public.conversation_participants USING btree (private_hash, user_id) WHERE (private_hash IS NOT NULL);


--
-- Name: index_conversation_participants_on_user_id_and_last_message_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_conversation_participants_on_user_id_and_last_message_at ON public.conversation_participants USING btree (user_id, last_message_at);


--
-- Name: index_conversation_participants_unread_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_conversation_participants_unread_on_user_id ON public.conversation_participants USING btree (user_id) WHERE ((workflow_state)::text = 'unread'::text);


--
-- Name: index_conversations_on_private_hash; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_conversations_on_private_hash ON public.conversations USING btree (private_hash);


--
-- Name: index_course_account_associations_on_account_id_and_depth_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_course_account_associations_on_account_id_and_depth_id ON public.course_account_associations USING btree (account_id, depth);


--
-- Name: index_course_account_associations_on_course_section_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_course_account_associations_on_course_section_id ON public.course_account_associations USING btree (course_section_id);


--
-- Name: index_course_account_associations_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_course_account_associations_replica_identity ON public.course_account_associations USING btree (root_account_id, id);


--
-- Name: index_course_audits_on_unique_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_course_audits_on_unique_uuid ON public.auditor_course_records USING btree (uuid);


--
-- Name: index_course_pace_module_items_on_course_pace_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_course_pace_module_items_on_course_pace_id ON public.course_pace_module_items USING btree (course_pace_id);


--
-- Name: index_course_pace_module_items_on_module_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_course_pace_module_items_on_module_item_id ON public.course_pace_module_items USING btree (module_item_id);


--
-- Name: index_course_pace_module_items_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_course_pace_module_items_replica_identity ON public.course_pace_module_items USING btree (root_account_id, id);


--
-- Name: index_course_paces_on_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_course_paces_on_course_id ON public.course_paces USING btree (course_id);


--
-- Name: index_course_paces_on_course_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_course_paces_on_course_id_and_user_id ON public.course_paces USING btree (course_id, user_id) WHERE ((workflow_state)::text = 'active'::text);


--
-- Name: index_course_paces_on_course_section_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_course_paces_on_course_section_id ON public.course_paces USING btree (course_section_id) WHERE ((workflow_state)::text = 'active'::text);


--
-- Name: index_course_paces_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_course_paces_replica_identity ON public.course_paces USING btree (root_account_id, id);


--
-- Name: index_course_score_statistics_on_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_course_score_statistics_on_course_id ON public.course_score_statistics USING btree (course_id);


--
-- Name: index_course_scores; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_course_scores ON public.scores USING btree (enrollment_id) WHERE course_score;


--
-- Name: index_course_sections_on_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_course_sections_on_course_id ON public.course_sections USING btree (course_id);


--
-- Name: index_course_sections_on_enrollment_term_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_course_sections_on_enrollment_term_id ON public.course_sections USING btree (enrollment_term_id);


--
-- Name: index_course_sections_on_nonxlist_course; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_course_sections_on_nonxlist_course ON public.course_sections USING btree (nonxlist_course_id) WHERE (nonxlist_course_id IS NOT NULL);


--
-- Name: index_course_sections_on_sis_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_course_sections_on_sis_batch_id ON public.course_sections USING btree (sis_batch_id) WHERE (sis_batch_id IS NOT NULL);


--
-- Name: index_course_sections_on_sis_source_id_and_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_course_sections_on_sis_source_id_and_root_account_id ON public.course_sections USING btree (sis_source_id, root_account_id) WHERE (sis_source_id IS NOT NULL);


--
-- Name: index_course_sections_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_course_sections_replica_identity ON public.course_sections USING btree (root_account_id, id);


--
-- Name: index_course_sections_unique_default_section; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_course_sections_unique_default_section ON public.course_sections USING btree (course_id) WHERE ((default_section = true) AND ((workflow_state)::text <> 'deleted'::text));


--
-- Name: index_courses_on_abstract_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_courses_on_abstract_course_id ON public.courses USING btree (abstract_course_id) WHERE (abstract_course_id IS NOT NULL);


--
-- Name: index_courses_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_courses_on_account_id ON public.courses USING btree (account_id);


--
-- Name: index_courses_on_enrollment_term_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_courses_on_enrollment_term_id ON public.courses USING btree (enrollment_term_id);


--
-- Name: index_courses_on_grading_standard; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_courses_on_grading_standard ON public.courses USING btree (grading_standard_id);


--
-- Name: index_courses_on_homeroom_course; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_courses_on_homeroom_course ON public.courses USING btree (homeroom_course) WHERE homeroom_course;


--
-- Name: index_courses_on_homeroom_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_courses_on_homeroom_course_id ON public.courses USING btree (homeroom_course_id) WHERE (homeroom_course_id IS NOT NULL);


--
-- Name: index_courses_on_integration_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_courses_on_integration_id ON public.courses USING btree (integration_id, root_account_id) WHERE (integration_id IS NOT NULL);


--
-- Name: index_courses_on_latest_outcome_import_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_courses_on_latest_outcome_import_id ON public.courses USING btree (latest_outcome_import_id) WHERE (latest_outcome_import_id IS NOT NULL);


--
-- Name: index_courses_on_lti_context_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_courses_on_lti_context_id ON public.courses USING btree (lti_context_id);


--
-- Name: index_courses_on_self_enrollment_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_courses_on_self_enrollment_code ON public.courses USING btree (self_enrollment_code) WHERE (self_enrollment_code IS NOT NULL);


--
-- Name: index_courses_on_sis_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_courses_on_sis_batch_id ON public.courses USING btree (sis_batch_id) WHERE (sis_batch_id IS NOT NULL);


--
-- Name: index_courses_on_sis_source_id_and_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_courses_on_sis_source_id_and_root_account_id ON public.courses USING btree (sis_source_id, root_account_id) WHERE (sis_source_id IS NOT NULL);


--
-- Name: index_courses_on_sync_enrollments_from_homeroom; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_courses_on_sync_enrollments_from_homeroom ON public.courses USING btree (sync_enrollments_from_homeroom) WHERE sync_enrollments_from_homeroom;


--
-- Name: index_courses_on_template_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_courses_on_template_course_id ON public.courses USING btree (template_course_id);


--
-- Name: index_courses_on_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_courses_on_uuid ON public.courses USING btree (uuid);


--
-- Name: index_courses_on_wiki_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_courses_on_wiki_id ON public.courses USING btree (wiki_id) WHERE (wiki_id IS NOT NULL);


--
-- Name: index_courses_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_courses_replica_identity ON public.courses USING btree (root_account_id, id);


--
-- Name: index_cr_assignment_set_actions_on_assignment_set_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cr_assignment_set_actions_on_assignment_set_id ON public.conditional_release_assignment_set_actions USING btree (assignment_set_id) WHERE (deleted_at IS NULL);


--
-- Name: index_cr_assignment_set_actions_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cr_assignment_set_actions_on_root_account_id ON public.conditional_release_assignment_set_actions USING btree (root_account_id);


--
-- Name: index_cr_assignment_set_actions_on_set_and_student; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cr_assignment_set_actions_on_set_and_student ON public.conditional_release_assignment_set_actions USING btree (assignment_set_id, student_id, created_at DESC) WHERE (deleted_at IS NULL);


--
-- Name: index_cr_assignment_set_associations_on_assignment_and_set; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_cr_assignment_set_associations_on_assignment_and_set ON public.conditional_release_assignment_set_associations USING btree (assignment_id, assignment_set_id) WHERE (deleted_at IS NULL);


--
-- Name: index_cr_assignment_set_associations_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cr_assignment_set_associations_on_root_account_id ON public.conditional_release_assignment_set_associations USING btree (root_account_id);


--
-- Name: index_cr_assignment_set_associations_on_set; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cr_assignment_set_associations_on_set ON public.conditional_release_assignment_set_associations USING btree (assignment_id) WHERE (deleted_at IS NULL);


--
-- Name: index_cr_assignment_sets_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cr_assignment_sets_on_root_account_id ON public.conditional_release_assignment_sets USING btree (root_account_id);


--
-- Name: index_cr_assignment_sets_on_scoring_range_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cr_assignment_sets_on_scoring_range_id ON public.conditional_release_assignment_sets USING btree (scoring_range_id) WHERE (deleted_at IS NULL);


--
-- Name: index_cr_rules_on_account_and_course; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cr_rules_on_account_and_course ON public.conditional_release_rules USING btree (root_account_id, course_id) WHERE (deleted_at IS NULL);


--
-- Name: index_cr_rules_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cr_rules_on_root_account_id ON public.conditional_release_rules USING btree (root_account_id);


--
-- Name: index_cr_scoring_ranges_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cr_scoring_ranges_on_root_account_id ON public.conditional_release_scoring_ranges USING btree (root_account_id);


--
-- Name: index_cr_scoring_ranges_on_rule_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cr_scoring_ranges_on_rule_id ON public.conditional_release_scoring_ranges USING btree (rule_id) WHERE (deleted_at IS NULL);


--
-- Name: index_crasa_on_assignment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crasa_on_assignment_id ON public.conditional_release_assignment_set_associations USING btree (assignment_id) WHERE (assignment_id IS NOT NULL);


--
-- Name: index_crasa_on_assignment_set_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crasa_on_assignment_set_id ON public.conditional_release_assignment_set_associations USING btree (assignment_set_id) WHERE (assignment_set_id IS NOT NULL);


--
-- Name: index_crocodoc_documents_on_attachment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crocodoc_documents_on_attachment_id ON public.crocodoc_documents USING btree (attachment_id);


--
-- Name: index_crocodoc_documents_on_process_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crocodoc_documents_on_process_state ON public.crocodoc_documents USING btree (process_state);


--
-- Name: index_crocodoc_documents_on_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crocodoc_documents_on_uuid ON public.crocodoc_documents USING btree (uuid);


--
-- Name: index_csp_domains_on_account_id_and_domain; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_csp_domains_on_account_id_and_domain ON public.csp_domains USING btree (account_id, domain);


--
-- Name: index_csp_domains_on_account_id_and_workflow_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_csp_domains_on_account_id_and_workflow_state ON public.csp_domains USING btree (account_id, workflow_state);


--
-- Name: index_custom_data_on_user_id_and_namespace; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_custom_data_on_user_id_and_namespace ON public.custom_data USING btree (user_id, namespace);


--
-- Name: index_custom_grade_statuses_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_custom_grade_statuses_on_created_by_id ON public.custom_grade_statuses USING btree (created_by_id);


--
-- Name: index_custom_grade_statuses_on_deleted_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_custom_grade_statuses_on_deleted_by_id ON public.custom_grade_statuses USING btree (deleted_by_id);


--
-- Name: index_custom_grade_statuses_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_custom_grade_statuses_replica_identity ON public.custom_grade_statuses USING btree (root_account_id, id);


--
-- Name: index_custom_gradebook_column_data_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_custom_gradebook_column_data_on_root_account_id ON public.custom_gradebook_column_data USING btree (root_account_id);


--
-- Name: index_custom_gradebook_column_data_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_custom_gradebook_column_data_on_user_id ON public.custom_gradebook_column_data USING btree (user_id);


--
-- Name: index_custom_gradebook_column_data_unique_column_and_user; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_custom_gradebook_column_data_unique_column_and_user ON public.custom_gradebook_column_data USING btree (custom_gradebook_column_id, user_id);


--
-- Name: index_custom_gradebook_columns_on_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_custom_gradebook_columns_on_course_id ON public.custom_gradebook_columns USING btree (course_id);


--
-- Name: index_custom_gradebook_columns_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_custom_gradebook_columns_on_root_account_id ON public.custom_gradebook_columns USING btree (root_account_id);


--
-- Name: index_delayed_jobs_on_locked_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delayed_jobs_on_locked_by ON public.delayed_jobs USING btree (locked_by) WHERE (locked_by IS NOT NULL);


--
-- Name: index_delayed_jobs_on_run_at_and_tag; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delayed_jobs_on_run_at_and_tag ON public.delayed_jobs USING btree (run_at, tag);


--
-- Name: index_delayed_jobs_on_shard_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delayed_jobs_on_shard_id ON public.delayed_jobs USING btree (shard_id);


--
-- Name: index_delayed_jobs_on_singleton_not_running; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_delayed_jobs_on_singleton_not_running ON public.delayed_jobs USING btree (singleton) WHERE ((singleton IS NOT NULL) AND ((locked_by IS NULL) OR ((locked_by)::text = 'on hold'::text)));


--
-- Name: index_delayed_jobs_on_singleton_running; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_delayed_jobs_on_singleton_running ON public.delayed_jobs USING btree (singleton) WHERE ((singleton IS NOT NULL) AND (locked_by IS NOT NULL) AND ((locked_by)::text <> 'on hold'::text));


--
-- Name: index_delayed_jobs_on_strand; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delayed_jobs_on_strand ON public.delayed_jobs USING btree (strand, id);


--
-- Name: index_delayed_jobs_on_tag; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delayed_jobs_on_tag ON public.delayed_jobs USING btree (tag);


--
-- Name: index_delayed_messages_on_notification_policy_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delayed_messages_on_notification_policy_id ON public.delayed_messages USING btree (notification_policy_id);


--
-- Name: index_delayed_messages_on_notification_policy_override_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delayed_messages_on_notification_policy_override_id ON public.delayed_messages USING btree (notification_policy_override_id) WHERE (notification_policy_override_id IS NOT NULL);


--
-- Name: index_delayed_messages_pending; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delayed_messages_pending ON public.delayed_messages USING btree (send_at) WHERE ((workflow_state)::text = 'pending'::text);


--
-- Name: index_dev_key_bindings_on_account_id_and_developer_key_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_dev_key_bindings_on_account_id_and_developer_key_id ON public.developer_key_account_bindings USING btree (account_id, developer_key_id);


--
-- Name: index_developer_key_account_bindings_on_developer_key_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_developer_key_account_bindings_on_developer_key_id ON public.developer_key_account_bindings USING btree (developer_key_id);


--
-- Name: index_developer_key_account_bindings_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_developer_key_account_bindings_replica_identity ON public.developer_key_account_bindings USING btree (root_account_id, id);


--
-- Name: index_developer_keys_on_service_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_developer_keys_on_service_user_id ON public.developer_keys USING btree (service_user_id) WHERE (service_user_id IS NOT NULL);


--
-- Name: index_developer_keys_on_vendor_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_developer_keys_on_vendor_code ON public.developer_keys USING btree (vendor_code);


--
-- Name: index_developer_keys_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_developer_keys_replica_identity ON public.developer_keys USING btree (root_account_id, id);


--
-- Name: index_discussion_entries_active_on_user_id_and_topic; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_entries_active_on_user_id_and_topic ON public.discussion_entries USING btree (user_id, discussion_topic_id) WHERE ((workflow_state)::text <> 'deleted'::text);


--
-- Name: index_discussion_entries_for_topic; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_entries_for_topic ON public.discussion_entries USING btree (discussion_topic_id, updated_at, created_at);


--
-- Name: index_discussion_entries_on_editor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_entries_on_editor_id ON public.discussion_entries USING btree (editor_id) WHERE (editor_id IS NOT NULL);


--
-- Name: index_discussion_entries_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_entries_on_parent_id ON public.discussion_entries USING btree (parent_id);


--
-- Name: index_discussion_entries_on_quoted_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_entries_on_quoted_entry_id ON public.discussion_entries USING btree (quoted_entry_id);


--
-- Name: index_discussion_entries_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_entries_on_user_id ON public.discussion_entries USING btree (user_id);


--
-- Name: index_discussion_entries_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_discussion_entries_replica_identity ON public.discussion_entries USING btree (root_account_id, id);


--
-- Name: index_discussion_entries_root_entry; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_entries_root_entry ON public.discussion_entries USING btree (root_entry_id, workflow_state, created_at);


--
-- Name: index_discussion_entry_drafts_on_attachment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_entry_drafts_on_attachment_id ON public.discussion_entry_drafts USING btree (attachment_id);


--
-- Name: index_discussion_entry_drafts_on_discussion_topic_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_entry_drafts_on_discussion_topic_id ON public.discussion_entry_drafts USING btree (discussion_topic_id);


--
-- Name: index_discussion_entry_drafts_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_entry_drafts_on_parent_id ON public.discussion_entry_drafts USING btree (parent_id);


--
-- Name: index_discussion_entry_drafts_on_root_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_entry_drafts_on_root_entry_id ON public.discussion_entry_drafts USING btree (root_entry_id);


--
-- Name: index_discussion_entry_drafts_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_entry_drafts_on_user_id ON public.discussion_entry_drafts USING btree (user_id);


--
-- Name: index_discussion_entry_participants_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_entry_participants_on_user_id ON public.discussion_entry_participants USING btree (user_id);


--
-- Name: index_discussion_entry_participants_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_discussion_entry_participants_replica_identity ON public.discussion_entry_participants USING btree (root_account_id, id);


--
-- Name: index_discussion_entry_versions_on_discussion_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_entry_versions_on_discussion_entry_id ON public.discussion_entry_versions USING btree (discussion_entry_id);


--
-- Name: index_discussion_entry_versions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_entry_versions_on_user_id ON public.discussion_entry_versions USING btree (user_id);


--
-- Name: index_discussion_entry_versions_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_discussion_entry_versions_replica_identity ON public.discussion_entry_versions USING btree (root_account_id, id);


--
-- Name: index_discussion_topic_participants_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_topic_participants_on_user_id ON public.discussion_topic_participants USING btree (user_id);


--
-- Name: index_discussion_topic_participants_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_discussion_topic_participants_replica_identity ON public.discussion_topic_participants USING btree (root_account_id, id);


--
-- Name: index_discussion_topics_on_assignment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_topics_on_assignment_id ON public.discussion_topics USING btree (assignment_id);


--
-- Name: index_discussion_topics_on_attachment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_topics_on_attachment_id ON public.discussion_topics USING btree (attachment_id) WHERE (attachment_id IS NOT NULL);


--
-- Name: index_discussion_topics_on_cloned_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_topics_on_cloned_item_id ON public.discussion_topics USING btree (cloned_item_id) WHERE (cloned_item_id IS NOT NULL);


--
-- Name: index_discussion_topics_on_context_and_last_reply_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_topics_on_context_and_last_reply_at ON public.discussion_topics USING btree (context_id, last_reply_at);


--
-- Name: index_discussion_topics_on_context_id_and_position; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_topics_on_context_id_and_position ON public.discussion_topics USING btree (context_id, "position");


--
-- Name: index_discussion_topics_on_editor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_topics_on_editor_id ON public.discussion_topics USING btree (editor_id) WHERE (editor_id IS NOT NULL);


--
-- Name: index_discussion_topics_on_external_feed_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_topics_on_external_feed_id ON public.discussion_topics USING btree (external_feed_id) WHERE (external_feed_id IS NOT NULL);


--
-- Name: index_discussion_topics_on_group_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_topics_on_group_category_id ON public.discussion_topics USING btree (group_category_id) WHERE (group_category_id IS NOT NULL);


--
-- Name: index_discussion_topics_on_id_and_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_topics_on_id_and_type ON public.discussion_topics USING btree (id, type);


--
-- Name: index_discussion_topics_on_old_assignment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_topics_on_old_assignment_id ON public.discussion_topics USING btree (old_assignment_id) WHERE (old_assignment_id IS NOT NULL);


--
-- Name: index_discussion_topics_on_root_topic_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_topics_on_root_topic_id ON public.discussion_topics USING btree (root_topic_id);


--
-- Name: index_discussion_topics_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_topics_on_user_id ON public.discussion_topics USING btree (user_id);


--
-- Name: index_discussion_topics_on_workflow_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_topics_on_workflow_state ON public.discussion_topics USING btree (workflow_state);


--
-- Name: index_discussion_topics_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_discussion_topics_replica_identity ON public.discussion_topics USING btree (root_account_id, id);


--
-- Name: index_discussion_topics_unique_subtopic_per_context; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_discussion_topics_unique_subtopic_per_context ON public.discussion_topics USING btree (context_id, context_type, root_topic_id);


--
-- Name: index_enrollment_dates_overrides_on_enrollment_term_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_enrollment_dates_overrides_on_enrollment_term_id ON public.enrollment_dates_overrides USING btree (enrollment_term_id);


--
-- Name: index_enrollment_dates_overrides_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_enrollment_dates_overrides_on_root_account_id ON public.enrollment_dates_overrides USING btree (root_account_id);


--
-- Name: index_enrollment_dates_overrides_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_enrollment_dates_overrides_replica_identity ON public.enrollment_dates_overrides USING btree (context_id, id);


--
-- Name: index_enrollment_scores; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_enrollment_scores ON public.scores USING btree (enrollment_id);


--
-- Name: index_enrollment_states_on_currents; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_enrollment_states_on_currents ON public.enrollment_states USING btree (state_is_current, access_is_current);


--
-- Name: index_enrollment_states_on_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_enrollment_states_on_state ON public.enrollment_states USING btree (state);


--
-- Name: index_enrollment_states_on_state_valid_until; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_enrollment_states_on_state_valid_until ON public.enrollment_states USING btree (state_valid_until);


--
-- Name: index_enrollment_states_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_enrollment_states_replica_identity ON public.enrollment_states USING btree (root_account_id, enrollment_id);


--
-- Name: index_enrollment_terms_on_grading_period_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_enrollment_terms_on_grading_period_group_id ON public.enrollment_terms USING btree (grading_period_group_id);


--
-- Name: index_enrollment_terms_on_sis_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_enrollment_terms_on_sis_batch_id ON public.enrollment_terms USING btree (sis_batch_id) WHERE (sis_batch_id IS NOT NULL);


--
-- Name: index_enrollment_terms_on_sis_source_id_and_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_enrollment_terms_on_sis_source_id_and_root_account_id ON public.enrollment_terms USING btree (sis_source_id, root_account_id) WHERE (sis_source_id IS NOT NULL);


--
-- Name: index_enrollment_terms_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_enrollment_terms_replica_identity ON public.enrollment_terms USING btree (root_account_id, id);


--
-- Name: index_enrollments_on_associated_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_enrollments_on_associated_user_id ON public.enrollments USING btree (associated_user_id) WHERE (associated_user_id IS NOT NULL);


--
-- Name: index_enrollments_on_course_id_and_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_enrollments_on_course_id_and_id ON public.enrollments USING btree (course_id, id);


--
-- Name: index_enrollments_on_course_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_enrollments_on_course_id_and_user_id ON public.enrollments USING btree (course_id, user_id);


--
-- Name: index_enrollments_on_course_id_and_workflow_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_enrollments_on_course_id_and_workflow_state ON public.enrollments USING btree (course_id, workflow_state);


--
-- Name: index_enrollments_on_course_section_id_and_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_enrollments_on_course_section_id_and_id ON public.enrollments USING btree (course_section_id, id);


--
-- Name: index_enrollments_on_course_when_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_enrollments_on_course_when_active ON public.enrollments USING btree (course_id) WHERE ((workflow_state)::text = 'active'::text);


--
-- Name: index_enrollments_on_role_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_enrollments_on_role_id_and_user_id ON public.enrollments USING btree (role_id, user_id);


--
-- Name: index_enrollments_on_root_account_id_and_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_enrollments_on_root_account_id_and_course_id ON public.enrollments USING btree (root_account_id, course_id);


--
-- Name: index_enrollments_on_sis_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_enrollments_on_sis_batch_id ON public.enrollments USING btree (sis_batch_id) WHERE (sis_batch_id IS NOT NULL);


--
-- Name: index_enrollments_on_sis_pseudonym_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_enrollments_on_sis_pseudonym_id ON public.enrollments USING btree (sis_pseudonym_id);


--
-- Name: index_enrollments_on_temp_enrollment_user_type_role_section; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_enrollments_on_temp_enrollment_user_type_role_section ON public.enrollments USING btree (temporary_enrollment_source_user_id, user_id, type, role_id, course_section_id) WHERE (temporary_enrollment_source_user_id IS NOT NULL);


--
-- Name: index_enrollments_on_temporary_enrollment_pairing_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_enrollments_on_temporary_enrollment_pairing_id ON public.enrollments USING btree (temporary_enrollment_pairing_id) WHERE (temporary_enrollment_pairing_id IS NOT NULL);


--
-- Name: index_enrollments_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_enrollments_on_user_id ON public.enrollments USING btree (user_id);


--
-- Name: index_enrollments_on_user_type_role_section; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_enrollments_on_user_type_role_section ON public.enrollments USING btree (user_id, type, role_id, course_section_id) WHERE (associated_user_id IS NULL);


--
-- Name: index_enrollments_on_user_type_role_section_associated_user; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_enrollments_on_user_type_role_section_associated_user ON public.enrollments USING btree (user_id, type, role_id, course_section_id, associated_user_id) WHERE (associated_user_id IS NOT NULL);


--
-- Name: index_enrollments_on_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_enrollments_on_uuid ON public.enrollments USING btree (uuid);


--
-- Name: index_enrollments_on_workflow_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_enrollments_on_workflow_state ON public.enrollments USING btree (workflow_state);


--
-- Name: index_enrollments_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_enrollments_replica_identity ON public.enrollments USING btree (root_account_id, id);


--
-- Name: index_entry_participant_on_entry_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_entry_participant_on_entry_id_and_user_id ON public.discussion_entry_participants USING btree (discussion_entry_id, user_id);


--
-- Name: index_eportfolio_categories_on_eportfolio_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_eportfolio_categories_on_eportfolio_id ON public.eportfolio_categories USING btree (eportfolio_id);


--
-- Name: index_eportfolio_entries_on_eportfolio_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_eportfolio_entries_on_eportfolio_category_id ON public.eportfolio_entries USING btree (eportfolio_category_id);


--
-- Name: index_eportfolio_entries_on_eportfolio_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_eportfolio_entries_on_eportfolio_id ON public.eportfolio_entries USING btree (eportfolio_id);


--
-- Name: index_eportfolios_on_spam_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_eportfolios_on_spam_status ON public.eportfolios USING btree (spam_status);


--
-- Name: index_eportfolios_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_eportfolios_on_user_id ON public.eportfolios USING btree (user_id);


--
-- Name: index_epub_exports_on_content_export_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_epub_exports_on_content_export_id ON public.epub_exports USING btree (content_export_id);


--
-- Name: index_epub_exports_on_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_epub_exports_on_course_id ON public.epub_exports USING btree (course_id);


--
-- Name: index_epub_exports_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_epub_exports_on_user_id ON public.epub_exports USING btree (user_id);


--
-- Name: index_error_reports_on_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_error_reports_on_category ON public.error_reports USING btree (category);


--
-- Name: index_error_reports_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_error_reports_on_user_id ON public.error_reports USING btree (user_id) WHERE (user_id IS NOT NULL);


--
-- Name: index_error_reports_on_zendesk_ticket_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_error_reports_on_zendesk_ticket_id ON public.error_reports USING btree (zendesk_ticket_id);


--
-- Name: index_external_feed_entries_on_external_feed_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_external_feed_entries_on_external_feed_id ON public.external_feed_entries USING btree (external_feed_id);


--
-- Name: index_external_feed_entries_on_url; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_external_feed_entries_on_url ON public.external_feed_entries USING btree (url);


--
-- Name: index_external_feed_entries_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_external_feed_entries_on_user_id ON public.external_feed_entries USING btree (user_id) WHERE (user_id IS NOT NULL);


--
-- Name: index_external_feed_entries_on_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_external_feed_entries_on_uuid ON public.external_feed_entries USING btree (uuid);


--
-- Name: index_external_feeds_on_context_id_and_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_external_feeds_on_context_id_and_context_type ON public.external_feeds USING btree (context_id, context_type);


--
-- Name: index_external_feeds_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_external_feeds_on_user_id ON public.external_feeds USING btree (user_id) WHERE (user_id IS NOT NULL);


--
-- Name: index_external_feeds_uniquely_1; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_external_feeds_uniquely_1 ON public.external_feeds USING btree (context_id, context_type, url, verbosity) WHERE (header_match IS NULL);


--
-- Name: index_external_feeds_uniquely_2; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_external_feeds_uniquely_2 ON public.external_feeds USING btree (context_id, context_type, url, header_match, verbosity) WHERE (header_match IS NOT NULL);


--
-- Name: index_external_integration_keys_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_external_integration_keys_unique ON public.external_integration_keys USING btree (context_id, context_type, key_type);


--
-- Name: index_external_tools_on_context_and_migration_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_external_tools_on_context_and_migration_id ON public.context_external_tools USING btree (context_id, context_type, migration_id) WHERE (migration_id IS NOT NULL);


--
-- Name: index_failed_jobs_on_failed_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_failed_jobs_on_failed_at ON public.failed_jobs USING btree (failed_at);


--
-- Name: index_failed_jobs_on_shard_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_failed_jobs_on_shard_id ON public.failed_jobs USING btree (shard_id);


--
-- Name: index_failed_jobs_on_singleton; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_failed_jobs_on_singleton ON public.failed_jobs USING btree (singleton) WHERE (singleton IS NOT NULL);


--
-- Name: index_failed_jobs_on_strand; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_failed_jobs_on_strand ON public.failed_jobs USING btree (strand) WHERE (strand IS NOT NULL);


--
-- Name: index_failed_jobs_on_tag; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_failed_jobs_on_tag ON public.failed_jobs USING btree (tag);


--
-- Name: index_favorites_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_favorites_replica_identity ON public.favorites USING btree (root_account_id, id);


--
-- Name: index_favorites_unique_user_object; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_favorites_unique_user_object ON public.favorites USING btree (user_id, context_id, context_type);


--
-- Name: index_feature_flags_on_context_and_feature; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_feature_flags_on_context_and_feature ON public.feature_flags USING btree (context_id, context_type, feature);


--
-- Name: index_folders_on_cloned_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_folders_on_cloned_item_id ON public.folders USING btree (cloned_item_id);


--
-- Name: index_folders_on_context_id_and_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_folders_on_context_id_and_context_type ON public.folders USING btree (context_id, context_type);


--
-- Name: index_folders_on_context_id_and_context_type_for_root_folders; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_folders_on_context_id_and_context_type_for_root_folders ON public.folders USING btree (context_id, context_type) WHERE ((parent_folder_id IS NULL) AND ((workflow_state)::text <> 'deleted'::text));


--
-- Name: index_folders_on_parent_folder_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_folders_on_parent_folder_id ON public.folders USING btree (parent_folder_id);


--
-- Name: index_folders_on_submission_context_code_and_parent_folder_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_folders_on_submission_context_code_and_parent_folder_id ON public.folders USING btree (submission_context_code, parent_folder_id);


--
-- Name: index_folders_on_unique_type_and_context_id_and_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_folders_on_unique_type_and_context_id_and_context_type ON public.folders USING btree (unique_type, context_id, context_type) WHERE ((unique_type IS NOT NULL) AND ((workflow_state)::text <> 'deleted'::text));


--
-- Name: index_folders_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_folders_replica_identity ON public.folders USING btree (root_account_id, id);


--
-- Name: index_generated_quiz_questions; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_generated_quiz_questions ON public.quiz_questions USING btree (assessment_question_id, quiz_group_id, duplicate_index) WHERE ((assessment_question_id IS NOT NULL) AND (quiz_group_id IS NOT NULL) AND ((workflow_state)::text = 'generated'::text));


--
-- Name: index_gin_trgm_communication_channels_path; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gin_trgm_communication_channels_path ON public.communication_channels USING gin (lower((path)::text) public.gin_trgm_ops);


--
-- Name: index_gin_trgm_courses_composite_search; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gin_trgm_courses_composite_search ON public.courses USING gin ((((((COALESCE(lower((name)::text), ''::text) || ' '::text) || COALESCE(lower((sis_source_id)::text), ''::text)) || ' '::text) || COALESCE(lower((course_code)::text), ''::text))) public.gin_trgm_ops);


--
-- Name: index_gin_trgm_discussion_topics_title; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gin_trgm_discussion_topics_title ON public.discussion_topics USING gin (lower((title)::text) public.gin_trgm_ops);


--
-- Name: index_gin_trgm_pseudonyms_sis_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gin_trgm_pseudonyms_sis_user_id ON public.pseudonyms USING gin (lower((sis_user_id)::text) public.gin_trgm_ops);


--
-- Name: index_gin_trgm_pseudonyms_unique_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gin_trgm_pseudonyms_unique_id ON public.pseudonyms USING gin (lower((unique_id)::text) public.gin_trgm_ops);


--
-- Name: index_gin_trgm_users_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gin_trgm_users_name ON public.users USING gin (lower((name)::text) public.gin_trgm_ops);


--
-- Name: index_gin_trgm_users_name_active_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gin_trgm_users_name_active_only ON public.users USING gin (lower((name)::text) public.gin_trgm_ops) WHERE ((workflow_state)::text = ANY ((ARRAY['registered'::character varying, 'pre_registered'::character varying])::text[]));


--
-- Name: index_gin_trgm_users_short_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gin_trgm_users_short_name ON public.users USING gin (lower((short_name)::text) public.gin_trgm_ops);


--
-- Name: index_grade_audits_on_unique_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_grade_audits_on_unique_uuid ON public.auditor_grade_change_records USING btree (uuid);


--
-- Name: index_gradebook_csvs_on_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gradebook_csvs_on_course_id ON public.gradebook_csvs USING btree (course_id);


--
-- Name: index_gradebook_csvs_on_progress_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gradebook_csvs_on_progress_id ON public.gradebook_csvs USING btree (progress_id);


--
-- Name: index_gradebook_csvs_on_user_id_and_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gradebook_csvs_on_user_id_and_course_id ON public.gradebook_csvs USING btree (user_id, course_id);


--
-- Name: index_gradebook_filters_on_course_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gradebook_filters_on_course_id_and_user_id ON public.gradebook_filters USING btree (course_id, user_id);


--
-- Name: index_gradebook_filters_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gradebook_filters_on_user_id ON public.gradebook_filters USING btree (user_id);


--
-- Name: index_gradebook_uploads_on_course_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_gradebook_uploads_on_course_id_and_user_id ON public.gradebook_uploads USING btree (course_id, user_id);


--
-- Name: index_gradebook_uploads_on_progress_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gradebook_uploads_on_progress_id ON public.gradebook_uploads USING btree (progress_id);


--
-- Name: index_gradebook_uploads_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gradebook_uploads_on_user_id ON public.gradebook_uploads USING btree (user_id);


--
-- Name: index_graded_submissions_on_assignments; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_graded_submissions_on_assignments ON public.submissions USING btree (assignment_id) WHERE ((workflow_state)::text = 'graded'::text);


--
-- Name: index_grading_period_groups_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_grading_period_groups_on_account_id ON public.grading_period_groups USING btree (account_id);


--
-- Name: index_grading_period_groups_on_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_grading_period_groups_on_course_id ON public.grading_period_groups USING btree (course_id);


--
-- Name: index_grading_period_groups_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_grading_period_groups_on_root_account_id ON public.grading_period_groups USING btree (root_account_id) WHERE (root_account_id IS NOT NULL);


--
-- Name: index_grading_period_groups_on_workflow_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_grading_period_groups_on_workflow_state ON public.grading_period_groups USING btree (workflow_state);


--
-- Name: index_grading_period_scores; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_grading_period_scores ON public.scores USING btree (enrollment_id, grading_period_id) WHERE (grading_period_id IS NOT NULL);


--
-- Name: index_grading_periods_on_grading_period_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_grading_periods_on_grading_period_group_id ON public.grading_periods USING btree (grading_period_group_id);


--
-- Name: index_grading_periods_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_grading_periods_on_root_account_id ON public.grading_periods USING btree (root_account_id);


--
-- Name: index_grading_periods_on_workflow_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_grading_periods_on_workflow_state ON public.grading_periods USING btree (workflow_state);


--
-- Name: index_grading_standards_on_context_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_grading_standards_on_context_code ON public.grading_standards USING btree (context_code);


--
-- Name: index_grading_standards_on_context_id_and_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_grading_standards_on_context_id_and_context_type ON public.grading_standards USING btree (context_id, context_type);


--
-- Name: index_grading_standards_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_grading_standards_on_root_account_id ON public.grading_standards USING btree (root_account_id);


--
-- Name: index_grading_standards_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_grading_standards_on_user_id ON public.grading_standards USING btree (user_id) WHERE (user_id IS NOT NULL);


--
-- Name: index_group_and_membership_importers_on_attachment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_group_and_membership_importers_on_attachment_id ON public.group_and_membership_importers USING btree (attachment_id) WHERE (attachment_id IS NOT NULL);


--
-- Name: index_group_and_membership_importers_on_group_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_group_and_membership_importers_on_group_category_id ON public.group_and_membership_importers USING btree (group_category_id);


--
-- Name: index_group_categories_on_context; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_group_categories_on_context ON public.group_categories USING btree (context_id, context_type);


--
-- Name: index_group_categories_on_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_group_categories_on_role ON public.group_categories USING btree (role);


--
-- Name: index_group_categories_on_root_account_id_and_sis_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_group_categories_on_root_account_id_and_sis_source_id ON public.group_categories USING btree (root_account_id, sis_source_id) WHERE (sis_source_id IS NOT NULL);


--
-- Name: index_group_categories_on_sis_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_group_categories_on_sis_batch_id ON public.group_categories USING btree (sis_batch_id);


--
-- Name: index_group_categories_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_group_categories_replica_identity ON public.group_categories USING btree (root_account_id, id);


--
-- Name: index_group_memberships_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_group_memberships_on_group_id ON public.group_memberships USING btree (group_id);


--
-- Name: index_group_memberships_on_group_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_group_memberships_on_group_id_and_user_id ON public.group_memberships USING btree (group_id, user_id) WHERE ((workflow_state)::text <> 'deleted'::text);


--
-- Name: index_group_memberships_on_sis_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_group_memberships_on_sis_batch_id ON public.group_memberships USING btree (sis_batch_id) WHERE (sis_batch_id IS NOT NULL);


--
-- Name: index_group_memberships_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_group_memberships_on_user_id ON public.group_memberships USING btree (user_id);


--
-- Name: index_group_memberships_on_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_group_memberships_on_uuid ON public.group_memberships USING btree (uuid);


--
-- Name: index_group_memberships_on_workflow_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_group_memberships_on_workflow_state ON public.group_memberships USING btree (workflow_state);


--
-- Name: index_group_memberships_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_group_memberships_replica_identity ON public.group_memberships USING btree (root_account_id, id);


--
-- Name: index_groups_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_groups_on_account_id ON public.groups USING btree (account_id);


--
-- Name: index_groups_on_context_id_and_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_groups_on_context_id_and_context_type ON public.groups USING btree (context_id, context_type);


--
-- Name: index_groups_on_group_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_groups_on_group_category_id ON public.groups USING btree (group_category_id);


--
-- Name: index_groups_on_leader_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_groups_on_leader_id ON public.groups USING btree (leader_id) WHERE (leader_id IS NOT NULL);


--
-- Name: index_groups_on_sis_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_groups_on_sis_batch_id ON public.groups USING btree (sis_batch_id) WHERE (sis_batch_id IS NOT NULL);


--
-- Name: index_groups_on_sis_source_id_and_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_groups_on_sis_source_id_and_root_account_id ON public.groups USING btree (sis_source_id, root_account_id) WHERE (sis_source_id IS NOT NULL);


--
-- Name: index_groups_on_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_groups_on_uuid ON public.groups USING btree (uuid);


--
-- Name: index_groups_on_wiki_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_groups_on_wiki_id ON public.groups USING btree (wiki_id) WHERE (wiki_id IS NOT NULL);


--
-- Name: index_groups_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_groups_replica_identity ON public.groups USING btree (root_account_id, id);


--
-- Name: index_ignores_on_asset_and_user_id_and_purpose; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ignores_on_asset_and_user_id_and_purpose ON public.ignores USING btree (asset_id, asset_type, user_id, purpose);


--
-- Name: index_ignores_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ignores_on_user_id ON public.ignores USING btree (user_id);


--
-- Name: index_late_policies_on_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_late_policies_on_course_id ON public.late_policies USING btree (course_id);


--
-- Name: index_late_policies_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_late_policies_on_root_account_id ON public.late_policies USING btree (root_account_id);


--
-- Name: index_learning_outcome_groups_on_context_and_vendor_guid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_learning_outcome_groups_on_context_and_vendor_guid ON public.learning_outcome_groups USING btree (context_type, context_id, vendor_guid_2);


--
-- Name: index_learning_outcome_groups_on_context_id_and_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_learning_outcome_groups_on_context_id_and_context_type ON public.learning_outcome_groups USING btree (context_id, context_type);


--
-- Name: index_learning_outcome_groups_on_learning_outcome_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_learning_outcome_groups_on_learning_outcome_group_id ON public.learning_outcome_groups USING btree (learning_outcome_group_id) WHERE (learning_outcome_group_id IS NOT NULL);


--
-- Name: index_learning_outcome_groups_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_learning_outcome_groups_on_root_account_id ON public.learning_outcome_groups USING btree (root_account_id);


--
-- Name: index_learning_outcome_groups_on_root_learning_outcome_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_learning_outcome_groups_on_root_learning_outcome_group_id ON public.learning_outcome_groups USING btree (root_learning_outcome_group_id) WHERE (root_learning_outcome_group_id IS NOT NULL);


--
-- Name: index_learning_outcome_groups_on_source_outcome_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_learning_outcome_groups_on_source_outcome_group_id ON public.learning_outcome_groups USING btree (source_outcome_group_id) WHERE (source_outcome_group_id IS NOT NULL);


--
-- Name: index_learning_outcome_groups_on_vendor_guid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_learning_outcome_groups_on_vendor_guid ON public.learning_outcome_groups USING btree (vendor_guid);


--
-- Name: index_learning_outcome_groups_on_vendor_guid_2; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_learning_outcome_groups_on_vendor_guid_2 ON public.learning_outcome_groups USING btree (vendor_guid_2);


--
-- Name: index_learning_outcome_question_results_on_learning_outcome_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_learning_outcome_question_results_on_learning_outcome_id ON public.learning_outcome_question_results USING btree (learning_outcome_id);


--
-- Name: index_learning_outcome_question_results_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_learning_outcome_question_results_on_root_account_id ON public.learning_outcome_question_results USING btree (root_account_id);


--
-- Name: index_learning_outcome_results_association; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_learning_outcome_results_association ON public.learning_outcome_results USING btree (user_id, content_tag_id, association_id, association_type, associated_asset_id, associated_asset_type);


--
-- Name: index_learning_outcome_results_on_content_tag_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_learning_outcome_results_on_content_tag_id ON public.learning_outcome_results USING btree (content_tag_id);


--
-- Name: index_learning_outcome_results_on_learning_outcome_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_learning_outcome_results_on_learning_outcome_id ON public.learning_outcome_results USING btree (learning_outcome_id) WHERE (learning_outcome_id IS NOT NULL);


--
-- Name: index_learning_outcome_results_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_learning_outcome_results_on_root_account_id ON public.learning_outcome_results USING btree (root_account_id);


--
-- Name: index_learning_outcomes_on_context_id_and_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_learning_outcomes_on_context_id_and_context_type ON public.learning_outcomes USING btree (context_id, context_type);


--
-- Name: index_learning_outcomes_on_copied_from_outcome_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_learning_outcomes_on_copied_from_outcome_id ON public.learning_outcomes USING btree (copied_from_outcome_id) WHERE (copied_from_outcome_id IS NOT NULL);


--
-- Name: index_learning_outcomes_on_root_account_ids; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_learning_outcomes_on_root_account_ids ON public.learning_outcomes USING gin (root_account_ids);


--
-- Name: index_learning_outcomes_on_vendor_guid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_learning_outcomes_on_vendor_guid ON public.learning_outcomes USING btree (vendor_guid);


--
-- Name: index_learning_outcomes_on_vendor_guid_2; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_learning_outcomes_on_vendor_guid_2 ON public.learning_outcomes USING btree (vendor_guid_2);


--
-- Name: index_live_assessments; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_live_assessments ON public.live_assessments_assessments USING btree (context_id, context_type, key);


--
-- Name: index_live_assessments_results_on_assessment_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_live_assessments_results_on_assessment_id_and_user_id ON public.live_assessments_results USING btree (assessment_id, user_id);


--
-- Name: index_live_assessments_results_on_assessor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_live_assessments_results_on_assessor_id ON public.live_assessments_results USING btree (assessor_id);


--
-- Name: index_live_assessments_results_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_live_assessments_results_on_user_id ON public.live_assessments_results USING btree (user_id);


--
-- Name: index_live_assessments_submissions_on_assessment_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_live_assessments_submissions_on_assessment_id_and_user_id ON public.live_assessments_submissions USING btree (assessment_id, user_id);


--
-- Name: index_live_assessments_submissions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_live_assessments_submissions_on_user_id ON public.live_assessments_submissions USING btree (user_id);


--
-- Name: index_lti_ims_registrations_on_developer_key_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lti_ims_registrations_on_developer_key_id ON public.lti_ims_registrations USING btree (developer_key_id);


--
-- Name: index_lti_ims_registrations_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_lti_ims_registrations_replica_identity ON public.lti_ims_registrations USING btree (root_account_id, id);


--
-- Name: index_lti_line_items_on_assignment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lti_line_items_on_assignment_id ON public.lti_line_items USING btree (assignment_id);


--
-- Name: index_lti_line_items_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lti_line_items_on_client_id ON public.lti_line_items USING btree (client_id);


--
-- Name: index_lti_line_items_on_lti_resource_link_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lti_line_items_on_lti_resource_link_id ON public.lti_line_items USING btree (lti_resource_link_id);


--
-- Name: index_lti_line_items_on_resource_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lti_line_items_on_resource_id ON public.lti_line_items USING btree (resource_id);


--
-- Name: index_lti_line_items_on_tag; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lti_line_items_on_tag ON public.lti_line_items USING btree (tag);


--
-- Name: index_lti_line_items_on_workflow_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lti_line_items_on_workflow_state ON public.lti_line_items USING btree (workflow_state);


--
-- Name: index_lti_line_items_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_lti_line_items_replica_identity ON public.lti_line_items USING btree (root_account_id, id);


--
-- Name: index_lti_links_on_linkable_id_and_linkable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lti_links_on_linkable_id_and_linkable_type ON public.lti_links USING btree (linkable_id, linkable_type);


--
-- Name: index_lti_links_on_resource_link_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_lti_links_on_resource_link_id ON public.lti_links USING btree (resource_link_id);


--
-- Name: index_lti_message_handlers_on_resource_handler_and_type; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_lti_message_handlers_on_resource_handler_and_type ON public.lti_message_handlers USING btree (resource_handler_id, message_type);


--
-- Name: index_lti_message_handlers_on_tool_proxy_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lti_message_handlers_on_tool_proxy_id ON public.lti_message_handlers USING btree (tool_proxy_id);


--
-- Name: index_lti_product_families_on_developer_key_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lti_product_families_on_developer_key_id ON public.lti_product_families USING btree (developer_key_id);


--
-- Name: index_lti_product_families_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lti_product_families_on_root_account_id ON public.lti_product_families USING btree (root_account_id);


--
-- Name: index_lti_resource_handlers_on_tool_proxy_and_type_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_lti_resource_handlers_on_tool_proxy_and_type_code ON public.lti_resource_handlers USING btree (tool_proxy_id, resource_type_code);


--
-- Name: index_lti_resource_links_by_context_id_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lti_resource_links_by_context_id_context_type ON public.lti_resource_links USING btree (context_id, context_type);


--
-- Name: index_lti_resource_links_on_context_external_tool_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lti_resource_links_on_context_external_tool_id ON public.lti_resource_links USING btree (context_external_tool_id);


--
-- Name: index_lti_resource_links_on_resource_link_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_lti_resource_links_on_resource_link_uuid ON public.lti_resource_links USING btree (resource_link_uuid);


--
-- Name: index_lti_resource_links_on_workflow_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lti_resource_links_on_workflow_state ON public.lti_resource_links USING btree (workflow_state);


--
-- Name: index_lti_resource_links_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_lti_resource_links_replica_identity ON public.lti_resource_links USING btree (root_account_id, id);


--
-- Name: index_lti_resource_links_unique_lookup_uuid_on_context; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_lti_resource_links_unique_lookup_uuid_on_context ON public.lti_resource_links USING btree (lookup_uuid, context_id, context_type);


--
-- Name: index_lti_resource_placements_on_message_handler_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lti_resource_placements_on_message_handler_id ON public.lti_resource_placements USING btree (message_handler_id) WHERE (message_handler_id IS NOT NULL);


--
-- Name: index_lti_results_on_lti_line_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lti_results_on_lti_line_item_id ON public.lti_results USING btree (lti_line_item_id);


--
-- Name: index_lti_results_on_lti_line_item_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_lti_results_on_lti_line_item_id_and_user_id ON public.lti_results USING btree (lti_line_item_id, user_id);


--
-- Name: index_lti_results_on_submission_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lti_results_on_submission_id ON public.lti_results USING btree (submission_id);


--
-- Name: index_lti_results_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lti_results_on_user_id ON public.lti_results USING btree (user_id);


--
-- Name: index_lti_results_on_workflow_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lti_results_on_workflow_state ON public.lti_results USING btree (workflow_state);


--
-- Name: index_lti_results_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_lti_results_replica_identity ON public.lti_results USING btree (root_account_id, id);


--
-- Name: index_lti_tool_configurations_on_developer_key_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_lti_tool_configurations_on_developer_key_id ON public.lti_tool_configurations USING btree (developer_key_id);


--
-- Name: index_lti_tool_consumer_profiles_on_developer_key_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_lti_tool_consumer_profiles_on_developer_key_id ON public.lti_tool_consumer_profiles USING btree (developer_key_id);


--
-- Name: index_lti_tool_consumer_profiles_on_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_lti_tool_consumer_profiles_on_uuid ON public.lti_tool_consumer_profiles USING btree (uuid);


--
-- Name: index_lti_tool_proxies_on_guid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lti_tool_proxies_on_guid ON public.lti_tool_proxies USING btree (guid);


--
-- Name: index_lti_tool_proxies_on_product_family_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lti_tool_proxies_on_product_family_id ON public.lti_tool_proxies USING btree (product_family_id);


--
-- Name: index_lti_tool_proxy_bindings_on_context_and_tool_proxy; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_lti_tool_proxy_bindings_on_context_and_tool_proxy ON public.lti_tool_proxy_bindings USING btree (context_id, context_type, tool_proxy_id);


--
-- Name: index_lti_tool_proxy_bindings_on_tool_proxy_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lti_tool_proxy_bindings_on_tool_proxy_id ON public.lti_tool_proxy_bindings USING btree (tool_proxy_id);


--
-- Name: index_lti_tool_settings_on_link_context_and_tool_proxy; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_lti_tool_settings_on_link_context_and_tool_proxy ON public.lti_tool_settings USING btree (resource_link_id, context_type, context_id, tool_proxy_id);


--
-- Name: index_master_content_tags_on_current_migration_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_master_content_tags_on_current_migration_id ON public.master_courses_master_content_tags USING btree (current_migration_id) WHERE (current_migration_id IS NOT NULL);


--
-- Name: index_master_content_tags_on_migration_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_master_content_tags_on_migration_id ON public.master_courses_master_content_tags USING btree (migration_id);


--
-- Name: index_master_content_tags_on_template_id_and_content; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_master_content_tags_on_template_id_and_content ON public.master_courses_master_content_tags USING btree (master_template_id, content_type, content_id);


--
-- Name: index_master_courses_child_content_tags_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_master_courses_child_content_tags_on_root_account_id ON public.master_courses_child_content_tags USING btree (root_account_id);


--
-- Name: index_master_courses_child_subscriptions_on_master_template_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_master_courses_child_subscriptions_on_master_template_id ON public.master_courses_child_subscriptions USING btree (master_template_id);


--
-- Name: index_master_courses_child_subscriptions_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_master_courses_child_subscriptions_on_root_account_id ON public.master_courses_child_subscriptions USING btree (root_account_id);


--
-- Name: index_master_courses_master_content_tags_on_master_template_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_master_courses_master_content_tags_on_master_template_id ON public.master_courses_master_content_tags USING btree (master_template_id);


--
-- Name: index_master_courses_master_content_tags_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_master_courses_master_content_tags_on_root_account_id ON public.master_courses_master_content_tags USING btree (root_account_id);


--
-- Name: index_master_courses_master_migrations_on_master_template_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_master_courses_master_migrations_on_master_template_id ON public.master_courses_master_migrations USING btree (master_template_id);


--
-- Name: index_master_courses_master_migrations_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_master_courses_master_migrations_on_root_account_id ON public.master_courses_master_migrations USING btree (root_account_id);


--
-- Name: index_master_courses_master_templates_on_active_migration_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_master_courses_master_templates_on_active_migration_id ON public.master_courses_master_templates USING btree (active_migration_id) WHERE (active_migration_id IS NOT NULL);


--
-- Name: index_master_courses_master_templates_on_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_master_courses_master_templates_on_course_id ON public.master_courses_master_templates USING btree (course_id);


--
-- Name: index_master_courses_master_templates_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_master_courses_master_templates_on_root_account_id ON public.master_courses_master_templates USING btree (root_account_id);


--
-- Name: index_master_courses_migration_results_on_child_subscription_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_master_courses_migration_results_on_child_subscription_id ON public.master_courses_migration_results USING btree (child_subscription_id);


--
-- Name: index_master_courses_migration_results_on_content_migration_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_master_courses_migration_results_on_content_migration_id ON public.master_courses_migration_results USING btree (content_migration_id);


--
-- Name: index_master_courses_migration_results_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_master_courses_migration_results_on_root_account_id ON public.master_courses_migration_results USING btree (root_account_id);


--
-- Name: index_master_templates_unique_on_course_and_full; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_master_templates_unique_on_course_and_full ON public.master_courses_master_templates USING btree (course_id) WHERE (full_course AND ((workflow_state)::text <> 'deleted'::text));


--
-- Name: index_mc_child_content_tags_on_sub_and_migration_id_pattern_ops; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_mc_child_content_tags_on_sub_and_migration_id_pattern_ops ON public.master_courses_child_content_tags USING btree (child_subscription_id, migration_id text_pattern_ops);


--
-- Name: index_mc_child_subscriptions_on_template_id_and_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_mc_child_subscriptions_on_template_id_and_course_id ON public.master_courses_child_subscriptions USING btree (master_template_id, child_course_id) WHERE ((workflow_state)::text <> 'deleted'::text);


--
-- Name: index_mc_migration_results_on_master_and_content_migration_ids; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_mc_migration_results_on_master_and_content_migration_ids ON public.master_courses_migration_results USING btree (master_migration_id, content_migration_id);


--
-- Name: index_mc_migration_results_on_master_mig_id_and_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_mc_migration_results_on_master_mig_id_and_state ON public.master_courses_migration_results USING btree (master_migration_id, state);


--
-- Name: index_media_objects_on_attachment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_objects_on_attachment_id ON public.media_objects USING btree (attachment_id);


--
-- Name: index_media_objects_on_context_id_and_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_objects_on_context_id_and_context_type ON public.media_objects USING btree (context_id, context_type);


--
-- Name: index_media_objects_on_media_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_objects_on_media_id ON public.media_objects USING btree (media_id);


--
-- Name: index_media_objects_on_old_media_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_objects_on_old_media_id ON public.media_objects USING btree (old_media_id);


--
-- Name: index_media_objects_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_objects_on_root_account_id ON public.media_objects USING btree (root_account_id);


--
-- Name: index_media_objects_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_objects_on_user_id ON public.media_objects USING btree (user_id) WHERE (user_id IS NOT NULL);


--
-- Name: index_media_tracks_on_attachment_id_and_locale; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_media_tracks_on_attachment_id_and_locale ON public.media_tracks USING btree (attachment_id, locale) WHERE (attachment_id IS NOT NULL);


--
-- Name: index_mentions_on_discussion_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_mentions_on_discussion_entry_id ON public.mentions USING btree (discussion_entry_id);


--
-- Name: index_mentions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_mentions_on_user_id ON public.mentions USING btree (user_id);


--
-- Name: index_mentions_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_mentions_replica_identity ON public.mentions USING btree (root_account_id, id);


--
-- Name: index_messages_on_communication_channel_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_communication_channel_id ON public.messages USING btree (communication_channel_id);


--
-- Name: index_messages_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_created_at ON public.messages USING btree (created_at);


--
-- Name: index_messages_on_notification_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_notification_id ON public.messages USING btree (notification_id);


--
-- Name: index_messages_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_root_account_id ON public.messages USING btree (root_account_id);


--
-- Name: index_messages_on_sent_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_sent_at ON public.messages USING btree (sent_at) WHERE (sent_at IS NOT NULL);


--
-- Name: index_messages_user_id_dispatch_at_to_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_user_id_dispatch_at_to_email ON public.messages USING btree (user_id, to_email, dispatch_at);


--
-- Name: index_microsoft_sync_groups_on_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_microsoft_sync_groups_on_course_id ON public.microsoft_sync_groups USING btree (course_id);


--
-- Name: index_microsoft_sync_groups_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_microsoft_sync_groups_replica_identity ON public.microsoft_sync_groups USING btree (root_account_id, id);


--
-- Name: index_microsoft_sync_partial_sync_changes_course_user_enroll; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_microsoft_sync_partial_sync_changes_course_user_enroll ON public.microsoft_sync_partial_sync_changes USING btree (course_id, user_id, enrollment_type);


--
-- Name: index_microsoft_sync_partial_sync_changes_on_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_microsoft_sync_partial_sync_changes_on_course_id ON public.microsoft_sync_partial_sync_changes USING btree (course_id);


--
-- Name: index_microsoft_sync_partial_sync_changes_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_microsoft_sync_partial_sync_changes_on_user_id ON public.microsoft_sync_partial_sync_changes USING btree (user_id);


--
-- Name: index_microsoft_sync_partial_sync_changes_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_microsoft_sync_partial_sync_changes_replica_identity ON public.microsoft_sync_partial_sync_changes USING btree (root_account_id, id);


--
-- Name: index_microsoft_sync_user_mappings_ra_id_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_microsoft_sync_user_mappings_ra_id_user_id ON public.microsoft_sync_user_mappings USING btree (user_id, root_account_id);


--
-- Name: index_microsoft_sync_user_mappings_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_microsoft_sync_user_mappings_replica_identity ON public.microsoft_sync_user_mappings USING btree (root_account_id, id);


--
-- Name: index_migration_issues_on_content_migration_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_migration_issues_on_content_migration_id ON public.migration_issues USING btree (content_migration_id);


--
-- Name: index_moderated_grading_provisional_grades_on_scorer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_moderated_grading_provisional_grades_on_scorer_id ON public.moderated_grading_provisional_grades USING btree (scorer_id);


--
-- Name: index_moderated_grading_provisional_grades_on_submission_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_moderated_grading_provisional_grades_on_submission_id ON public.moderated_grading_provisional_grades USING btree (submission_id);


--
-- Name: index_moderated_grading_selections_on_selected_grade; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_moderated_grading_selections_on_selected_grade ON public.moderated_grading_selections USING btree (selected_provisional_grade_id) WHERE (selected_provisional_grade_id IS NOT NULL);


--
-- Name: index_moderated_grading_selections_on_student_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_moderated_grading_selections_on_student_id ON public.moderated_grading_selections USING btree (student_id);


--
-- Name: index_moderation_graders_on_assignment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_moderation_graders_on_assignment_id ON public.moderation_graders USING btree (assignment_id);


--
-- Name: index_moderation_graders_on_assignment_id_and_anonymous_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_moderation_graders_on_assignment_id_and_anonymous_id ON public.moderation_graders USING btree (assignment_id, anonymous_id);


--
-- Name: index_moderation_graders_on_user_id_and_assignment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_moderation_graders_on_user_id_and_assignment_id ON public.moderation_graders USING btree (user_id, assignment_id);


--
-- Name: index_notification_endpoints_on_access_token_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notification_endpoints_on_access_token_id ON public.notification_endpoints USING btree (access_token_id);


--
-- Name: index_notification_endpoints_on_access_token_id_and_arn; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_notification_endpoints_on_access_token_id_and_arn ON public.notification_endpoints USING btree (access_token_id, arn) WHERE ((workflow_state)::text = 'active'::text);


--
-- Name: index_notification_endpoints_on_workflow_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notification_endpoints_on_workflow_state ON public.notification_endpoints USING btree (workflow_state);


--
-- Name: index_notification_policies_on_cc_and_notification_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_notification_policies_on_cc_and_notification_id ON public.notification_policies USING btree (communication_channel_id, notification_id);


--
-- Name: index_notification_policies_on_notification_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notification_policies_on_notification_id ON public.notification_policies USING btree (notification_id);


--
-- Name: index_notification_policies_overrides_on_cc_id_and_notification; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notification_policies_overrides_on_cc_id_and_notification ON public.notification_policy_overrides USING btree (communication_channel_id, notification_id);


--
-- Name: index_notification_policies_overrides_uniq_context_and_cc; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_notification_policies_overrides_uniq_context_and_cc ON public.notification_policy_overrides USING btree (context_id, context_type, communication_channel_id) WHERE (notification_id IS NULL);


--
-- Name: index_notification_policies_overrides_uniq_context_notification; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_notification_policies_overrides_uniq_context_notification ON public.notification_policy_overrides USING btree (context_id, context_type, communication_channel_id, notification_id) WHERE (notification_id IS NOT NULL);


--
-- Name: index_notification_policy_overrides_on_communication_channel_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notification_policy_overrides_on_communication_channel_id ON public.notification_policy_overrides USING btree (communication_channel_id);


--
-- Name: index_notification_policy_overrides_on_context; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notification_policy_overrides_on_context ON public.notification_policy_overrides USING btree (context_type, context_id);


--
-- Name: index_notification_policy_overrides_on_notification_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notification_policy_overrides_on_notification_id ON public.notification_policy_overrides USING btree (notification_id);


--
-- Name: index_notifications_unique_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_notifications_unique_on_name ON public.notifications USING btree (name);


--
-- Name: index_oauth_requests_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_oauth_requests_on_user_id ON public.oauth_requests USING btree (user_id) WHERE (user_id IS NOT NULL);


--
-- Name: index_observer_alert_thresholds_on_observer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_observer_alert_thresholds_on_observer_id ON public.observer_alert_thresholds USING btree (observer_id);


--
-- Name: index_observer_alert_thresholds_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_observer_alert_thresholds_on_user_id ON public.observer_alert_thresholds USING btree (user_id);


--
-- Name: index_observer_alerts_on_context_type_and_context_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_observer_alerts_on_context_type_and_context_id ON public.observer_alerts USING btree (context_type, context_id);


--
-- Name: index_observer_alerts_on_observer_alert_threshold_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_observer_alerts_on_observer_alert_threshold_id ON public.observer_alerts USING btree (observer_alert_threshold_id);


--
-- Name: index_observer_alerts_on_observer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_observer_alerts_on_observer_id ON public.observer_alerts USING btree (observer_id);


--
-- Name: index_observer_alerts_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_observer_alerts_on_user_id ON public.observer_alerts USING btree (user_id);


--
-- Name: index_observer_alerts_on_workflow_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_observer_alerts_on_workflow_state ON public.observer_alerts USING btree (workflow_state);


--
-- Name: index_observer_pairing_codes_on_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_observer_pairing_codes_on_expires_at ON public.observer_pairing_codes USING btree (expires_at);


--
-- Name: index_observer_pairing_codes_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_observer_pairing_codes_on_user_id ON public.observer_pairing_codes USING btree (user_id);


--
-- Name: index_on_report_snapshots; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_on_report_snapshots ON public.report_snapshots USING btree (report_type, account_id, created_at);


--
-- Name: index_on_submissions_missing_for_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_on_submissions_missing_for_user ON public.submissions USING btree (user_id) WHERE ((late_policy_status)::text = 'missing'::text);


--
-- Name: index_one_time_passwords_on_user_id_and_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_one_time_passwords_on_user_id_and_code ON public.one_time_passwords USING btree (user_id, code);


--
-- Name: index_originality_reports_on_attachment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_originality_reports_on_attachment_id ON public.originality_reports USING btree (attachment_id);


--
-- Name: index_originality_reports_on_originality_report_attachment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_originality_reports_on_originality_report_attachment_id ON public.originality_reports USING btree (originality_report_attachment_id);


--
-- Name: index_originality_reports_on_submission_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_originality_reports_on_submission_id ON public.originality_reports USING btree (submission_id);


--
-- Name: index_originality_reports_on_submission_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_originality_reports_on_submission_time ON public.originality_reports USING btree (submission_time);


--
-- Name: index_originality_reports_on_workflow_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_originality_reports_on_workflow_state ON public.originality_reports USING btree (workflow_state);


--
-- Name: index_originality_reports_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_originality_reports_replica_identity ON public.originality_reports USING btree (root_account_id, id);


--
-- Name: index_outcome_calculation_methods_on_context; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_outcome_calculation_methods_on_context ON public.outcome_calculation_methods USING btree (context_type, context_id);


--
-- Name: index_outcome_calculation_methods_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outcome_calculation_methods_on_root_account_id ON public.outcome_calculation_methods USING btree (root_account_id);


--
-- Name: index_outcome_friendly_description_on_context_and_outcome; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_outcome_friendly_description_on_context_and_outcome ON public.outcome_friendly_descriptions USING btree (context_type, context_id, learning_outcome_id);


--
-- Name: index_outcome_friendly_descriptions_on_learning_outcome_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outcome_friendly_descriptions_on_learning_outcome_id ON public.outcome_friendly_descriptions USING btree (learning_outcome_id);


--
-- Name: index_outcome_friendly_descriptions_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outcome_friendly_descriptions_on_root_account_id ON public.outcome_friendly_descriptions USING btree (root_account_id);


--
-- Name: index_outcome_import_errors_on_outcome_import_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outcome_import_errors_on_outcome_import_id ON public.outcome_import_errors USING btree (outcome_import_id);


--
-- Name: index_outcome_imports_on_attachment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outcome_imports_on_attachment_id ON public.outcome_imports USING btree (attachment_id);


--
-- Name: index_outcome_imports_on_context_type_and_context_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outcome_imports_on_context_type_and_context_id ON public.outcome_imports USING btree (context_type, context_id);


--
-- Name: index_outcome_imports_on_learning_outcome_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outcome_imports_on_learning_outcome_group_id ON public.outcome_imports USING btree (learning_outcome_group_id);


--
-- Name: index_outcome_imports_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outcome_imports_on_user_id ON public.outcome_imports USING btree (user_id);


--
-- Name: index_outcome_proficiencies_on_context_id_and_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_outcome_proficiencies_on_context_id_and_context_type ON public.outcome_proficiencies USING btree (context_id, context_type) WHERE (context_id IS NOT NULL);


--
-- Name: index_outcome_proficiencies_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outcome_proficiencies_on_root_account_id ON public.outcome_proficiencies USING btree (root_account_id);


--
-- Name: index_outcome_proficiency_ratings_on_outcome_proficiency_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outcome_proficiency_ratings_on_outcome_proficiency_id ON public.outcome_proficiency_ratings USING btree (outcome_proficiency_id);


--
-- Name: index_outcome_proficiency_ratings_on_proficiency_and_points; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outcome_proficiency_ratings_on_proficiency_and_points ON public.outcome_proficiency_ratings USING btree (outcome_proficiency_id, points);


--
-- Name: index_outcome_proficiency_ratings_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_outcome_proficiency_ratings_on_root_account_id ON public.outcome_proficiency_ratings USING btree (root_account_id);


--
-- Name: index_page_comments_on_page_id_and_page_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_page_comments_on_page_id_and_page_type ON public.page_comments USING btree (page_id, page_type);


--
-- Name: index_page_comments_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_page_comments_on_user_id ON public.page_comments USING btree (user_id);


--
-- Name: index_page_views_asset_user_access_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_page_views_asset_user_access_id ON public.page_views USING btree (asset_user_access_id);


--
-- Name: index_page_views_on_account_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_page_views_on_account_id_and_created_at ON public.page_views USING btree (account_id, created_at);


--
-- Name: index_page_views_on_context_type_and_context_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_page_views_on_context_type_and_context_id ON public.page_views USING btree (context_type, context_id);


--
-- Name: index_page_views_on_real_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_page_views_on_real_user_id ON public.page_views USING btree (real_user_id) WHERE (real_user_id IS NOT NULL);


--
-- Name: index_page_views_on_user_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_page_views_on_user_id_and_created_at ON public.page_views USING btree (user_id, created_at);


--
-- Name: index_page_views_summarized_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_page_views_summarized_created_at ON public.page_views USING btree (summarized, created_at);


--
-- Name: index_parallel_importers_on_attachment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parallel_importers_on_attachment_id ON public.parallel_importers USING btree (attachment_id);


--
-- Name: index_parallel_importers_on_sis_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parallel_importers_on_sis_batch_id ON public.parallel_importers USING btree (sis_batch_id);


--
-- Name: index_planner_notes_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_planner_notes_on_user_id ON public.planner_notes USING btree (user_id);


--
-- Name: index_planner_notes_on_user_id_and_linked_object; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_planner_notes_on_user_id_and_linked_object ON public.planner_notes USING btree (user_id, linked_object_id, linked_object_type) WHERE ((linked_object_id IS NOT NULL) AND ((workflow_state)::text <> 'deleted'::text));


--
-- Name: index_planner_overrides_on_plannable_and_user; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_planner_overrides_on_plannable_and_user ON public.planner_overrides USING btree (plannable_type, plannable_id, user_id);


--
-- Name: index_planner_overrides_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_planner_overrides_on_user_id ON public.planner_overrides USING btree (user_id);


--
-- Name: index_plugin_settings_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plugin_settings_on_name ON public.plugin_settings USING btree (name);


--
-- Name: index_polling_poll_choices_on_poll_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_polling_poll_choices_on_poll_id ON public.polling_poll_choices USING btree (poll_id);


--
-- Name: index_polling_poll_sessions_on_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_polling_poll_sessions_on_course_id ON public.polling_poll_sessions USING btree (course_id);


--
-- Name: index_polling_poll_sessions_on_course_section_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_polling_poll_sessions_on_course_section_id ON public.polling_poll_sessions USING btree (course_section_id);


--
-- Name: index_polling_poll_sessions_on_poll_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_polling_poll_sessions_on_poll_id ON public.polling_poll_sessions USING btree (poll_id);


--
-- Name: index_polling_poll_submissions_on_poll_choice_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_polling_poll_submissions_on_poll_choice_id ON public.polling_poll_submissions USING btree (poll_choice_id);


--
-- Name: index_polling_poll_submissions_on_poll_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_polling_poll_submissions_on_poll_id ON public.polling_poll_submissions USING btree (poll_id);


--
-- Name: index_polling_poll_submissions_on_poll_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_polling_poll_submissions_on_poll_session_id ON public.polling_poll_submissions USING btree (poll_session_id);


--
-- Name: index_polling_poll_submissions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_polling_poll_submissions_on_user_id ON public.polling_poll_submissions USING btree (user_id);


--
-- Name: index_polling_polls_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_polling_polls_on_user_id ON public.polling_polls USING btree (user_id);


--
-- Name: index_post_policies_on_assignment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_post_policies_on_assignment_id ON public.post_policies USING btree (assignment_id);


--
-- Name: index_post_policies_on_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_post_policies_on_course_id ON public.post_policies USING btree (course_id);


--
-- Name: index_post_policies_on_course_id_and_assignment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_post_policies_on_course_id_and_assignment_id ON public.post_policies USING btree (course_id, assignment_id);


--
-- Name: index_post_policies_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_post_policies_on_root_account_id ON public.post_policies USING btree (root_account_id);


--
-- Name: index_profiles_on_context_type_and_context_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_profiles_on_context_type_and_context_id ON public.profiles USING btree (context_type, context_id);


--
-- Name: index_profiles_on_root_account_id_and_path; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_profiles_on_root_account_id_and_path ON public.profiles USING btree (root_account_id, path);


--
-- Name: index_progresses_on_context_id_and_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_progresses_on_context_id_and_context_type ON public.progresses USING btree (context_id, context_type);


--
-- Name: index_provisional_grades_on_source_grade; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_provisional_grades_on_source_grade ON public.moderated_grading_provisional_grades USING btree (source_provisional_grade_id) WHERE (source_provisional_grade_id IS NOT NULL);


--
-- Name: index_pseudonyms_on_authentication_provider_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pseudonyms_on_authentication_provider_id ON public.pseudonyms USING btree (authentication_provider_id) WHERE (authentication_provider_id IS NOT NULL);


--
-- Name: index_pseudonyms_on_integration_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_pseudonyms_on_integration_id ON public.pseudonyms USING btree (integration_id, account_id) WHERE (integration_id IS NOT NULL);


--
-- Name: index_pseudonyms_on_persistence_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pseudonyms_on_persistence_token ON public.pseudonyms USING btree (persistence_token);


--
-- Name: index_pseudonyms_on_single_access_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pseudonyms_on_single_access_token ON public.pseudonyms USING btree (single_access_token);


--
-- Name: index_pseudonyms_on_sis_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pseudonyms_on_sis_batch_id ON public.pseudonyms USING btree (sis_batch_id) WHERE (sis_batch_id IS NOT NULL);


--
-- Name: index_pseudonyms_on_sis_communication_channel_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pseudonyms_on_sis_communication_channel_id ON public.pseudonyms USING btree (sis_communication_channel_id);


--
-- Name: index_pseudonyms_on_sis_user_id_and_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_pseudonyms_on_sis_user_id_and_account_id ON public.pseudonyms USING btree (sis_user_id, account_id) WHERE (sis_user_id IS NOT NULL);


--
-- Name: index_pseudonyms_on_unique_id_and_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pseudonyms_on_unique_id_and_account_id ON public.pseudonyms USING btree (lower((unique_id)::text), account_id);


--
-- Name: index_pseudonyms_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pseudonyms_on_user_id ON public.pseudonyms USING btree (user_id);


--
-- Name: index_pseudonyms_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_pseudonyms_replica_identity ON public.pseudonyms USING btree (account_id, id);


--
-- Name: index_pseudonyms_unique_with_auth_provider; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_pseudonyms_unique_with_auth_provider ON public.pseudonyms USING btree (lower((unique_id)::text), account_id, authentication_provider_id) WHERE ((workflow_state)::text = ANY ((ARRAY['active'::character varying, 'suspended'::character varying])::text[]));


--
-- Name: index_pseudonyms_unique_without_auth_provider; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_pseudonyms_unique_without_auth_provider ON public.pseudonyms USING btree (lower((unique_id)::text), account_id) WHERE (((workflow_state)::text = ANY ((ARRAY['active'::character varying, 'suspended'::character varying])::text[])) AND (authentication_provider_id IS NULL));


--
-- Name: index_purgatories_on_attachment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_purgatories_on_attachment_id ON public.purgatories USING btree (attachment_id);


--
-- Name: index_purgatories_on_deleted_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purgatories_on_deleted_by_user_id ON public.purgatories USING btree (deleted_by_user_id);


--
-- Name: index_purgatories_on_workflow_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_purgatories_on_workflow_state ON public.purgatories USING btree (workflow_state);


--
-- Name: index_qqr_on_qq_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_qqr_on_qq_id ON public.quiz_question_regrades USING btree (quiz_question_id);


--
-- Name: index_qqr_on_qr_id_and_qq_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_qqr_on_qr_id_and_qq_id ON public.quiz_question_regrades USING btree (quiz_regrade_id, quiz_question_id);


--
-- Name: index_quiz_groups_on_quiz_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_quiz_groups_on_quiz_id ON public.quiz_groups USING btree (quiz_id);


--
-- Name: index_quiz_groups_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_quiz_groups_on_root_account_id ON public.quiz_groups USING btree (root_account_id);


--
-- Name: index_quiz_migration_alerts_on_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_quiz_migration_alerts_on_course_id ON public.quiz_migration_alerts USING btree (course_id);


--
-- Name: index_quiz_migration_alerts_on_migration_type_and_migration_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_quiz_migration_alerts_on_migration_type_and_migration_id ON public.quiz_migration_alerts USING btree (migration_type, migration_id);


--
-- Name: index_quiz_migration_alerts_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_quiz_migration_alerts_on_user_id ON public.quiz_migration_alerts USING btree (user_id);


--
-- Name: index_quiz_questions_on_assessment_question_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_quiz_questions_on_assessment_question_id ON public.quiz_questions USING btree (assessment_question_id) WHERE (assessment_question_id IS NOT NULL);


--
-- Name: index_quiz_questions_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_quiz_questions_on_root_account_id ON public.quiz_questions USING btree (root_account_id);


--
-- Name: index_quiz_regrade_runs_on_quiz_regrade_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_quiz_regrade_runs_on_quiz_regrade_id ON public.quiz_regrade_runs USING btree (quiz_regrade_id);


--
-- Name: index_quiz_regrades_on_quiz_id_and_quiz_version; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_quiz_regrades_on_quiz_id_and_quiz_version ON public.quiz_regrades USING btree (quiz_id, quiz_version);


--
-- Name: index_quiz_regrades_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_quiz_regrades_on_user_id ON public.quiz_regrades USING btree (user_id);


--
-- Name: index_quiz_statistics_on_quiz_id_and_report_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_quiz_statistics_on_quiz_id_and_report_type ON public.quiz_statistics USING btree (quiz_id, report_type);


--
-- Name: index_quiz_submission_events_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_quiz_submission_events_on_created_at ON public.quiz_submission_events USING btree (created_at);


--
-- Name: index_quiz_submission_events_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_quiz_submission_events_on_root_account_id ON public.quiz_submission_events USING btree (root_account_id);


--
-- Name: index_quiz_submission_snapshots_on_quiz_submission_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_quiz_submission_snapshots_on_quiz_submission_id ON public.quiz_submission_snapshots USING btree (quiz_submission_id);


--
-- Name: index_quiz_submissions_on_quiz_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_quiz_submissions_on_quiz_id_and_user_id ON public.quiz_submissions USING btree (quiz_id, user_id);


--
-- Name: index_quiz_submissions_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_quiz_submissions_on_root_account_id ON public.quiz_submissions USING btree (root_account_id);


--
-- Name: index_quiz_submissions_on_submission_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_quiz_submissions_on_submission_id ON public.quiz_submissions USING btree (submission_id);


--
-- Name: index_quiz_submissions_on_temporary_user_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_quiz_submissions_on_temporary_user_code ON public.quiz_submissions USING btree (temporary_user_code);


--
-- Name: index_quiz_submissions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_quiz_submissions_on_user_id ON public.quiz_submissions USING btree (user_id);


--
-- Name: index_quizzes_on_assignment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_quizzes_on_assignment_id ON public.quizzes USING btree (assignment_id);


--
-- Name: index_quizzes_on_cloned_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_quizzes_on_cloned_item_id ON public.quizzes USING btree (cloned_item_id) WHERE (cloned_item_id IS NOT NULL);


--
-- Name: index_quizzes_on_context_id_and_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_quizzes_on_context_id_and_context_type ON public.quizzes USING btree (context_id, context_type);


--
-- Name: index_quizzes_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_quizzes_on_root_account_id ON public.quizzes USING btree (root_account_id);


--
-- Name: index_report_snapshots_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_report_snapshots_on_account_id ON public.report_snapshots USING btree (account_id) WHERE (account_id IS NOT NULL);


--
-- Name: index_resource_codes_on_assignment_configuration_tool_lookups; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_resource_codes_on_assignment_configuration_tool_lookups ON public.assignment_configuration_tool_lookups USING btree (tool_product_code, tool_vendor_code, tool_resource_type_code);


--
-- Name: index_resource_placements_on_placement_and_message_handler; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_resource_placements_on_placement_and_message_handler ON public.lti_resource_placements USING btree (placement, message_handler_id) WHERE (message_handler_id IS NOT NULL);


--
-- Name: index_role_overrides_on_context_role_permission; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_role_overrides_on_context_role_permission ON public.role_overrides USING btree (context_id, context_type, role_id, permission);


--
-- Name: index_role_overrides_on_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_role_overrides_on_role_id ON public.role_overrides USING btree (role_id);


--
-- Name: index_role_overrides_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_role_overrides_replica_identity ON public.role_overrides USING btree (root_account_id, id);


--
-- Name: index_roles_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roles_on_account_id ON public.roles USING btree (account_id);


--
-- Name: index_roles_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roles_on_name ON public.roles USING btree (name);


--
-- Name: index_roles_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_roles_replica_identity ON public.roles USING btree (root_account_id, id);


--
-- Name: index_roles_unique_account_name_where_active; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_roles_unique_account_name_where_active ON public.roles USING btree (account_id, name) WHERE ((workflow_state)::text = 'active'::text);


--
-- Name: index_rubric_assessments_on_artifact_id_and_artifact_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rubric_assessments_on_artifact_id_and_artifact_type ON public.rubric_assessments USING btree (artifact_id, artifact_type);


--
-- Name: index_rubric_assessments_on_assessor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rubric_assessments_on_assessor_id ON public.rubric_assessments USING btree (assessor_id);


--
-- Name: index_rubric_assessments_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rubric_assessments_on_root_account_id ON public.rubric_assessments USING btree (root_account_id);


--
-- Name: index_rubric_assessments_on_rubric_association_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rubric_assessments_on_rubric_association_id ON public.rubric_assessments USING btree (rubric_association_id);


--
-- Name: index_rubric_assessments_on_rubric_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rubric_assessments_on_rubric_id ON public.rubric_assessments USING btree (rubric_id);


--
-- Name: index_rubric_assessments_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rubric_assessments_on_user_id ON public.rubric_assessments USING btree (user_id);


--
-- Name: index_rubric_associations_on_aid_and_atype; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rubric_associations_on_aid_and_atype ON public.rubric_associations USING btree (association_id, association_type);


--
-- Name: index_rubric_associations_on_context_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rubric_associations_on_context_code ON public.rubric_associations USING btree (context_code);


--
-- Name: index_rubric_associations_on_context_id_and_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rubric_associations_on_context_id_and_context_type ON public.rubric_associations USING btree (context_id, context_type);


--
-- Name: index_rubric_associations_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rubric_associations_on_root_account_id ON public.rubric_associations USING btree (root_account_id);


--
-- Name: index_rubric_associations_on_rubric_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rubric_associations_on_rubric_id ON public.rubric_associations USING btree (rubric_id);


--
-- Name: index_rubric_criteria_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rubric_criteria_on_created_by_id ON public.rubric_criteria USING btree (created_by_id);


--
-- Name: index_rubric_criteria_on_deleted_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rubric_criteria_on_deleted_by_id ON public.rubric_criteria USING btree (deleted_by_id);


--
-- Name: index_rubric_criteria_on_learning_outcome_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rubric_criteria_on_learning_outcome_id ON public.rubric_criteria USING btree (learning_outcome_id);


--
-- Name: index_rubric_criteria_on_rubric_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rubric_criteria_on_rubric_id ON public.rubric_criteria USING btree (rubric_id);


--
-- Name: index_rubric_criteria_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_rubric_criteria_replica_identity ON public.rubric_criteria USING btree (root_account_id, id);


--
-- Name: index_rubrics_on_context_id_and_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rubrics_on_context_id_and_context_type ON public.rubrics USING btree (context_id, context_type);


--
-- Name: index_rubrics_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rubrics_on_root_account_id ON public.rubrics USING btree (root_account_id);


--
-- Name: index_rubrics_on_rubric_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rubrics_on_rubric_id ON public.rubrics USING btree (rubric_id) WHERE (rubric_id IS NOT NULL);


--
-- Name: index_rubrics_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rubrics_on_user_id ON public.rubrics USING btree (user_id);


--
-- Name: index_scheduled_smart_alerts_on_due_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_scheduled_smart_alerts_on_due_at ON public.scheduled_smart_alerts USING btree (due_at);


--
-- Name: index_scheduled_smart_alerts_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_scheduled_smart_alerts_on_root_account_id ON public.scheduled_smart_alerts USING btree (root_account_id);


--
-- Name: index_score_metadata_on_score_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_score_metadata_on_score_id ON public.score_metadata USING btree (score_id);


--
-- Name: index_score_statistics_on_assignment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_score_statistics_on_assignment_id ON public.score_statistics USING btree (assignment_id);


--
-- Name: index_score_statistics_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_score_statistics_on_root_account_id ON public.score_statistics USING btree (root_account_id);


--
-- Name: index_scores_on_assignment_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_scores_on_assignment_group_id ON public.scores USING btree (assignment_group_id);


--
-- Name: index_scores_on_custom_grade_status_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_scores_on_custom_grade_status_id ON public.scores USING btree (custom_grade_status_id) WHERE (custom_grade_status_id IS NOT NULL);


--
-- Name: index_scores_on_grading_period_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_scores_on_grading_period_id ON public.scores USING btree (grading_period_id) WHERE (grading_period_id IS NOT NULL);


--
-- Name: index_scores_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_scores_on_root_account_id ON public.scores USING btree (root_account_id);


--
-- Name: index_sections_on_integration_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_sections_on_integration_id ON public.course_sections USING btree (integration_id, root_account_id) WHERE (integration_id IS NOT NULL);


--
-- Name: index_session_persistence_tokens_on_pseudonym_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_session_persistence_tokens_on_pseudonym_id ON public.session_persistence_tokens USING btree (pseudonym_id);


--
-- Name: index_sessions_on_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sessions_on_session_id ON public.sessions USING btree (session_id);


--
-- Name: index_sessions_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sessions_on_updated_at ON public.sessions USING btree (updated_at);


--
-- Name: index_settings_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_settings_on_name ON public.settings USING btree (name);


--
-- Name: index_shared_brand_configs_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shared_brand_configs_on_account_id ON public.shared_brand_configs USING btree (account_id);


--
-- Name: index_shared_brand_configs_on_brand_config_md5; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shared_brand_configs_on_brand_config_md5 ON public.shared_brand_configs USING btree (brand_config_md5);


--
-- Name: index_sis_batch_errors_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sis_batch_errors_on_created_at ON public.sis_batch_errors USING btree (created_at);


--
-- Name: index_sis_batch_errors_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sis_batch_errors_on_root_account_id ON public.sis_batch_errors USING btree (root_account_id);


--
-- Name: index_sis_batch_errors_on_sis_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sis_batch_errors_on_sis_batch_id ON public.sis_batch_errors USING btree (sis_batch_id);


--
-- Name: index_sis_batch_roll_back_context_workflow_states; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sis_batch_roll_back_context_workflow_states ON public.sis_batch_roll_back_data USING btree (updated_workflow_state, previous_workflow_state);


--
-- Name: index_sis_batch_roll_back_data_on_sis_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sis_batch_roll_back_data_on_sis_batch_id ON public.sis_batch_roll_back_data USING btree (sis_batch_id);


--
-- Name: index_sis_batch_roll_back_data_on_workflow_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sis_batch_roll_back_data_on_workflow_state ON public.sis_batch_roll_back_data USING btree (workflow_state);


--
-- Name: index_sis_batches_account_id_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sis_batches_account_id_created_at ON public.sis_batches USING btree (account_id, created_at);


--
-- Name: index_sis_batches_diffing; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sis_batches_diffing ON public.sis_batches USING btree (account_id, diffing_data_set_identifier, created_at);


--
-- Name: index_sis_batches_on_attachment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sis_batches_on_attachment_id ON public.sis_batches USING btree (attachment_id);


--
-- Name: index_sis_batches_on_batch_mode_term_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sis_batches_on_batch_mode_term_id ON public.sis_batches USING btree (batch_mode_term_id) WHERE (batch_mode_term_id IS NOT NULL);


--
-- Name: index_sis_batches_on_errors_attachment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sis_batches_on_errors_attachment_id ON public.sis_batches USING btree (errors_attachment_id);


--
-- Name: index_sis_batches_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sis_batches_on_user_id ON public.sis_batches USING btree (user_id) WHERE (user_id IS NOT NULL);


--
-- Name: index_sis_batches_workflow_state_for_accounts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sis_batches_workflow_state_for_accounts ON public.sis_batches USING btree (account_id, workflow_state, created_at);


--
-- Name: index_sis_post_grades_statuses_on_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sis_post_grades_statuses_on_course_id ON public.sis_post_grades_statuses USING btree (course_id);


--
-- Name: index_sis_post_grades_statuses_on_course_section_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sis_post_grades_statuses_on_course_section_id ON public.sis_post_grades_statuses USING btree (course_section_id);


--
-- Name: index_sis_post_grades_statuses_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sis_post_grades_statuses_on_user_id ON public.sis_post_grades_statuses USING btree (user_id);


--
-- Name: index_standard_grade_statuses_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_standard_grade_statuses_replica_identity ON public.standard_grade_statuses USING btree (root_account_id, id);


--
-- Name: index_standard_status_on_name_and_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_standard_status_on_name_and_root_account_id ON public.standard_grade_statuses USING btree (status_name, root_account_id);


--
-- Name: index_stream_item_instances_global; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_stream_item_instances_global ON public.stream_item_instances USING btree (user_id, hidden, id, stream_item_id);


--
-- Name: index_stream_item_instances_on_context_type_and_context_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_stream_item_instances_on_context_type_and_context_id ON public.stream_item_instances USING btree (context_type, context_id);


--
-- Name: index_stream_item_instances_on_stream_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_stream_item_instances_on_stream_item_id ON public.stream_item_instances USING btree (stream_item_id);


--
-- Name: index_stream_item_instances_on_stream_item_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_stream_item_instances_on_stream_item_id_and_user_id ON public.stream_item_instances USING btree (stream_item_id, user_id);


--
-- Name: index_stream_items_on_asset_type_and_asset_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_stream_items_on_asset_type_and_asset_id ON public.stream_items USING btree (asset_type, asset_id);


--
-- Name: index_stream_items_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_stream_items_on_updated_at ON public.stream_items USING btree (updated_at);


--
-- Name: index_submission_comments_on_attempt; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submission_comments_on_attempt ON public.submission_comments USING btree (attempt);


--
-- Name: index_submission_comments_on_author_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submission_comments_on_author_id ON public.submission_comments USING btree (author_id);


--
-- Name: index_submission_comments_on_context_id_and_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submission_comments_on_context_id_and_context_type ON public.submission_comments USING btree (context_id, context_type);


--
-- Name: index_submission_comments_on_draft; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submission_comments_on_draft ON public.submission_comments USING btree (draft);


--
-- Name: index_submission_comments_on_provisional_grade_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submission_comments_on_provisional_grade_id ON public.submission_comments USING btree (provisional_grade_id) WHERE (provisional_grade_id IS NOT NULL);


--
-- Name: index_submission_comments_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submission_comments_on_root_account_id ON public.submission_comments USING btree (root_account_id);


--
-- Name: index_submission_comments_on_submission_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submission_comments_on_submission_id ON public.submission_comments USING btree (submission_id);


--
-- Name: index_submission_draft_and_attachment_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_submission_draft_and_attachment_unique ON public.submission_draft_attachments USING btree (submission_draft_id, attachment_id);


--
-- Name: index_submission_draft_attachments_on_attachment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submission_draft_attachments_on_attachment_id ON public.submission_draft_attachments USING btree (attachment_id);


--
-- Name: index_submission_draft_attachments_on_submission_draft_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submission_draft_attachments_on_submission_draft_id ON public.submission_draft_attachments USING btree (submission_draft_id);


--
-- Name: index_submission_drafts_on_submission_attempt; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submission_drafts_on_submission_attempt ON public.submission_drafts USING btree (submission_attempt);


--
-- Name: index_submission_drafts_on_submission_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submission_drafts_on_submission_id ON public.submission_drafts USING btree (submission_id);


--
-- Name: index_submission_versions; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_submission_versions ON public.submission_versions USING btree (context_id, version_id, user_id, assignment_id) WHERE ((context_type)::text = 'Course'::text);


--
-- Name: index_submission_versions_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submission_versions_on_root_account_id ON public.submission_versions USING btree (root_account_id);


--
-- Name: index_submission_versions_on_version_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submission_versions_on_version_id ON public.submission_versions USING btree (version_id);


--
-- Name: index_submissions_graded_or_excused_on_assignment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submissions_graded_or_excused_on_assignment_id ON public.submissions USING btree (assignment_id) WHERE (((workflow_state)::text <> 'deleted'::text) AND (((score IS NOT NULL) AND ((workflow_state)::text = 'graded'::text)) OR (excused = true)));


--
-- Name: index_submissions_graded_or_excused_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submissions_graded_or_excused_on_user_id ON public.submissions USING btree (user_id) WHERE (((score IS NOT NULL) AND ((workflow_state)::text = 'graded'::text)) OR (excused = true));


--
-- Name: index_submissions_needs_grading; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submissions_needs_grading ON public.submissions USING btree (assignment_id) WHERE ((submission_type IS NOT NULL) AND ((excused = false) OR (excused IS NULL)) AND (((workflow_state)::text = 'pending_review'::text) OR (((workflow_state)::text = ANY ((ARRAY['submitted'::character varying, 'graded'::character varying])::text[])) AND ((score IS NULL) OR (NOT grade_matches_current_submission)))));


--
-- Name: index_submissions_on_assignment_id_and_anonymous_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_submissions_on_assignment_id_and_anonymous_id ON public.submissions USING btree (assignment_id, anonymous_id) WHERE (anonymous_id IS NOT NULL);


--
-- Name: index_submissions_on_assignment_id_and_submission_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submissions_on_assignment_id_and_submission_type ON public.submissions USING btree (assignment_id, submission_type);


--
-- Name: index_submissions_on_assignment_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submissions_on_assignment_id_and_user_id ON public.submissions USING btree (assignment_id, user_id);


--
-- Name: index_submissions_on_cached_due_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submissions_on_cached_due_date ON public.submissions USING btree (cached_due_date);


--
-- Name: index_submissions_on_cached_quiz_lti; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submissions_on_cached_quiz_lti ON public.submissions USING btree (cached_quiz_lti);


--
-- Name: index_submissions_on_course_id_and_cached_due_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submissions_on_course_id_and_cached_due_date ON public.submissions USING btree (course_id, cached_due_date);


--
-- Name: index_submissions_on_custom_grade_status_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submissions_on_custom_grade_status_id ON public.submissions USING btree (custom_grade_status_id) WHERE (custom_grade_status_id IS NOT NULL);


--
-- Name: index_submissions_on_graded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submissions_on_graded_at ON public.submissions USING brin (graded_at);


--
-- Name: index_submissions_on_grading_period_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submissions_on_grading_period_id ON public.submissions USING btree (grading_period_id) WHERE (grading_period_id IS NOT NULL);


--
-- Name: index_submissions_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submissions_on_group_id ON public.submissions USING btree (group_id) WHERE (group_id IS NOT NULL);


--
-- Name: index_submissions_on_late_policy_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submissions_on_late_policy_status ON public.submissions USING btree (late_policy_status) WHERE (((workflow_state)::text <> 'deleted'::text) AND (late_policy_status IS NOT NULL));


--
-- Name: index_submissions_on_media_object_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submissions_on_media_object_id ON public.submissions USING btree (media_object_id) WHERE (media_object_id IS NOT NULL);


--
-- Name: index_submissions_on_proxy_submitter_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submissions_on_proxy_submitter_id ON public.submissions USING btree (proxy_submitter_id);


--
-- Name: index_submissions_on_quiz_submission_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submissions_on_quiz_submission_id ON public.submissions USING btree (quiz_submission_id) WHERE (quiz_submission_id IS NOT NULL);


--
-- Name: index_submissions_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submissions_on_root_account_id ON public.submissions USING btree (root_account_id);


--
-- Name: index_submissions_on_submitted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submissions_on_submitted_at ON public.submissions USING btree (submitted_at);


--
-- Name: index_submissions_on_user_and_greatest_dates; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submissions_on_user_and_greatest_dates ON public.submissions USING btree (user_id, GREATEST(submitted_at, created_at));


--
-- Name: index_submissions_on_user_id_and_assignment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_submissions_on_user_id_and_assignment_id ON public.submissions USING btree (user_id, assignment_id);


--
-- Name: index_submissions_on_user_id_and_cached_due_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submissions_on_user_id_and_cached_due_date ON public.submissions USING btree (user_id, cached_due_date);


--
-- Name: index_submissions_on_user_id_and_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submissions_on_user_id_and_course_id ON public.submissions USING btree (user_id, course_id);


--
-- Name: index_submissions_with_grade; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submissions_with_grade ON public.submissions USING btree (user_id, course_id) WHERE (((score IS NOT NULL) OR (grade IS NOT NULL)) AND ((workflow_state)::text <> 'deleted'::text));


--
-- Name: index_switchman_shards_on_database_server_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_switchman_shards_on_database_server_id_and_name ON public.switchman_shards USING btree (database_server_id, name);


--
-- Name: index_switchman_shards_on_default; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_switchman_shards_on_default ON public.switchman_shards USING btree ("default") WHERE "default";


--
-- Name: index_switchman_shards_on_delayed_jobs_shard_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_switchman_shards_on_delayed_jobs_shard_id ON public.switchman_shards USING btree (delayed_jobs_shard_id) WHERE (delayed_jobs_shard_id IS NOT NULL);


--
-- Name: index_switchman_shards_unique_primary_db_and_shard; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_switchman_shards_unique_primary_db_and_shard ON public.switchman_shards USING btree ((true)) WHERE ((database_server_id IS NULL) AND (name IS NULL));


--
-- Name: index_switchman_shards_unique_primary_shard; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_switchman_shards_unique_primary_shard ON public.switchman_shards USING btree (database_server_id) WHERE (name IS NULL);


--
-- Name: index_temporary_enrollment_pairings_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_temporary_enrollment_pairings_on_created_by_id ON public.temporary_enrollment_pairings USING btree (created_by_id);


--
-- Name: index_temporary_enrollment_pairings_on_deleted_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_temporary_enrollment_pairings_on_deleted_by_id ON public.temporary_enrollment_pairings USING btree (deleted_by_id);


--
-- Name: index_temporary_enrollment_pairings_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_temporary_enrollment_pairings_replica_identity ON public.temporary_enrollment_pairings USING btree (root_account_id, id);


--
-- Name: index_terms_of_service_contents_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_terms_of_service_contents_on_account_id ON public.terms_of_service_contents USING btree (account_id);


--
-- Name: index_terms_of_services_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_terms_of_services_on_account_id ON public.terms_of_services USING btree (account_id);


--
-- Name: index_terms_on_integration_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_terms_on_integration_id ON public.enrollment_terms USING btree (integration_id, root_account_id) WHERE (integration_id IS NOT NULL);


--
-- Name: index_thumbnails_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_thumbnails_on_parent_id ON public.thumbnails USING btree (parent_id);


--
-- Name: index_thumbnails_size; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_thumbnails_size ON public.thumbnails USING btree (parent_id, thumbnail);


--
-- Name: index_tool_lookup_on_tool_assignment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tool_lookup_on_tool_assignment_id ON public.assignment_configuration_tool_lookups USING btree (tool_id, tool_type, assignment_id);


--
-- Name: index_topic_participant_on_topic_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_topic_participant_on_topic_id_and_user_id ON public.discussion_topic_participants USING btree (discussion_topic_id, user_id);


--
-- Name: index_unique_scheduled_smart_alert; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_unique_scheduled_smart_alert ON public.scheduled_smart_alerts USING btree (context_type, context_id, alert_type, root_account_id);


--
-- Name: index_user_account_associations_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_account_associations_on_account_id ON public.user_account_associations USING btree (account_id);


--
-- Name: index_user_account_associations_on_user_id_and_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_account_associations_on_user_id_and_account_id ON public.user_account_associations USING btree (user_id, account_id);


--
-- Name: index_user_account_associations_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_account_associations_replica_identity ON public.user_account_associations USING btree (root_account_id, id);


--
-- Name: index_user_lmgb_outcome_orderings; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_lmgb_outcome_orderings ON public.user_lmgb_outcome_orderings USING btree (learning_outcome_id, user_id, course_id);


--
-- Name: index_user_lmgb_outcome_orderings_on_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_lmgb_outcome_orderings_on_course_id ON public.user_lmgb_outcome_orderings USING btree (course_id);


--
-- Name: index_user_lmgb_outcome_orderings_on_learning_outcome_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_lmgb_outcome_orderings_on_learning_outcome_id ON public.user_lmgb_outcome_orderings USING btree (learning_outcome_id);


--
-- Name: index_user_lmgb_outcome_orderings_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_lmgb_outcome_orderings_on_user_id ON public.user_lmgb_outcome_orderings USING btree (user_id);


--
-- Name: index_user_lmgb_outcome_orderings_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_lmgb_outcome_orderings_replica_identity ON public.user_lmgb_outcome_orderings USING btree (root_account_id, id);


--
-- Name: index_user_merge_data_items_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_merge_data_items_on_user_id ON public.user_merge_data_items USING btree (user_id);


--
-- Name: index_user_merge_data_items_on_user_merge_data_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_merge_data_items_on_user_merge_data_id ON public.user_merge_data_items USING btree (user_merge_data_id);


--
-- Name: index_user_merge_data_on_from_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_merge_data_on_from_user_id ON public.user_merge_data USING btree (from_user_id);


--
-- Name: index_user_merge_data_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_merge_data_on_user_id ON public.user_merge_data USING btree (user_id);


--
-- Name: index_user_merge_data_records_on_context_id_and_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_merge_data_records_on_context_id_and_context_type ON public.user_merge_data_records USING btree (context_id, context_type, user_merge_data_id, previous_user_id);


--
-- Name: index_user_merge_data_records_on_user_merge_data_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_merge_data_records_on_user_merge_data_id ON public.user_merge_data_records USING btree (user_merge_data_id);


--
-- Name: index_user_notes_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_notes_on_created_by_id ON public.user_notes USING btree (created_by_id);


--
-- Name: index_user_notes_on_user_id_and_workflow_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_notes_on_user_id_and_workflow_state ON public.user_notes USING btree (user_id, workflow_state);


--
-- Name: index_user_notes_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_notes_replica_identity ON public.user_notes USING btree (root_account_id, id);


--
-- Name: index_user_observers_on_observer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_observers_on_observer_id ON public.user_observers USING btree (observer_id);


--
-- Name: index_user_observers_on_sis_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_observers_on_sis_batch_id ON public.user_observers USING btree (sis_batch_id) WHERE (sis_batch_id IS NOT NULL);


--
-- Name: index_user_observers_on_user_id_and_observer_id_and_ra; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_observers_on_user_id_and_observer_id_and_ra ON public.user_observers USING btree (user_id, observer_id, root_account_id);


--
-- Name: index_user_observers_on_workflow_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_observers_on_workflow_state ON public.user_observers USING btree (workflow_state);


--
-- Name: index_user_past_lti_ids_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_past_lti_ids_on_user_id ON public.user_past_lti_ids USING btree (user_id);


--
-- Name: index_user_past_lti_ids_on_user_lti_context_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_past_lti_ids_on_user_lti_context_id ON public.user_past_lti_ids USING btree (user_lti_context_id);


--
-- Name: index_user_past_lti_ids_on_user_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_past_lti_ids_on_user_uuid ON public.user_past_lti_ids USING btree (user_uuid);


--
-- Name: index_user_preference_values_on_key_no_sub_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_preference_values_on_key_no_sub_key ON public.user_preference_values USING btree (user_id, key) WHERE (sub_key IS NULL);


--
-- Name: index_user_preference_values_on_keys; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_preference_values_on_keys ON public.user_preference_values USING btree (user_id, key, sub_key);


--
-- Name: index_user_profile_links_on_user_profile_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_profile_links_on_user_profile_id ON public.user_profile_links USING btree (user_profile_id) WHERE (user_profile_id IS NOT NULL);


--
-- Name: index_user_profiles_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_profiles_on_user_id ON public.user_profiles USING btree (user_id);


--
-- Name: index_user_services_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_services_on_user_id ON public.user_services USING btree (user_id);


--
-- Name: index_users_on_avatar_state_and_avatar_image_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_avatar_state_and_avatar_image_updated_at ON public.users USING btree (avatar_state, avatar_image_updated_at);


--
-- Name: index_users_on_lti_context_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_lti_context_id ON public.users USING btree (lti_context_id);


--
-- Name: index_users_on_merged_into_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_merged_into_user_id ON public.users USING btree (merged_into_user_id) WHERE (merged_into_user_id IS NOT NULL);


--
-- Name: index_users_on_sortable_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_sortable_name ON public.users USING btree (sortable_name COLLATE public."und-u-kn-true", id);


--
-- Name: index_users_on_turnitin_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_turnitin_id ON public.users USING btree (turnitin_id) WHERE (turnitin_id IS NOT NULL);


--
-- Name: index_users_on_unique_lti_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_unique_lti_id ON public.users USING btree (lti_id);


--
-- Name: index_users_on_unique_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_unique_uuid ON public.users USING btree (uuid);


--
-- Name: index_users_on_workflow_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_workflow_state ON public.users USING btree (workflow_state);


--
-- Name: index_users_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_replica_identity ON public.users USING btree (root_account_ids, id);


--
-- Name: index_versions_on_versionable_object_and_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_versions_on_versionable_object_and_number ON public.versions USING btree (versionable_id, versionable_type, number);


--
-- Name: index_viewed_submission_comments_on_submission_comment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_viewed_submission_comments_on_submission_comment_id ON public.viewed_submission_comments USING btree (submission_comment_id);


--
-- Name: index_viewed_submission_comments_user_comment; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_viewed_submission_comments_user_comment ON public.viewed_submission_comments USING btree (user_id, submission_comment_id);


--
-- Name: index_web_conference_participants_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_web_conference_participants_on_user_id ON public.web_conference_participants USING btree (user_id);


--
-- Name: index_web_conference_participants_on_web_conference_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_web_conference_participants_on_web_conference_id ON public.web_conference_participants USING btree (web_conference_id);


--
-- Name: index_web_conference_participants_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_web_conference_participants_replica_identity ON public.web_conference_participants USING btree (root_account_id, id);


--
-- Name: index_web_conferences_on_context_id_and_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_web_conferences_on_context_id_and_context_type ON public.web_conferences USING btree (context_id, context_type);


--
-- Name: index_web_conferences_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_web_conferences_on_user_id ON public.web_conferences USING btree (user_id);


--
-- Name: index_web_conferences_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_web_conferences_replica_identity ON public.web_conferences USING btree (root_account_id, id);


--
-- Name: index_wiki_page_lookups_on_wiki_page_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wiki_page_lookups_on_wiki_page_id ON public.wiki_page_lookups USING btree (wiki_page_id);


--
-- Name: index_wiki_page_lookups_replica_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_wiki_page_lookups_replica_identity ON public.wiki_page_lookups USING btree (root_account_id, id);


--
-- Name: index_wiki_pages_on_assignment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wiki_pages_on_assignment_id ON public.wiki_pages USING btree (assignment_id);


--
-- Name: index_wiki_pages_on_cloned_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wiki_pages_on_cloned_item_id ON public.wiki_pages USING btree (cloned_item_id) WHERE (cloned_item_id IS NOT NULL);


--
-- Name: index_wiki_pages_on_context_id_and_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wiki_pages_on_context_id_and_context_type ON public.wiki_pages USING btree (context_id, context_type);


--
-- Name: index_wiki_pages_on_current_lookup_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wiki_pages_on_current_lookup_id ON public.wiki_pages USING btree (current_lookup_id);


--
-- Name: index_wiki_pages_on_old_assignment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wiki_pages_on_old_assignment_id ON public.wiki_pages USING btree (old_assignment_id);


--
-- Name: index_wiki_pages_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wiki_pages_on_root_account_id ON public.wiki_pages USING btree (root_account_id);


--
-- Name: index_wiki_pages_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wiki_pages_on_user_id ON public.wiki_pages USING btree (user_id);


--
-- Name: index_wiki_pages_on_wiki_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wiki_pages_on_wiki_id ON public.wiki_pages USING btree (wiki_id);


--
-- Name: index_wiki_pages_on_wiki_id_and_todo_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wiki_pages_on_wiki_id_and_todo_date ON public.wiki_pages USING btree (wiki_id, todo_date) WHERE (todo_date IS NOT NULL);


--
-- Name: index_wikis_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wikis_on_root_account_id ON public.wikis USING btree (root_account_id);


--
-- Name: lor_artifact_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX lor_artifact_id_idx ON public.learning_outcome_results USING btree (artifact_id, artifact_type);


--
-- Name: media_object_id_locale; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX media_object_id_locale ON public.media_tracks USING btree (media_object_id, locale);


--
-- Name: messages_2025_18_communication_channel_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_2025_18_communication_channel_id_idx ON public.messages_2025_18 USING btree (communication_channel_id);


--
-- Name: messages_2025_18_context_id_context_type_notification_name__idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_2025_18_context_id_context_type_notification_name__idx ON public.messages_2025_18 USING btree (context_id, context_type, notification_name, "to", user_id);


--
-- Name: messages_2025_18_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_2025_18_created_at_idx ON public.messages_2025_18 USING btree (created_at);


--
-- Name: messages_2025_18_notification_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_2025_18_notification_id_idx ON public.messages_2025_18 USING btree (notification_id);


--
-- Name: messages_2025_18_root_account_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_2025_18_root_account_id_idx ON public.messages_2025_18 USING btree (root_account_id);


--
-- Name: messages_2025_18_sent_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_2025_18_sent_at_idx ON public.messages_2025_18 USING btree (sent_at) WHERE (sent_at IS NOT NULL);


--
-- Name: messages_2025_18_user_id_to_email_dispatch_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_2025_18_user_id_to_email_dispatch_at_idx ON public.messages_2025_18 USING btree (user_id, to_email, dispatch_at);


--
-- Name: messages_2025_19_communication_channel_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_2025_19_communication_channel_id_idx ON public.messages_2025_19 USING btree (communication_channel_id);


--
-- Name: messages_2025_19_context_id_context_type_notification_name__idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_2025_19_context_id_context_type_notification_name__idx ON public.messages_2025_19 USING btree (context_id, context_type, notification_name, "to", user_id);


--
-- Name: messages_2025_19_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_2025_19_created_at_idx ON public.messages_2025_19 USING btree (created_at);


--
-- Name: messages_2025_19_notification_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_2025_19_notification_id_idx ON public.messages_2025_19 USING btree (notification_id);


--
-- Name: messages_2025_19_root_account_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_2025_19_root_account_id_idx ON public.messages_2025_19 USING btree (root_account_id);


--
-- Name: messages_2025_19_sent_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_2025_19_sent_at_idx ON public.messages_2025_19 USING btree (sent_at) WHERE (sent_at IS NOT NULL);


--
-- Name: messages_2025_19_user_id_to_email_dispatch_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_2025_19_user_id_to_email_dispatch_at_idx ON public.messages_2025_19 USING btree (user_id, to_email, dispatch_at);


--
-- Name: messages_2025_20_communication_channel_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_2025_20_communication_channel_id_idx ON public.messages_2025_20 USING btree (communication_channel_id);


--
-- Name: messages_2025_20_context_id_context_type_notification_name__idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_2025_20_context_id_context_type_notification_name__idx ON public.messages_2025_20 USING btree (context_id, context_type, notification_name, "to", user_id);


--
-- Name: messages_2025_20_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_2025_20_created_at_idx ON public.messages_2025_20 USING btree (created_at);


--
-- Name: messages_2025_20_notification_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_2025_20_notification_id_idx ON public.messages_2025_20 USING btree (notification_id);


--
-- Name: messages_2025_20_root_account_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_2025_20_root_account_id_idx ON public.messages_2025_20 USING btree (root_account_id);


--
-- Name: messages_2025_20_sent_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_2025_20_sent_at_idx ON public.messages_2025_20 USING btree (sent_at) WHERE (sent_at IS NOT NULL);


--
-- Name: messages_2025_20_user_id_to_email_dispatch_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_2025_20_user_id_to_email_dispatch_at_idx ON public.messages_2025_20 USING btree (user_id, to_email, dispatch_at);


--
-- Name: n_strand_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX n_strand_index ON public.delayed_jobs USING btree (strand, next_in_strand, id) WHERE (strand IS NOT NULL);


--
-- Name: next_in_strand_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX next_in_strand_index ON public.delayed_jobs USING btree (strand, strand_order_override, id) WHERE (strand IS NOT NULL);


--
-- Name: observer_alert_thresholds_on_alert_type_and_observer_and_user; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX observer_alert_thresholds_on_alert_type_and_observer_and_user ON public.observer_alert_thresholds USING btree (alert_type, user_id, observer_id);


--
-- Name: product_family_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX product_family_uniqueness ON public.lti_product_families USING btree (product_code, vendor_code, root_account_id, developer_key_id);


--
-- Name: question_bank_id_and_position; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX question_bank_id_and_position ON public.assessment_questions USING btree (assessment_question_bank_id, "position");


--
-- Name: quiz_questions_quiz_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX quiz_questions_quiz_group_id ON public.quiz_questions USING btree (quiz_group_id);


--
-- Name: quiz_submission_events_2025_5_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX quiz_submission_events_2025_5_created_at_idx ON public.quiz_submission_events_2025_5 USING btree (created_at);


--
-- Name: quiz_submission_events_2025_5_quiz_submission_id_attempt_cr_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX quiz_submission_events_2025_5_quiz_submission_id_attempt_cr_idx ON public.quiz_submission_events_2025_5 USING btree (quiz_submission_id, attempt, created_at);


--
-- Name: quiz_submission_events_2025_5_root_account_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX quiz_submission_events_2025_5_root_account_id_idx ON public.quiz_submission_events_2025_5 USING btree (root_account_id);


--
-- Name: quiz_submission_events_2025_6_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX quiz_submission_events_2025_6_created_at_idx ON public.quiz_submission_events_2025_6 USING btree (created_at);


--
-- Name: quiz_submission_events_2025_6_quiz_submission_id_attempt_cr_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX quiz_submission_events_2025_6_quiz_submission_id_attempt_cr_idx ON public.quiz_submission_events_2025_6 USING btree (quiz_submission_id, attempt, created_at);


--
-- Name: quiz_submission_events_2025_6_root_account_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX quiz_submission_events_2025_6_root_account_id_idx ON public.quiz_submission_events_2025_6 USING btree (root_account_id);


--
-- Name: quiz_submission_events_2025_7_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX quiz_submission_events_2025_7_created_at_idx ON public.quiz_submission_events_2025_7 USING btree (created_at);


--
-- Name: quiz_submission_events_2025_7_quiz_submission_id_attempt_cr_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX quiz_submission_events_2025_7_quiz_submission_id_attempt_cr_idx ON public.quiz_submission_events_2025_7 USING btree (quiz_submission_id, attempt, created_at);


--
-- Name: quiz_submission_events_2025_7_root_account_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX quiz_submission_events_2025_7_root_account_id_idx ON public.quiz_submission_events_2025_7 USING btree (root_account_id);


--
-- Name: unique_index_on_context_and_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_index_on_context_and_slug ON public.wiki_page_lookups USING btree (context_id, context_type, slug);


--
-- Name: unique_index_on_entry_and_user; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_index_on_entry_and_user ON public.discussion_entry_drafts USING btree (discussion_entry_id, user_id);


--
-- Name: unique_index_on_root_entry_and_user; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_index_on_root_entry_and_user ON public.discussion_entry_drafts USING btree (root_entry_id, user_id) WHERE (discussion_entry_id IS NULL);


--
-- Name: unique_index_on_topic_and_user; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_index_on_topic_and_user ON public.discussion_entry_drafts USING btree (discussion_topic_id, user_id) WHERE ((discussion_entry_id IS NULL) AND (root_entry_id IS NULL));


--
-- Name: unique_submissions_and_canvadocs; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_submissions_and_canvadocs ON public.canvadocs_submissions USING btree (submission_id, canvadoc_id) WHERE (canvadoc_id IS NOT NULL);


--
-- Name: unique_submissions_and_crocodocs; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_submissions_and_crocodocs ON public.canvadocs_submissions USING btree (submission_id, crocodoc_document_id) WHERE (crocodoc_document_id IS NOT NULL);


--
-- Name: usage_rights_context_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX usage_rights_context_idx ON public.usage_rights USING btree (context_id, context_type);


--
-- Name: user_past_lti_ids_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX user_past_lti_ids_index ON public.user_past_lti_ids USING btree (user_id, context_id, context_type);


--
-- Name: versions_0_versionable_id_versionable_type_number_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX versions_0_versionable_id_versionable_type_number_idx ON public.versions_0 USING btree (versionable_id, versionable_type, number);


--
-- Name: versions_1_versionable_id_versionable_type_number_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX versions_1_versionable_id_versionable_type_number_idx ON public.versions_1 USING btree (versionable_id, versionable_type, number);


--
-- Name: ws_sa; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ws_sa ON public.delayed_messages USING btree (workflow_state, send_at);


--
-- Name: attachments attachment_before_insert_verify_active_folder__tr; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER attachment_before_insert_verify_active_folder__tr BEFORE INSERT ON public.attachments FOR EACH ROW EXECUTE FUNCTION public.attachment_before_insert_verify_active_folder__tr_fn();


--
-- Name: delayed_jobs delayed_jobs_after_delete_row_tr; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER delayed_jobs_after_delete_row_tr AFTER DELETE ON public.delayed_jobs FOR EACH ROW WHEN ((((old.strand IS NOT NULL) OR (old.singleton IS NOT NULL)) AND (old.next_in_strand = true))) EXECUTE FUNCTION public.delayed_jobs_after_delete_row_tr_fn();


--
-- Name: delayed_jobs delayed_jobs_before_insert_row_tr; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER delayed_jobs_before_insert_row_tr BEFORE INSERT ON public.delayed_jobs FOR EACH ROW WHEN (((new.strand IS NOT NULL) OR (new.singleton IS NOT NULL))) EXECUTE FUNCTION public.delayed_jobs_before_insert_row_tr_fn();


--
-- Name: delayed_jobs delayed_jobs_before_unlock_delete_conflicting_singletons_row_tr; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER delayed_jobs_before_unlock_delete_conflicting_singletons_row_tr BEFORE UPDATE ON public.delayed_jobs FOR EACH ROW WHEN (((old.singleton IS NOT NULL) AND ((old.singleton)::text = (new.singleton)::text) AND (old.locked_by IS NOT NULL) AND (new.locked_by IS NULL))) EXECUTE FUNCTION public.delayed_jobs_before_unlock_delete_conflicting_singletons_row_fn();


--
-- Name: folders folder_before_insert_verify_active_parent_folder__tr; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER folder_before_insert_verify_active_parent_folder__tr BEFORE INSERT ON public.folders FOR EACH ROW EXECUTE FUNCTION public.folder_before_insert_verify_active_parent_folder__tr_fn();


--
-- Name: abstract_courses guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.abstract_courses REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: access_tokens guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.access_tokens REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: account_notification_roles guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.account_notification_roles REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: account_notifications guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.account_notifications REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: account_report_rows guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.account_report_rows REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: account_report_runners guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.account_report_runners REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: account_reports guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.account_reports REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: account_users guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.account_users REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: accounts guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.accounts REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: alert_criteria guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.alert_criteria REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: alerts guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.alerts REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: anonymous_or_moderation_events guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.anonymous_or_moderation_events REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: appointment_group_contexts guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.appointment_group_contexts REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: appointment_group_sub_contexts guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.appointment_group_sub_contexts REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: appointment_groups guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.appointment_groups REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: assessment_question_bank_users guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.assessment_question_bank_users REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: assessment_question_banks guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.assessment_question_banks REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: assessment_questions guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.assessment_questions REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: assessment_requests guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.assessment_requests REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: asset_user_accesses guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.asset_user_accesses REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: assignment_configuration_tool_lookups guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.assignment_configuration_tool_lookups REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: assignment_groups guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.assignment_groups REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: assignment_override_students guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.assignment_override_students REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: assignment_overrides guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.assignment_overrides REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: assignments guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.assignments REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: attachment_associations guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.attachment_associations REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: attachment_upload_statuses guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.attachment_upload_statuses REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: attachments guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.attachments REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: aua_logs_0 guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.aua_logs_0 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: aua_logs_1 guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.aua_logs_1 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: aua_logs_2 guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.aua_logs_2 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: aua_logs_3 guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.aua_logs_3 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: aua_logs_4 guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.aua_logs_4 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: aua_logs_5 guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.aua_logs_5 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: aua_logs_6 guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.aua_logs_6 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: auditor_authentication_records guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.auditor_authentication_records REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: auditor_authentication_records_2025_5 guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.auditor_authentication_records_2025_5 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: auditor_authentication_records_2025_6 guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.auditor_authentication_records_2025_6 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: auditor_course_records guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.auditor_course_records REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: auditor_course_records_2025_5 guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.auditor_course_records_2025_5 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: auditor_course_records_2025_6 guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.auditor_course_records_2025_6 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: auditor_feature_flag_records guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.auditor_feature_flag_records REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: auditor_feature_flag_records_2025_5 guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.auditor_feature_flag_records_2025_5 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: auditor_feature_flag_records_2025_6 guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.auditor_feature_flag_records_2025_6 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: auditor_grade_change_records guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.auditor_grade_change_records REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: auditor_grade_change_records_2025_5 guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.auditor_grade_change_records_2025_5 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: auditor_grade_change_records_2025_6 guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.auditor_grade_change_records_2025_6 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: auditor_pseudonym_records guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.auditor_pseudonym_records REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: auditor_pseudonym_records_2025_5 guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.auditor_pseudonym_records_2025_5 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: auditor_pseudonym_records_2025_6 guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.auditor_pseudonym_records_2025_6 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: authentication_providers guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.authentication_providers REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: blackout_dates guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.blackout_dates REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: block_editors guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.block_editors REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: bookmarks_bookmarks guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.bookmarks_bookmarks REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: brand_configs guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.brand_configs REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: calendar_events guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.calendar_events REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: canvadocs guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.canvadocs REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: canvadocs_annotation_contexts guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.canvadocs_annotation_contexts REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: canvadocs_submissions guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.canvadocs_submissions REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: canvas_metadata guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.canvas_metadata REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: cloned_items guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.cloned_items REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: collaborations guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.collaborations REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: collaborators guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.collaborators REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: comment_bank_items guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.comment_bank_items REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: communication_channels guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.communication_channels REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: conditional_release_assignment_set_actions guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.conditional_release_assignment_set_actions REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: conditional_release_assignment_set_associations guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.conditional_release_assignment_set_associations REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: conditional_release_assignment_sets guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.conditional_release_assignment_sets REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: conditional_release_rules guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.conditional_release_rules REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: conditional_release_scoring_ranges guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.conditional_release_scoring_ranges REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: content_exports guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.content_exports REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: content_migrations guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.content_migrations REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: content_participation_counts guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.content_participation_counts REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: content_participations guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.content_participations REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: content_shares guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.content_shares REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: content_tags guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.content_tags REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: context_external_tool_placements guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.context_external_tool_placements REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: context_external_tools guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.context_external_tools REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: context_module_progressions guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.context_module_progressions REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: context_modules guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.context_modules REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: conversation_batches guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.conversation_batches REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: conversation_message_participants guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.conversation_message_participants REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: conversation_messages guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.conversation_messages REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: conversation_participants guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.conversation_participants REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: conversations guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.conversations REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: course_account_associations guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.course_account_associations REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: course_pace_module_items guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.course_pace_module_items REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: course_paces guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.course_paces REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: course_score_statistics guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.course_score_statistics REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: course_sections guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.course_sections REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: courses guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.courses REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: crocodoc_documents guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.crocodoc_documents REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: csp_domains guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.csp_domains REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: custom_data guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.custom_data REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: custom_grade_statuses guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.custom_grade_statuses REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: custom_gradebook_column_data guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.custom_gradebook_column_data REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: custom_gradebook_columns guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.custom_gradebook_columns REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: delayed_jobs guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.delayed_jobs REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: delayed_messages guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.delayed_messages REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: delayed_notifications guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.delayed_notifications REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: developer_key_account_bindings guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.developer_key_account_bindings REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: developer_keys guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.developer_keys REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: discussion_entries guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.discussion_entries REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: discussion_entry_drafts guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.discussion_entry_drafts REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: discussion_entry_participants guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.discussion_entry_participants REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: discussion_entry_versions guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.discussion_entry_versions REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: discussion_topic_materialized_views guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.discussion_topic_materialized_views REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: discussion_topic_participants guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.discussion_topic_participants REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: discussion_topic_section_visibilities guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.discussion_topic_section_visibilities REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: discussion_topics guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.discussion_topics REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: enrollment_dates_overrides guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.enrollment_dates_overrides REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: enrollment_states guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.enrollment_states REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: enrollment_terms guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.enrollment_terms REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: enrollments guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.enrollments REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: eportfolio_categories guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.eportfolio_categories REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: eportfolio_entries guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.eportfolio_entries REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: eportfolios guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.eportfolios REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: epub_exports guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.epub_exports REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: error_reports guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.error_reports REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: event_stream_failures guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.event_stream_failures REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: external_feed_entries guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.external_feed_entries REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: external_feeds guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.external_feeds REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: external_integration_keys guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.external_integration_keys REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: failed_jobs guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.failed_jobs REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: favorites guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.favorites REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: feature_flags guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.feature_flags REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: folders guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.folders REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: gradebook_csvs guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.gradebook_csvs REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: gradebook_filters guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.gradebook_filters REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: gradebook_uploads guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.gradebook_uploads REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: grading_period_groups guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.grading_period_groups REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: grading_periods guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.grading_periods REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: grading_standards guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.grading_standards REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: group_and_membership_importers guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.group_and_membership_importers REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: group_categories guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.group_categories REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: group_memberships guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.group_memberships REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: groups guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.groups REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: ignores guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.ignores REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: late_policies guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.late_policies REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: learning_outcome_groups guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.learning_outcome_groups REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: learning_outcome_question_results guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.learning_outcome_question_results REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: learning_outcome_results guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.learning_outcome_results REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: learning_outcomes guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.learning_outcomes REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: live_assessments_assessments guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.live_assessments_assessments REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: live_assessments_results guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.live_assessments_results REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: live_assessments_submissions guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.live_assessments_submissions REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: lti_ims_registrations guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.lti_ims_registrations REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: lti_line_items guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.lti_line_items REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: lti_links guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.lti_links REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: lti_message_handlers guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.lti_message_handlers REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: lti_product_families guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.lti_product_families REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: lti_resource_handlers guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.lti_resource_handlers REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: lti_resource_links guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.lti_resource_links REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: lti_resource_placements guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.lti_resource_placements REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: lti_results guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.lti_results REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: lti_tool_configurations guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.lti_tool_configurations REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: lti_tool_consumer_profiles guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.lti_tool_consumer_profiles REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: lti_tool_proxies guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.lti_tool_proxies REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: lti_tool_proxy_bindings guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.lti_tool_proxy_bindings REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: lti_tool_settings guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.lti_tool_settings REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: master_courses_child_content_tags guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.master_courses_child_content_tags REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: master_courses_child_subscriptions guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.master_courses_child_subscriptions REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: master_courses_master_content_tags guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.master_courses_master_content_tags REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: master_courses_master_migrations guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.master_courses_master_migrations REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: master_courses_master_templates guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.master_courses_master_templates REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: master_courses_migration_results guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.master_courses_migration_results REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: media_objects guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.media_objects REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: media_tracks guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.media_tracks REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: mentions guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.mentions REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: messages guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.messages REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: messages_2025_18 guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.messages_2025_18 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: messages_2025_19 guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.messages_2025_19 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: messages_2025_20 guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.messages_2025_20 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: microsoft_sync_groups guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.microsoft_sync_groups REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: microsoft_sync_partial_sync_changes guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.microsoft_sync_partial_sync_changes REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: microsoft_sync_user_mappings guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.microsoft_sync_user_mappings REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: migration_issues guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.migration_issues REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: moderated_grading_provisional_grades guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.moderated_grading_provisional_grades REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: moderated_grading_selections guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.moderated_grading_selections REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: moderation_graders guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.moderation_graders REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: notification_endpoints guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.notification_endpoints REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: notification_policies guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.notification_policies REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: notification_policy_overrides guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.notification_policy_overrides REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: notifications guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.notifications REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: oauth_requests guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.oauth_requests REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: observer_alert_thresholds guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.observer_alert_thresholds REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: observer_alerts guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.observer_alerts REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: observer_pairing_codes guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.observer_pairing_codes REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: one_time_passwords guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.one_time_passwords REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: originality_reports guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.originality_reports REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: outcome_calculation_methods guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.outcome_calculation_methods REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: outcome_friendly_descriptions guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.outcome_friendly_descriptions REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: outcome_import_errors guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.outcome_import_errors REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: outcome_imports guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.outcome_imports REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: outcome_proficiencies guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.outcome_proficiencies REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: outcome_proficiency_ratings guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.outcome_proficiency_ratings REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: page_comments guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.page_comments REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: page_views guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.page_views REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: parallel_importers guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.parallel_importers REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: planner_notes guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.planner_notes REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: planner_overrides guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.planner_overrides REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: plugin_settings guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.plugin_settings REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: polling_poll_choices guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.polling_poll_choices REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: polling_poll_sessions guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.polling_poll_sessions REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: polling_poll_submissions guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.polling_poll_submissions REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: polling_polls guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.polling_polls REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: post_policies guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.post_policies REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: profiles guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.profiles REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: progresses guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.progresses REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: pseudonyms guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.pseudonyms REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: purgatories guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.purgatories REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: quiz_groups guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.quiz_groups REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: quiz_migration_alerts guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.quiz_migration_alerts REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: quiz_question_regrades guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.quiz_question_regrades REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: quiz_questions guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.quiz_questions REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: quiz_regrade_runs guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.quiz_regrade_runs REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: quiz_regrades guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.quiz_regrades REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: quiz_statistics guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.quiz_statistics REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: quiz_submission_events guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.quiz_submission_events REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: quiz_submission_events_2025_5 guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.quiz_submission_events_2025_5 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: quiz_submission_events_2025_6 guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.quiz_submission_events_2025_6 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: quiz_submission_events_2025_7 guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.quiz_submission_events_2025_7 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: quiz_submission_snapshots guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.quiz_submission_snapshots REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: quiz_submissions guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.quiz_submissions REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: quizzes guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.quizzes REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: report_snapshots guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.report_snapshots REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: role_overrides guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.role_overrides REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: roles guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.roles REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: rubric_assessments guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.rubric_assessments REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: rubric_associations guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.rubric_associations REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: rubric_criteria guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.rubric_criteria REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: rubrics guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.rubrics REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: scheduled_smart_alerts guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.scheduled_smart_alerts REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: score_metadata guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.score_metadata REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: score_statistics guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.score_statistics REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: scores guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.scores REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: session_persistence_tokens guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.session_persistence_tokens REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: sessions guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.sessions REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: settings guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.settings REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: shared_brand_configs guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.shared_brand_configs REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: sis_batch_errors guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.sis_batch_errors REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: sis_batch_roll_back_data guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.sis_batch_roll_back_data REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: sis_batches guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.sis_batches REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: sis_post_grades_statuses guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.sis_post_grades_statuses REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: standard_grade_statuses guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.standard_grade_statuses REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: stream_item_instances guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.stream_item_instances REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: stream_items guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.stream_items REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: submission_comments guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.submission_comments REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: submission_draft_attachments guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.submission_draft_attachments REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: submission_drafts guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.submission_drafts REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: submission_versions guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.submission_versions REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: submissions guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.submissions REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: switchman_shards guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.switchman_shards REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: temporary_enrollment_pairings guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.temporary_enrollment_pairings REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: terms_of_service_contents guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.terms_of_service_contents REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: terms_of_services guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.terms_of_services REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: thumbnails guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.thumbnails REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: usage_rights guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.usage_rights REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: user_account_associations guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.user_account_associations REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: user_lmgb_outcome_orderings guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.user_lmgb_outcome_orderings REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: user_merge_data guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.user_merge_data REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: user_merge_data_items guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.user_merge_data_items REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: user_merge_data_records guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.user_merge_data_records REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: user_notes guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.user_notes REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: user_observers guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.user_observers REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: user_past_lti_ids guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.user_past_lti_ids REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: user_preference_values guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.user_preference_values REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: user_profile_links guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.user_profile_links REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: user_profiles guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.user_profiles REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: user_services guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.user_services REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: users guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.users REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: versions guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.versions REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: versions_0 guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.versions_0 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: versions_1 guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.versions_1 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: viewed_submission_comments guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.viewed_submission_comments REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: web_conference_participants guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.web_conference_participants REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: web_conferences guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.web_conferences REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: wiki_page_lookups guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.wiki_page_lookups REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: wiki_pages guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.wiki_pages REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: wikis guard_excessive_deletes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_deletes AFTER DELETE ON public.wikis REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: abstract_courses guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.abstract_courses REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: access_tokens guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.access_tokens REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: account_notification_roles guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.account_notification_roles REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: account_notifications guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.account_notifications REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: account_report_rows guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.account_report_rows REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: account_report_runners guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.account_report_runners REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: account_reports guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.account_reports REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: account_users guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.account_users REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: accounts guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.accounts REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: alert_criteria guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.alert_criteria REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: alerts guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.alerts REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: anonymous_or_moderation_events guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.anonymous_or_moderation_events REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: appointment_group_contexts guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.appointment_group_contexts REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: appointment_group_sub_contexts guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.appointment_group_sub_contexts REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: appointment_groups guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.appointment_groups REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: assessment_question_bank_users guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.assessment_question_bank_users REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: assessment_question_banks guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.assessment_question_banks REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: assessment_questions guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.assessment_questions REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: assessment_requests guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.assessment_requests REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: asset_user_accesses guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.asset_user_accesses REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: assignment_configuration_tool_lookups guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.assignment_configuration_tool_lookups REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: assignment_groups guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.assignment_groups REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: assignment_override_students guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.assignment_override_students REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: assignment_overrides guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.assignment_overrides REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: assignments guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.assignments REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: attachment_associations guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.attachment_associations REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: attachment_upload_statuses guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.attachment_upload_statuses REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: attachments guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.attachments REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: aua_logs_0 guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.aua_logs_0 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: aua_logs_1 guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.aua_logs_1 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: aua_logs_2 guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.aua_logs_2 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: aua_logs_3 guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.aua_logs_3 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: aua_logs_4 guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.aua_logs_4 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: aua_logs_5 guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.aua_logs_5 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: aua_logs_6 guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.aua_logs_6 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: auditor_authentication_records guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.auditor_authentication_records REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: auditor_authentication_records_2025_5 guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.auditor_authentication_records_2025_5 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: auditor_authentication_records_2025_6 guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.auditor_authentication_records_2025_6 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: auditor_course_records guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.auditor_course_records REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: auditor_course_records_2025_5 guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.auditor_course_records_2025_5 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: auditor_course_records_2025_6 guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.auditor_course_records_2025_6 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: auditor_feature_flag_records guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.auditor_feature_flag_records REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: auditor_feature_flag_records_2025_5 guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.auditor_feature_flag_records_2025_5 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: auditor_feature_flag_records_2025_6 guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.auditor_feature_flag_records_2025_6 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: auditor_grade_change_records guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.auditor_grade_change_records REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: auditor_grade_change_records_2025_5 guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.auditor_grade_change_records_2025_5 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: auditor_grade_change_records_2025_6 guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.auditor_grade_change_records_2025_6 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: auditor_pseudonym_records guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.auditor_pseudonym_records REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: auditor_pseudonym_records_2025_5 guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.auditor_pseudonym_records_2025_5 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: auditor_pseudonym_records_2025_6 guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.auditor_pseudonym_records_2025_6 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: authentication_providers guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.authentication_providers REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: blackout_dates guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.blackout_dates REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: block_editors guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.block_editors REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: bookmarks_bookmarks guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.bookmarks_bookmarks REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: brand_configs guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.brand_configs REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: calendar_events guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.calendar_events REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: canvadocs guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.canvadocs REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: canvadocs_annotation_contexts guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.canvadocs_annotation_contexts REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: canvadocs_submissions guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.canvadocs_submissions REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: canvas_metadata guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.canvas_metadata REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: cloned_items guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.cloned_items REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: collaborations guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.collaborations REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: collaborators guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.collaborators REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: comment_bank_items guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.comment_bank_items REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: communication_channels guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.communication_channels REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: conditional_release_assignment_set_actions guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.conditional_release_assignment_set_actions REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: conditional_release_assignment_set_associations guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.conditional_release_assignment_set_associations REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: conditional_release_assignment_sets guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.conditional_release_assignment_sets REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: conditional_release_rules guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.conditional_release_rules REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: conditional_release_scoring_ranges guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.conditional_release_scoring_ranges REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: content_exports guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.content_exports REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: content_migrations guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.content_migrations REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: content_participation_counts guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.content_participation_counts REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: content_participations guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.content_participations REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: content_shares guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.content_shares REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: content_tags guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.content_tags REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: context_external_tool_placements guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.context_external_tool_placements REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: context_external_tools guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.context_external_tools REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: context_module_progressions guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.context_module_progressions REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: context_modules guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.context_modules REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: conversation_batches guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.conversation_batches REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: conversation_message_participants guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.conversation_message_participants REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: conversation_messages guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.conversation_messages REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: conversation_participants guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.conversation_participants REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: conversations guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.conversations REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: course_account_associations guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.course_account_associations REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: course_pace_module_items guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.course_pace_module_items REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: course_paces guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.course_paces REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: course_score_statistics guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.course_score_statistics REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: course_sections guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.course_sections REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: courses guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.courses REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: crocodoc_documents guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.crocodoc_documents REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: csp_domains guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.csp_domains REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: custom_data guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.custom_data REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: custom_grade_statuses guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.custom_grade_statuses REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: custom_gradebook_column_data guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.custom_gradebook_column_data REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: custom_gradebook_columns guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.custom_gradebook_columns REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: delayed_jobs guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.delayed_jobs REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: delayed_messages guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.delayed_messages REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: delayed_notifications guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.delayed_notifications REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: developer_key_account_bindings guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.developer_key_account_bindings REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: developer_keys guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.developer_keys REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: discussion_entries guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.discussion_entries REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: discussion_entry_drafts guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.discussion_entry_drafts REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: discussion_entry_participants guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.discussion_entry_participants REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: discussion_entry_versions guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.discussion_entry_versions REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: discussion_topic_materialized_views guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.discussion_topic_materialized_views REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: discussion_topic_participants guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.discussion_topic_participants REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: discussion_topic_section_visibilities guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.discussion_topic_section_visibilities REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: discussion_topics guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.discussion_topics REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: enrollment_dates_overrides guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.enrollment_dates_overrides REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: enrollment_states guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.enrollment_states REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: enrollment_terms guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.enrollment_terms REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: enrollments guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.enrollments REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: eportfolio_categories guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.eportfolio_categories REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: eportfolio_entries guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.eportfolio_entries REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: eportfolios guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.eportfolios REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: epub_exports guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.epub_exports REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: error_reports guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.error_reports REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: event_stream_failures guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.event_stream_failures REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: external_feed_entries guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.external_feed_entries REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: external_feeds guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.external_feeds REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: external_integration_keys guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.external_integration_keys REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: failed_jobs guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.failed_jobs REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: favorites guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.favorites REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: feature_flags guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.feature_flags REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: folders guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.folders REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: gradebook_csvs guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.gradebook_csvs REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: gradebook_filters guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.gradebook_filters REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: gradebook_uploads guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.gradebook_uploads REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: grading_period_groups guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.grading_period_groups REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: grading_periods guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.grading_periods REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: grading_standards guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.grading_standards REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: group_and_membership_importers guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.group_and_membership_importers REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: group_categories guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.group_categories REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: group_memberships guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.group_memberships REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: groups guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.groups REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: ignores guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.ignores REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: late_policies guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.late_policies REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: learning_outcome_groups guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.learning_outcome_groups REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: learning_outcome_question_results guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.learning_outcome_question_results REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: learning_outcome_results guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.learning_outcome_results REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: learning_outcomes guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.learning_outcomes REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: live_assessments_assessments guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.live_assessments_assessments REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: live_assessments_results guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.live_assessments_results REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: live_assessments_submissions guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.live_assessments_submissions REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: lti_ims_registrations guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.lti_ims_registrations REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: lti_line_items guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.lti_line_items REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: lti_links guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.lti_links REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: lti_message_handlers guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.lti_message_handlers REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: lti_product_families guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.lti_product_families REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: lti_resource_handlers guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.lti_resource_handlers REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: lti_resource_links guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.lti_resource_links REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: lti_resource_placements guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.lti_resource_placements REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: lti_results guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.lti_results REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: lti_tool_configurations guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.lti_tool_configurations REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: lti_tool_consumer_profiles guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.lti_tool_consumer_profiles REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: lti_tool_proxies guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.lti_tool_proxies REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: lti_tool_proxy_bindings guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.lti_tool_proxy_bindings REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: lti_tool_settings guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.lti_tool_settings REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: master_courses_child_content_tags guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.master_courses_child_content_tags REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: master_courses_child_subscriptions guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.master_courses_child_subscriptions REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: master_courses_master_content_tags guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.master_courses_master_content_tags REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: master_courses_master_migrations guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.master_courses_master_migrations REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: master_courses_master_templates guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.master_courses_master_templates REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: master_courses_migration_results guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.master_courses_migration_results REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: media_objects guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.media_objects REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: media_tracks guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.media_tracks REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: mentions guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.mentions REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: messages guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.messages REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: messages_2025_18 guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.messages_2025_18 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: messages_2025_19 guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.messages_2025_19 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: messages_2025_20 guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.messages_2025_20 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: microsoft_sync_groups guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.microsoft_sync_groups REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: microsoft_sync_partial_sync_changes guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.microsoft_sync_partial_sync_changes REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: microsoft_sync_user_mappings guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.microsoft_sync_user_mappings REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: migration_issues guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.migration_issues REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: moderated_grading_provisional_grades guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.moderated_grading_provisional_grades REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: moderated_grading_selections guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.moderated_grading_selections REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: moderation_graders guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.moderation_graders REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: notification_endpoints guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.notification_endpoints REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: notification_policies guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.notification_policies REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: notification_policy_overrides guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.notification_policy_overrides REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: notifications guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.notifications REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: oauth_requests guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.oauth_requests REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: observer_alert_thresholds guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.observer_alert_thresholds REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: observer_alerts guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.observer_alerts REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: observer_pairing_codes guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.observer_pairing_codes REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: one_time_passwords guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.one_time_passwords REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: originality_reports guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.originality_reports REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: outcome_calculation_methods guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.outcome_calculation_methods REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: outcome_friendly_descriptions guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.outcome_friendly_descriptions REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: outcome_import_errors guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.outcome_import_errors REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: outcome_imports guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.outcome_imports REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: outcome_proficiencies guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.outcome_proficiencies REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: outcome_proficiency_ratings guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.outcome_proficiency_ratings REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: page_comments guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.page_comments REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: page_views guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.page_views REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: parallel_importers guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.parallel_importers REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: planner_notes guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.planner_notes REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: planner_overrides guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.planner_overrides REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: plugin_settings guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.plugin_settings REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: polling_poll_choices guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.polling_poll_choices REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: polling_poll_sessions guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.polling_poll_sessions REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: polling_poll_submissions guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.polling_poll_submissions REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: polling_polls guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.polling_polls REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: post_policies guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.post_policies REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: profiles guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.profiles REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: progresses guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.progresses REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: pseudonyms guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.pseudonyms REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: purgatories guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.purgatories REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: quiz_groups guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.quiz_groups REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: quiz_migration_alerts guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.quiz_migration_alerts REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: quiz_question_regrades guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.quiz_question_regrades REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: quiz_questions guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.quiz_questions REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: quiz_regrade_runs guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.quiz_regrade_runs REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: quiz_regrades guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.quiz_regrades REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: quiz_statistics guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.quiz_statistics REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: quiz_submission_events guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.quiz_submission_events REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: quiz_submission_events_2025_5 guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.quiz_submission_events_2025_5 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: quiz_submission_events_2025_6 guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.quiz_submission_events_2025_6 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: quiz_submission_events_2025_7 guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.quiz_submission_events_2025_7 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: quiz_submission_snapshots guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.quiz_submission_snapshots REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: quiz_submissions guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.quiz_submissions REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: quizzes guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.quizzes REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: report_snapshots guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.report_snapshots REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: role_overrides guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.role_overrides REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: roles guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.roles REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: rubric_assessments guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.rubric_assessments REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: rubric_associations guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.rubric_associations REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: rubric_criteria guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.rubric_criteria REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: rubrics guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.rubrics REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: scheduled_smart_alerts guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.scheduled_smart_alerts REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: score_metadata guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.score_metadata REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: score_statistics guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.score_statistics REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: scores guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.scores REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: session_persistence_tokens guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.session_persistence_tokens REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: sessions guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.sessions REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: settings guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.settings REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: shared_brand_configs guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.shared_brand_configs REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: sis_batch_errors guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.sis_batch_errors REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: sis_batch_roll_back_data guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.sis_batch_roll_back_data REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: sis_batches guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.sis_batches REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: sis_post_grades_statuses guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.sis_post_grades_statuses REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: standard_grade_statuses guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.standard_grade_statuses REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: stream_item_instances guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.stream_item_instances REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: stream_items guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.stream_items REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: submission_comments guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.submission_comments REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: submission_draft_attachments guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.submission_draft_attachments REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: submission_drafts guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.submission_drafts REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: submission_versions guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.submission_versions REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: submissions guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.submissions REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: switchman_shards guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.switchman_shards REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: temporary_enrollment_pairings guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.temporary_enrollment_pairings REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: terms_of_service_contents guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.terms_of_service_contents REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: terms_of_services guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.terms_of_services REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: thumbnails guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.thumbnails REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: usage_rights guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.usage_rights REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: user_account_associations guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.user_account_associations REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: user_lmgb_outcome_orderings guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.user_lmgb_outcome_orderings REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: user_merge_data guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.user_merge_data REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: user_merge_data_items guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.user_merge_data_items REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: user_merge_data_records guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.user_merge_data_records REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: user_notes guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.user_notes REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: user_observers guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.user_observers REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: user_past_lti_ids guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.user_past_lti_ids REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: user_preference_values guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.user_preference_values REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: user_profile_links guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.user_profile_links REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: user_profiles guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.user_profiles REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: user_services guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.user_services REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: users guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.users REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: versions guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.versions REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: versions_0 guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.versions_0 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: versions_1 guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.versions_1 REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: viewed_submission_comments guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.viewed_submission_comments REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: web_conference_participants guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.web_conference_participants REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: web_conferences guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.web_conferences REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: wiki_page_lookups guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.wiki_page_lookups REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: wiki_pages guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.wiki_pages REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: wikis guard_excessive_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER guard_excessive_updates AFTER UPDATE ON public.wikis REFERENCING OLD TABLE AS oldtbl FOR EACH STATEMENT EXECUTE FUNCTION public.guard_excessive_updates();


--
-- Name: submission_comments submission_comment_after_delete_set_last_comment_at__tr; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER submission_comment_after_delete_set_last_comment_at__tr AFTER DELETE ON public.submission_comments FOR EACH ROW WHEN (((old.draft <> true) AND (old.provisional_grade_id IS NULL))) EXECUTE FUNCTION public.submission_comment_after_delete_set_last_comment_at__tr_fn();


--
-- Name: submission_comments submission_comment_after_insert_set_last_comment_at__tr; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER submission_comment_after_insert_set_last_comment_at__tr AFTER INSERT ON public.submission_comments FOR EACH ROW WHEN (((new.draft <> true) AND (new.provisional_grade_id IS NULL))) EXECUTE FUNCTION public.submission_comment_after_save_set_last_comment_at__tr_fn();


--
-- Name: submission_comments submission_comment_after_update_set_last_comment_at__tr; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER submission_comment_after_update_set_last_comment_at__tr AFTER UPDATE OF draft, provisional_grade_id ON public.submission_comments FOR EACH ROW EXECUTE FUNCTION public.submission_comment_after_save_set_last_comment_at__tr_fn();


--
-- Name: auditor_authentication_records_2025_6 fk_rails_009dc1503a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_authentication_records_2025_6
    ADD CONSTRAINT fk_rails_009dc1503a FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: quiz_submission_events_2025_7 fk_rails_00bd7a911c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_submission_events_2025_7
    ADD CONSTRAINT fk_rails_00bd7a911c FOREIGN KEY (quiz_submission_id) REFERENCES public.quiz_submissions(id);


--
-- Name: parallel_importers fk_rails_00ed13d8d6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parallel_importers
    ADD CONSTRAINT fk_rails_00ed13d8d6 FOREIGN KEY (attachment_id) REFERENCES public.attachments(id);


--
-- Name: master_courses_master_templates fk_rails_01b5db190c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.master_courses_master_templates
    ADD CONSTRAINT fk_rails_01b5db190c FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: polling_poll_submissions fk_rails_01fa2ef709; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.polling_poll_submissions
    ADD CONSTRAINT fk_rails_01fa2ef709 FOREIGN KEY (poll_session_id) REFERENCES public.polling_poll_sessions(id);


--
-- Name: sis_post_grades_statuses fk_rails_0221897d5f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sis_post_grades_statuses
    ADD CONSTRAINT fk_rails_0221897d5f FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: sis_batches fk_rails_0235dd4ff6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sis_batches
    ADD CONSTRAINT fk_rails_0235dd4ff6 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: group_categories fk_rails_0297915259; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_categories
    ADD CONSTRAINT fk_rails_0297915259 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: collaborators fk_rails_02c23caf02; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collaborators
    ADD CONSTRAINT fk_rails_02c23caf02 FOREIGN KEY (collaboration_id) REFERENCES public.collaborations(id);


--
-- Name: quiz_submissions fk_rails_03c29046c1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_submissions
    ADD CONSTRAINT fk_rails_03c29046c1 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: context_modules fk_rails_03f6fc5c38; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.context_modules
    ADD CONSTRAINT fk_rails_03f6fc5c38 FOREIGN KEY (cloned_item_id) REFERENCES public.cloned_items(id);


--
-- Name: lti_message_handlers fk_rails_0446c78346; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_message_handlers
    ADD CONSTRAINT fk_rails_0446c78346 FOREIGN KEY (resource_handler_id) REFERENCES public.lti_resource_handlers(id);


--
-- Name: quiz_submissions fk_rails_04850db4b4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_submissions
    ADD CONSTRAINT fk_rails_04850db4b4 FOREIGN KEY (user_id) REFERENCES public.users(id) DEFERRABLE;


--
-- Name: content_migrations fk_rails_04f446621a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_migrations
    ADD CONSTRAINT fk_rails_04f446621a FOREIGN KEY (child_subscription_id) REFERENCES public.master_courses_child_subscriptions(id);


--
-- Name: comment_bank_items fk_rails_054ffaf73d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comment_bank_items
    ADD CONSTRAINT fk_rails_054ffaf73d FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: moderated_grading_selections fk_rails_05e761621e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.moderated_grading_selections
    ADD CONSTRAINT fk_rails_05e761621e FOREIGN KEY (student_id) REFERENCES public.users(id);


--
-- Name: notification_policies fk_rails_065136b4a1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_policies
    ADD CONSTRAINT fk_rails_065136b4a1 FOREIGN KEY (communication_channel_id) REFERENCES public.communication_channels(id);


--
-- Name: submission_drafts fk_rails_0694e3073c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submission_drafts
    ADD CONSTRAINT fk_rails_0694e3073c FOREIGN KEY (submission_id) REFERENCES public.submissions(id);


--
-- Name: media_objects fk_rails_06a85e3af6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media_objects
    ADD CONSTRAINT fk_rails_06a85e3af6 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: auditor_grade_change_records_2025_6 fk_rails_07ca64d8ab; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_grade_change_records_2025_6
    ADD CONSTRAINT fk_rails_07ca64d8ab FOREIGN KEY (submission_id) REFERENCES public.submissions(id);


--
-- Name: sis_post_grades_statuses fk_rails_07ef291b5d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sis_post_grades_statuses
    ADD CONSTRAINT fk_rails_07ef291b5d FOREIGN KEY (course_section_id) REFERENCES public.course_sections(id);


--
-- Name: content_exports fk_rails_08b467f95d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_exports
    ADD CONSTRAINT fk_rails_08b467f95d FOREIGN KEY (attachment_id) REFERENCES public.attachments(id);


--
-- Name: late_policies fk_rails_09f671532d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.late_policies
    ADD CONSTRAINT fk_rails_09f671532d FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: lti_ims_registrations fk_rails_0a76a6183d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_ims_registrations
    ADD CONSTRAINT fk_rails_0a76a6183d FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: gradebook_filters fk_rails_0a7dce7c80; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gradebook_filters
    ADD CONSTRAINT fk_rails_0a7dce7c80 FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: content_tags fk_rails_0ad9c826f2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_tags
    ADD CONSTRAINT fk_rails_0ad9c826f2 FOREIGN KEY (context_module_id) REFERENCES public.context_modules(id);


--
-- Name: discussion_topics fk_rails_0b0ccee25f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_topics
    ADD CONSTRAINT fk_rails_0b0ccee25f FOREIGN KEY (group_category_id) REFERENCES public.group_categories(id);


--
-- Name: conditional_release_assignment_sets fk_rails_0c8dc99f75; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conditional_release_assignment_sets
    ADD CONSTRAINT fk_rails_0c8dc99f75 FOREIGN KEY (scoring_range_id) REFERENCES public.conditional_release_scoring_ranges(id);


--
-- Name: calendar_events fk_rails_0e82f26e3c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendar_events
    ADD CONSTRAINT fk_rails_0e82f26e3c FOREIGN KEY (parent_calendar_event_id) REFERENCES public.calendar_events(id);


--
-- Name: canvadocs fk_rails_0e9b385b60; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.canvadocs
    ADD CONSTRAINT fk_rails_0e9b385b60 FOREIGN KEY (attachment_id) REFERENCES public.attachments(id);


--
-- Name: pseudonyms fk_rails_0f9b2ab873; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pseudonyms
    ADD CONSTRAINT fk_rails_0f9b2ab873 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: learning_outcome_results fk_rails_10267bb129; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.learning_outcome_results
    ADD CONSTRAINT fk_rails_10267bb129 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: outcome_proficiencies fk_rails_109e184e08; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outcome_proficiencies
    ADD CONSTRAINT fk_rails_109e184e08 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: submissions fk_rails_11ec1c51e8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submissions
    ADD CONSTRAINT fk_rails_11ec1c51e8 FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- Name: group_memberships fk_rails_1208c3cc2d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_memberships
    ADD CONSTRAINT fk_rails_1208c3cc2d FOREIGN KEY (sis_batch_id) REFERENCES public.sis_batches(id);


--
-- Name: course_paces fk_rails_12fc8e8331; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_paces
    ADD CONSTRAINT fk_rails_12fc8e8331 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: page_views fk_rails_13a4e75c00; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.page_views
    ADD CONSTRAINT fk_rails_13a4e75c00 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: polling_poll_sessions fk_rails_13d9535afd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.polling_poll_sessions
    ADD CONSTRAINT fk_rails_13d9535afd FOREIGN KEY (course_section_id) REFERENCES public.course_sections(id);


--
-- Name: master_courses_child_content_tags fk_rails_1421b96805; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.master_courses_child_content_tags
    ADD CONSTRAINT fk_rails_1421b96805 FOREIGN KEY (child_subscription_id) REFERENCES public.master_courses_child_subscriptions(id);


--
-- Name: group_memberships fk_rails_14271168a1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_memberships
    ADD CONSTRAINT fk_rails_14271168a1 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: auditor_authentication_records fk_rails_150aa17e55; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_authentication_records
    ADD CONSTRAINT fk_rails_150aa17e55 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: wiki_pages fk_rails_154906ae4a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wiki_pages
    ADD CONSTRAINT fk_rails_154906ae4a FOREIGN KEY (cloned_item_id) REFERENCES public.cloned_items(id);


--
-- Name: auditor_pseudonym_records_2025_5 fk_rails_15fbfa8d83; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_pseudonym_records_2025_5
    ADD CONSTRAINT fk_rails_15fbfa8d83 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: content_shares fk_rails_16c705c4c6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_shares
    ADD CONSTRAINT fk_rails_16c705c4c6 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: outcome_import_errors fk_rails_172fb97705; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outcome_import_errors
    ADD CONSTRAINT fk_rails_172fb97705 FOREIGN KEY (outcome_import_id) REFERENCES public.outcome_imports(id);


--
-- Name: auditor_authentication_records_2025_6 fk_rails_185536c7ac; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_authentication_records_2025_6
    ADD CONSTRAINT fk_rails_185536c7ac FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: courses fk_rails_187ebba5f6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT fk_rails_187ebba5f6 FOREIGN KEY (sis_batch_id) REFERENCES public.sis_batches(id);


--
-- Name: auditor_authentication_records fk_rails_191f85fb7d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_authentication_records
    ADD CONSTRAINT fk_rails_191f85fb7d FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: auditor_course_records_2025_5 fk_rails_1955b8f8c6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_course_records_2025_5
    ADD CONSTRAINT fk_rails_1955b8f8c6 FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: microsoft_sync_partial_sync_changes fk_rails_195cffa827; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.microsoft_sync_partial_sync_changes
    ADD CONSTRAINT fk_rails_195cffa827 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: observer_alert_thresholds fk_rails_197b88ba34; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.observer_alert_thresholds
    ADD CONSTRAINT fk_rails_197b88ba34 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: discussion_entry_drafts fk_rails_1a148cca38; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_entry_drafts
    ADD CONSTRAINT fk_rails_1a148cca38 FOREIGN KEY (discussion_topic_id) REFERENCES public.discussion_topics(id);


--
-- Name: assignment_overrides fk_rails_1b328f175b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_overrides
    ADD CONSTRAINT fk_rails_1b328f175b FOREIGN KEY (discussion_topic_id) REFERENCES public.discussion_topics(id);


--
-- Name: mentions fk_rails_1b711e94aa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mentions
    ADD CONSTRAINT fk_rails_1b711e94aa FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: score_metadata fk_rails_1baeaf2d19; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.score_metadata
    ADD CONSTRAINT fk_rails_1baeaf2d19 FOREIGN KEY (score_id) REFERENCES public.scores(id);


--
-- Name: profiles fk_rails_1c415318fc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT fk_rails_1c415318fc FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: anonymous_or_moderation_events fk_rails_1c75f73508; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.anonymous_or_moderation_events
    ADD CONSTRAINT fk_rails_1c75f73508 FOREIGN KEY (submission_id) REFERENCES public.submissions(id);


--
-- Name: bookmarks_bookmarks fk_rails_1c845e4204; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookmarks_bookmarks
    ADD CONSTRAINT fk_rails_1c845e4204 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: discussion_topics fk_rails_1d19e2eea5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_topics
    ADD CONSTRAINT fk_rails_1d19e2eea5 FOREIGN KEY (external_feed_id) REFERENCES public.external_feeds(id);


--
-- Name: migration_issues fk_rails_1d79ad9705; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.migration_issues
    ADD CONSTRAINT fk_rails_1d79ad9705 FOREIGN KEY (content_migration_id) REFERENCES public.content_migrations(id);


--
-- Name: conditional_release_scoring_ranges fk_rails_1e01dde724; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conditional_release_scoring_ranges
    ADD CONSTRAINT fk_rails_1e01dde724 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: account_reports fk_rails_1ee483dd34; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_reports
    ADD CONSTRAINT fk_rails_1ee483dd34 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: conditional_release_assignment_set_associations fk_rails_1ef1909e3b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conditional_release_assignment_set_associations
    ADD CONSTRAINT fk_rails_1ef1909e3b FOREIGN KEY (assignment_id) REFERENCES public.assignments(id);


--
-- Name: observer_pairing_codes fk_rails_1f9d0db943; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.observer_pairing_codes
    ADD CONSTRAINT fk_rails_1f9d0db943 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: calendar_events fk_rails_2069d7cd39; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendar_events
    ADD CONSTRAINT fk_rails_2069d7cd39 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: polling_poll_submissions fk_rails_21612c7e9a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.polling_poll_submissions
    ADD CONSTRAINT fk_rails_21612c7e9a FOREIGN KEY (poll_choice_id) REFERENCES public.polling_poll_choices(id);


--
-- Name: lti_results fk_rails_222c701887; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_results
    ADD CONSTRAINT fk_rails_222c701887 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: anonymous_or_moderation_events fk_rails_227462b115; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.anonymous_or_moderation_events
    ADD CONSTRAINT fk_rails_227462b115 FOREIGN KEY (canvadoc_id) REFERENCES public.canvadocs(id);


--
-- Name: rubrics fk_rails_232b21215a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rubrics
    ADD CONSTRAINT fk_rails_232b21215a FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: learning_outcome_groups fk_rails_2359cb17b0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.learning_outcome_groups
    ADD CONSTRAINT fk_rails_2359cb17b0 FOREIGN KEY (root_learning_outcome_group_id) REFERENCES public.learning_outcome_groups(id);


--
-- Name: account_users fk_rails_23b8e88a4b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_users
    ADD CONSTRAINT fk_rails_23b8e88a4b FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: custom_grade_statuses fk_rails_241d38373b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_grade_statuses
    ADD CONSTRAINT fk_rails_241d38373b FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: discussion_topic_section_visibilities fk_rails_2456b918f5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_topic_section_visibilities
    ADD CONSTRAINT fk_rails_2456b918f5 FOREIGN KEY (discussion_topic_id) REFERENCES public.discussion_topics(id);


--
-- Name: auditor_grade_change_records_2025_5 fk_rails_2557307d47; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_grade_change_records_2025_5
    ADD CONSTRAINT fk_rails_2557307d47 FOREIGN KEY (submission_id) REFERENCES public.submissions(id);


--
-- Name: enrollment_states fk_rails_2583b53a28; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enrollment_states
    ADD CONSTRAINT fk_rails_2583b53a28 FOREIGN KEY (enrollment_id) REFERENCES public.enrollments(id);


--
-- Name: outcome_imports fk_rails_25a74d343f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outcome_imports
    ADD CONSTRAINT fk_rails_25a74d343f FOREIGN KEY (attachment_id) REFERENCES public.attachments(id);


--
-- Name: media_objects fk_rails_25b24c5e66; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media_objects
    ADD CONSTRAINT fk_rails_25b24c5e66 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: learning_outcome_groups fk_rails_2630b3657a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.learning_outcome_groups
    ADD CONSTRAINT fk_rails_2630b3657a FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: user_lmgb_outcome_orderings fk_rails_26995faaa9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_lmgb_outcome_orderings
    ADD CONSTRAINT fk_rails_26995faaa9 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: score_statistics fk_rails_26cf804e62; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.score_statistics
    ADD CONSTRAINT fk_rails_26cf804e62 FOREIGN KEY (assignment_id) REFERENCES public.assignments(id);


--
-- Name: polling_polls fk_rails_2742c5bc84; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.polling_polls
    ADD CONSTRAINT fk_rails_2742c5bc84 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: auditor_feature_flag_records_2025_5 fk_rails_27b8885f05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_feature_flag_records_2025_5
    ADD CONSTRAINT fk_rails_27b8885f05 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: context_external_tools fk_rails_27d8c7c29b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.context_external_tools
    ADD CONSTRAINT fk_rails_27d8c7c29b FOREIGN KEY (cloned_item_id) REFERENCES public.cloned_items(id);


--
-- Name: content_migrations fk_rails_27f5fdeb82; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_migrations
    ADD CONSTRAINT fk_rails_27f5fdeb82 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: sis_batches fk_rails_289263ccc7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sis_batches
    ADD CONSTRAINT fk_rails_289263ccc7 FOREIGN KEY (errors_attachment_id) REFERENCES public.attachments(id);


--
-- Name: assignments fk_rails_289e40e18c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT fk_rails_289e40e18c FOREIGN KEY (cloned_item_id) REFERENCES public.cloned_items(id);


--
-- Name: viewed_submission_comments fk_rails_28c7c3f1f7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.viewed_submission_comments
    ADD CONSTRAINT fk_rails_28c7c3f1f7 FOREIGN KEY (submission_comment_id) REFERENCES public.submission_comments(id);


--
-- Name: lti_line_items fk_rails_2983f6e038; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_line_items
    ADD CONSTRAINT fk_rails_2983f6e038 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: discussion_entries fk_rails_2a02569030; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_entries
    ADD CONSTRAINT fk_rails_2a02569030 FOREIGN KEY (root_entry_id) REFERENCES public.discussion_entries(id);


--
-- Name: discussion_entry_drafts fk_rails_2cafc2a389; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_entry_drafts
    ADD CONSTRAINT fk_rails_2cafc2a389 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: authentication_providers fk_rails_2cd97ede08; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authentication_providers
    ADD CONSTRAINT fk_rails_2cd97ede08 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: rubric_assessments fk_rails_2d2687def1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rubric_assessments
    ADD CONSTRAINT fk_rails_2d2687def1 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: quiz_submission_events fk_rails_2d873134e2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_submission_events
    ADD CONSTRAINT fk_rails_2d873134e2 FOREIGN KEY (quiz_submission_id) REFERENCES public.quiz_submissions(id);


--
-- Name: assignment_groups fk_rails_2d906abe72; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_groups
    ADD CONSTRAINT fk_rails_2d906abe72 FOREIGN KEY (cloned_item_id) REFERENCES public.cloned_items(id);


--
-- Name: notification_policy_overrides fk_rails_2de20ddc94; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_policy_overrides
    ADD CONSTRAINT fk_rails_2de20ddc94 FOREIGN KEY (communication_channel_id) REFERENCES public.communication_channels(id);


--
-- Name: enrollments fk_rails_2e119501f4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enrollments
    ADD CONSTRAINT fk_rails_2e119501f4 FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: assessment_questions fk_rails_2ea0ec3c6e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessment_questions
    ADD CONSTRAINT fk_rails_2ea0ec3c6e FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: course_paces fk_rails_2f83a182a8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_paces
    ADD CONSTRAINT fk_rails_2f83a182a8 FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: abstract_courses fk_rails_3077d9a014; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.abstract_courses
    ADD CONSTRAINT fk_rails_3077d9a014 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: lti_resource_links fk_rails_3107ae7bc7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_resource_links
    ADD CONSTRAINT fk_rails_3107ae7bc7 FOREIGN KEY (context_external_tool_id) REFERENCES public.context_external_tools(id);


--
-- Name: web_conference_participants fk_rails_318671d89f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.web_conference_participants
    ADD CONSTRAINT fk_rails_318671d89f FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: planner_notes fk_rails_3255427de8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planner_notes
    ADD CONSTRAINT fk_rails_3255427de8 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: terms_of_services fk_rails_337ba633a9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.terms_of_services
    ADD CONSTRAINT fk_rails_337ba633a9 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: assessment_requests fk_rails_33d90b7c30; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessment_requests
    ADD CONSTRAINT fk_rails_33d90b7c30 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: mentions fk_rails_342ac04d74; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mentions
    ADD CONSTRAINT fk_rails_342ac04d74 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: observer_alerts fk_rails_3435fafc4c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.observer_alerts
    ADD CONSTRAINT fk_rails_3435fafc4c FOREIGN KEY (observer_id) REFERENCES public.users(id);


--
-- Name: enrollment_states fk_rails_343745d2d7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enrollment_states
    ADD CONSTRAINT fk_rails_343745d2d7 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: temporary_enrollment_pairings fk_rails_34cd006ab1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.temporary_enrollment_pairings
    ADD CONSTRAINT fk_rails_34cd006ab1 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: discussion_topic_materialized_views fk_rails_34dd2d679a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_topic_materialized_views
    ADD CONSTRAINT fk_rails_34dd2d679a FOREIGN KEY (discussion_topic_id) REFERENCES public.discussion_topics(id);


--
-- Name: learning_outcome_groups fk_rails_34f901d115; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.learning_outcome_groups
    ADD CONSTRAINT fk_rails_34f901d115 FOREIGN KEY (learning_outcome_group_id) REFERENCES public.learning_outcome_groups(id);


--
-- Name: enrollments fk_rails_3508166a21; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enrollments
    ADD CONSTRAINT fk_rails_3508166a21 FOREIGN KEY (temporary_enrollment_source_user_id) REFERENCES public.users(id);


--
-- Name: enrollment_dates_overrides fk_rails_356b7d0ddc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enrollment_dates_overrides
    ADD CONSTRAINT fk_rails_356b7d0ddc FOREIGN KEY (enrollment_term_id) REFERENCES public.enrollment_terms(id);


--
-- Name: wiki_pages fk_rails_35d1fa9801; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wiki_pages
    ADD CONSTRAINT fk_rails_35d1fa9801 FOREIGN KEY (current_lookup_id) REFERENCES public.wiki_page_lookups(id);


--
-- Name: microsoft_sync_groups fk_rails_36993c0cbb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.microsoft_sync_groups
    ADD CONSTRAINT fk_rails_36993c0cbb FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: originality_reports fk_rails_36c981e3e7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.originality_reports
    ADD CONSTRAINT fk_rails_36c981e3e7 FOREIGN KEY (submission_id) REFERENCES public.submissions(id);


--
-- Name: canvadocs_annotation_contexts fk_rails_3852f56e03; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.canvadocs_annotation_contexts
    ADD CONSTRAINT fk_rails_3852f56e03 FOREIGN KEY (submission_id) REFERENCES public.submissions(id);


--
-- Name: grading_standards fk_rails_38b90db7a8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grading_standards
    ADD CONSTRAINT fk_rails_38b90db7a8 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: auditor_feature_flag_records fk_rails_398a7e63f8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_feature_flag_records
    ADD CONSTRAINT fk_rails_398a7e63f8 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: auditor_authentication_records_2025_5 fk_rails_3ab4a09ded; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_authentication_records_2025_5
    ADD CONSTRAINT fk_rails_3ab4a09ded FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: submission_comments fk_rails_3afa317b63; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submission_comments
    ADD CONSTRAINT fk_rails_3afa317b63 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: assignments fk_rails_3b14d42018; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT fk_rails_3b14d42018 FOREIGN KEY (annotatable_attachment_id) REFERENCES public.attachments(id);


--
-- Name: discussion_topic_participants fk_rails_3b8c3c44d8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_topic_participants
    ADD CONSTRAINT fk_rails_3b8c3c44d8 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: master_courses_migration_results fk_rails_3bc9928389; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.master_courses_migration_results
    ADD CONSTRAINT fk_rails_3bc9928389 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: groups fk_rails_3c368b24c7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT fk_rails_3c368b24c7 FOREIGN KEY (leader_id) REFERENCES public.users(id);


--
-- Name: epub_exports fk_rails_3c608dd796; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.epub_exports
    ADD CONSTRAINT fk_rails_3c608dd796 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: submission_versions fk_rails_3cc1d6d266; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submission_versions
    ADD CONSTRAINT fk_rails_3cc1d6d266 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: delayed_messages fk_rails_3d428ac9f1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_messages
    ADD CONSTRAINT fk_rails_3d428ac9f1 FOREIGN KEY (communication_channel_id) REFERENCES public.communication_channels(id);


--
-- Name: collaborators fk_rails_3d4aaacbb1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collaborators
    ADD CONSTRAINT fk_rails_3d4aaacbb1 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: standard_grade_statuses fk_rails_3d961b60b0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.standard_grade_statuses
    ADD CONSTRAINT fk_rails_3d961b60b0 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: learning_outcome_question_results fk_rails_3d9b550248; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.learning_outcome_question_results
    ADD CONSTRAINT fk_rails_3d9b550248 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: collaborations fk_rails_3e8ae0af8a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collaborations
    ADD CONSTRAINT fk_rails_3e8ae0af8a FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: conditional_release_assignment_set_associations fk_rails_3ec0562eca; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conditional_release_assignment_set_associations
    ADD CONSTRAINT fk_rails_3ec0562eca FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: accounts fk_rails_3f0c8923c0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT fk_rails_3f0c8923c0 FOREIGN KEY (latest_outcome_import_id) REFERENCES public.outcome_imports(id);


--
-- Name: shared_brand_configs fk_rails_3f25f5e6fa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shared_brand_configs
    ADD CONSTRAINT fk_rails_3f25f5e6fa FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: assignment_override_students fk_rails_3f4a57f6cc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_override_students
    ADD CONSTRAINT fk_rails_3f4a57f6cc FOREIGN KEY (discussion_topic_id) REFERENCES public.discussion_topics(id);


--
-- Name: assessment_requests fk_rails_400dc27246; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessment_requests
    ADD CONSTRAINT fk_rails_400dc27246 FOREIGN KEY (asset_id) REFERENCES public.submissions(id);


--
-- Name: comment_bank_items fk_rails_406668e8c1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comment_bank_items
    ADD CONSTRAINT fk_rails_406668e8c1 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: user_preference_values fk_rails_4078397c6d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_preference_values
    ADD CONSTRAINT fk_rails_4078397c6d FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: quiz_migration_alerts fk_rails_40e00cb2a9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_migration_alerts
    ADD CONSTRAINT fk_rails_40e00cb2a9 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: courses fk_rails_4309898d02; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT fk_rails_4309898d02 FOREIGN KEY (wiki_id) REFERENCES public.wikis(id);


--
-- Name: user_past_lti_ids fk_rails_435c8261c6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_past_lti_ids
    ADD CONSTRAINT fk_rails_435c8261c6 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: role_overrides fk_rails_4412996802; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_overrides
    ADD CONSTRAINT fk_rails_4412996802 FOREIGN KEY (role_id) REFERENCES public.roles(id);


--
-- Name: learning_outcome_results fk_rails_453d9421c4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.learning_outcome_results
    ADD CONSTRAINT fk_rails_453d9421c4 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: user_merge_data_records fk_rails_4579cd8750; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_merge_data_records
    ADD CONSTRAINT fk_rails_4579cd8750 FOREIGN KEY (user_merge_data_id) REFERENCES public.user_merge_data(id);


--
-- Name: switchman_shards fk_rails_45bd80a9c8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.switchman_shards
    ADD CONSTRAINT fk_rails_45bd80a9c8 FOREIGN KEY (delayed_jobs_shard_id) REFERENCES public.switchman_shards(id);


--
-- Name: attachment_upload_statuses fk_rails_45ef35c05a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attachment_upload_statuses
    ADD CONSTRAINT fk_rails_45ef35c05a FOREIGN KEY (attachment_id) REFERENCES public.attachments(id);


--
-- Name: auditor_course_records_2025_6 fk_rails_4644763952; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_course_records_2025_6
    ADD CONSTRAINT fk_rails_4644763952 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: conditional_release_scoring_ranges fk_rails_465cc7ee68; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conditional_release_scoring_ranges
    ADD CONSTRAINT fk_rails_465cc7ee68 FOREIGN KEY (rule_id) REFERENCES public.conditional_release_rules(id);


--
-- Name: delayed_messages fk_rails_46708890c3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_messages
    ADD CONSTRAINT fk_rails_46708890c3 FOREIGN KEY (notification_policy_override_id) REFERENCES public.notification_policy_overrides(id);


--
-- Name: assignments fk_rails_46718e626a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT fk_rails_46718e626a FOREIGN KEY (migrate_from_id) REFERENCES public.quizzes(id);


--
-- Name: moderated_grading_provisional_grades fk_rails_46d61d78e3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.moderated_grading_provisional_grades
    ADD CONSTRAINT fk_rails_46d61d78e3 FOREIGN KEY (scorer_id) REFERENCES public.users(id);


--
-- Name: post_policies fk_rails_46ead4a120; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_policies
    ADD CONSTRAINT fk_rails_46ead4a120 FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: content_migrations fk_rails_471c20026b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_migrations
    ADD CONSTRAINT fk_rails_471c20026b FOREIGN KEY (overview_attachment_id) REFERENCES public.attachments(id);


--
-- Name: quiz_submissions fk_rails_473863d022; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_submissions
    ADD CONSTRAINT fk_rails_473863d022 FOREIGN KEY (quiz_id) REFERENCES public.quizzes(id);


--
-- Name: assignments fk_rails_47a0621bf1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT fk_rails_47a0621bf1 FOREIGN KEY (duplicate_of_id) REFERENCES public.assignments(id);


--
-- Name: eportfolio_entries fk_rails_482dbada33; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eportfolio_entries
    ADD CONSTRAINT fk_rails_482dbada33 FOREIGN KEY (eportfolio_category_id) REFERENCES public.eportfolio_categories(id);


--
-- Name: master_courses_master_migrations fk_rails_48befa8db6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.master_courses_master_migrations
    ADD CONSTRAINT fk_rails_48befa8db6 FOREIGN KEY (master_template_id) REFERENCES public.master_courses_master_templates(id);


--
-- Name: user_merge_data fk_rails_4993c3792e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_merge_data
    ADD CONSTRAINT fk_rails_4993c3792e FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: microsoft_sync_user_mappings fk_rails_49c98628cf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.microsoft_sync_user_mappings
    ADD CONSTRAINT fk_rails_49c98628cf FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: course_sections fk_rails_4a0eb6ebbb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_sections
    ADD CONSTRAINT fk_rails_4a0eb6ebbb FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: assignment_overrides fk_rails_4aaa63725e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_overrides
    ADD CONSTRAINT fk_rails_4aaa63725e FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: discussion_topics fk_rails_4aac5d137c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_topics
    ADD CONSTRAINT fk_rails_4aac5d137c FOREIGN KEY (root_topic_id) REFERENCES public.discussion_topics(id);


--
-- Name: eportfolios fk_rails_4c2dbd440f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eportfolios
    ADD CONSTRAINT fk_rails_4c2dbd440f FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: auditor_authentication_records_2025_5 fk_rails_4c5cfc39c6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_authentication_records_2025_5
    ADD CONSTRAINT fk_rails_4c5cfc39c6 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: course_pace_module_items fk_rails_4ca1736ec9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_pace_module_items
    ADD CONSTRAINT fk_rails_4ca1736ec9 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: discussion_entry_versions fk_rails_4cf3ce0354; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_entry_versions
    ADD CONSTRAINT fk_rails_4cf3ce0354 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: quiz_regrades fk_rails_4cf8b252f4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_regrades
    ADD CONSTRAINT fk_rails_4cf8b252f4 FOREIGN KEY (quiz_id) REFERENCES public.quizzes(id);


--
-- Name: gradebook_csvs fk_rails_4d8cd84eb3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gradebook_csvs
    ADD CONSTRAINT fk_rails_4d8cd84eb3 FOREIGN KEY (progress_id) REFERENCES public.progresses(id);


--
-- Name: course_account_associations fk_rails_4e21d15465; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_account_associations
    ADD CONSTRAINT fk_rails_4e21d15465 FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: gradebook_uploads fk_rails_4e38efab60; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gradebook_uploads
    ADD CONSTRAINT fk_rails_4e38efab60 FOREIGN KEY (progress_id) REFERENCES public.progresses(id);


--
-- Name: quiz_statistics fk_rails_4e39b123dd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_statistics
    ADD CONSTRAINT fk_rails_4e39b123dd FOREIGN KEY (quiz_id) REFERENCES public.quizzes(id);


--
-- Name: content_migrations fk_rails_4ec369896b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_migrations
    ADD CONSTRAINT fk_rails_4ec369896b FOREIGN KEY (asset_map_attachment_id) REFERENCES public.attachments(id);


--
-- Name: auditor_grade_change_records_2025_5 fk_rails_4f692303fd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_grade_change_records_2025_5
    ADD CONSTRAINT fk_rails_4f692303fd FOREIGN KEY (grading_period_id) REFERENCES public.grading_periods(id);


--
-- Name: auditor_grade_change_records_2025_5 fk_rails_502cee7a47; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_grade_change_records_2025_5
    ADD CONSTRAINT fk_rails_502cee7a47 FOREIGN KEY (assignment_id) REFERENCES public.assignments(id);


--
-- Name: user_observers fk_rails_506aea5479; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_observers
    ADD CONSTRAINT fk_rails_506aea5479 FOREIGN KEY (observer_id) REFERENCES public.users(id);


--
-- Name: blackout_dates fk_rails_519a52f507; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blackout_dates
    ADD CONSTRAINT fk_rails_519a52f507 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: auditor_course_records_2025_6 fk_rails_51bb949905; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_course_records_2025_6
    ADD CONSTRAINT fk_rails_51bb949905 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: auditor_grade_change_records_2025_6 fk_rails_51c8baeba5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_grade_change_records_2025_6
    ADD CONSTRAINT fk_rails_51c8baeba5 FOREIGN KEY (grader_id) REFERENCES public.users(id);


--
-- Name: enrollment_terms fk_rails_51e8498073; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enrollment_terms
    ADD CONSTRAINT fk_rails_51e8498073 FOREIGN KEY (grading_period_group_id) REFERENCES public.grading_period_groups(id);


--
-- Name: assignment_override_students fk_rails_5215564217; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_override_students
    ADD CONSTRAINT fk_rails_5215564217 FOREIGN KEY (user_id) REFERENCES public.users(id) DEFERRABLE;


--
-- Name: lti_results fk_rails_521e616957; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_results
    ADD CONSTRAINT fk_rails_521e616957 FOREIGN KEY (submission_id) REFERENCES public.submissions(id);


--
-- Name: polling_poll_sessions fk_rails_52ebcb3ce8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.polling_poll_sessions
    ADD CONSTRAINT fk_rails_52ebcb3ce8 FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: auditor_course_records_2025_6 fk_rails_536da685cc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_course_records_2025_6
    ADD CONSTRAINT fk_rails_536da685cc FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: lti_line_items fk_rails_5389b967c4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_line_items
    ADD CONSTRAINT fk_rails_5389b967c4 FOREIGN KEY (assignment_id) REFERENCES public.assignments(id);


--
-- Name: terms_of_service_contents fk_rails_547ad56ef9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.terms_of_service_contents
    ADD CONSTRAINT fk_rails_547ad56ef9 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: assignments fk_rails_5546acbfe8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT fk_rails_5546acbfe8 FOREIGN KEY (parent_assignment_id) REFERENCES public.assignments(id);


--
-- Name: auditor_pseudonym_records_2025_6 fk_rails_56b9661bd1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_pseudonym_records_2025_6
    ADD CONSTRAINT fk_rails_56b9661bd1 FOREIGN KEY (pseudonym_id) REFERENCES public.pseudonyms(id);


--
-- Name: enrollments fk_rails_56c4ec50d6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enrollments
    ADD CONSTRAINT fk_rails_56c4ec50d6 FOREIGN KEY (sis_batch_id) REFERENCES public.sis_batches(id);


--
-- Name: custom_gradebook_columns fk_rails_571a48e40d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_gradebook_columns
    ADD CONSTRAINT fk_rails_571a48e40d FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: lti_tool_proxies fk_rails_57f8b9857d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_tool_proxies
    ADD CONSTRAINT fk_rails_57f8b9857d FOREIGN KEY (product_family_id) REFERENCES public.lti_product_families(id);


--
-- Name: auditor_grade_change_records fk_rails_580da144dc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_grade_change_records
    ADD CONSTRAINT fk_rails_580da144dc FOREIGN KEY (submission_id) REFERENCES public.submissions(id);


--
-- Name: pseudonyms fk_rails_587e86bf60; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pseudonyms
    ADD CONSTRAINT fk_rails_587e86bf60 FOREIGN KEY (authentication_provider_id) REFERENCES public.authentication_providers(id);


--
-- Name: account_reports fk_rails_58e7f750a2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_reports
    ADD CONSTRAINT fk_rails_58e7f750a2 FOREIGN KEY (attachment_id) REFERENCES public.attachments(id);


--
-- Name: assignment_overrides fk_rails_58f8ee369b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_overrides
    ADD CONSTRAINT fk_rails_58f8ee369b FOREIGN KEY (assignment_id) REFERENCES public.assignments(id);


--
-- Name: account_notification_roles fk_rails_5948b12a95; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_notification_roles
    ADD CONSTRAINT fk_rails_5948b12a95 FOREIGN KEY (account_notification_id) REFERENCES public.account_notifications(id);


--
-- Name: auditor_authentication_records fk_rails_5ad3656efe; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_authentication_records
    ADD CONSTRAINT fk_rails_5ad3656efe FOREIGN KEY (pseudonym_id) REFERENCES public.pseudonyms(id);


--
-- Name: sis_batch_errors fk_rails_5b09c1528e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sis_batch_errors
    ADD CONSTRAINT fk_rails_5b09c1528e FOREIGN KEY (sis_batch_id) REFERENCES public.sis_batches(id);


--
-- Name: course_pace_module_items fk_rails_5b2f18ae32; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_pace_module_items
    ADD CONSTRAINT fk_rails_5b2f18ae32 FOREIGN KEY (course_pace_id) REFERENCES public.course_paces(id);


--
-- Name: observer_alert_thresholds fk_rails_5c0602a7d1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.observer_alert_thresholds
    ADD CONSTRAINT fk_rails_5c0602a7d1 FOREIGN KEY (observer_id) REFERENCES public.users(id);


--
-- Name: group_categories fk_rails_5c1dc542a5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_categories
    ADD CONSTRAINT fk_rails_5c1dc542a5 FOREIGN KEY (sis_batch_id) REFERENCES public.sis_batches(id);


--
-- Name: outcome_proficiency_ratings fk_rails_5c89659ba6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outcome_proficiency_ratings
    ADD CONSTRAINT fk_rails_5c89659ba6 FOREIGN KEY (outcome_proficiency_id) REFERENCES public.outcome_proficiencies(id);


--
-- Name: sis_batches fk_rails_5cc4e38775; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sis_batches
    ADD CONSTRAINT fk_rails_5cc4e38775 FOREIGN KEY (batch_mode_term_id) REFERENCES public.enrollment_terms(id);


--
-- Name: submissions fk_rails_5d48b8a034; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submissions
    ADD CONSTRAINT fk_rails_5d48b8a034 FOREIGN KEY (media_object_id) REFERENCES public.media_objects(id);


--
-- Name: accounts fk_rails_5de7ad5dec; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT fk_rails_5de7ad5dec FOREIGN KEY (root_account_id) REFERENCES public.accounts(id) DEFERRABLE;


--
-- Name: developer_keys fk_rails_5e370c2560; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.developer_keys
    ADD CONSTRAINT fk_rails_5e370c2560 FOREIGN KEY (service_user_id) REFERENCES public.users(id);


--
-- Name: web_conference_participants fk_rails_5e4063e908; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.web_conference_participants
    ADD CONSTRAINT fk_rails_5e4063e908 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: conditional_release_assignment_set_associations fk_rails_5eb00a6e83; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conditional_release_assignment_set_associations
    ADD CONSTRAINT fk_rails_5eb00a6e83 FOREIGN KEY (assignment_set_id) REFERENCES public.conditional_release_assignment_sets(id);


--
-- Name: auditor_grade_change_records fk_rails_5f24c0ee2c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_grade_change_records
    ADD CONSTRAINT fk_rails_5f24c0ee2c FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: planner_overrides fk_rails_5fa99aedd0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planner_overrides
    ADD CONSTRAINT fk_rails_5fa99aedd0 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: submissions fk_rails_60b29f2fd7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submissions
    ADD CONSTRAINT fk_rails_60b29f2fd7 FOREIGN KEY (proxy_submitter_id) REFERENCES public.users(id);


--
-- Name: gradebook_csvs fk_rails_60f1713674; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gradebook_csvs
    ADD CONSTRAINT fk_rails_60f1713674 FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: scheduled_smart_alerts fk_rails_60f3ba4c90; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scheduled_smart_alerts
    ADD CONSTRAINT fk_rails_60f3ba4c90 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: course_sections fk_rails_616bd9cbd0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_sections
    ADD CONSTRAINT fk_rails_616bd9cbd0 FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: user_lmgb_outcome_orderings fk_rails_61b9586ab3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_lmgb_outcome_orderings
    ADD CONSTRAINT fk_rails_61b9586ab3 FOREIGN KEY (learning_outcome_id) REFERENCES public.learning_outcomes(id);


--
-- Name: submissions fk_rails_61cac0823d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submissions
    ADD CONSTRAINT fk_rails_61cac0823d FOREIGN KEY (assignment_id) REFERENCES public.assignments(id);


--
-- Name: groups fk_rails_61d69a1dcf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT fk_rails_61d69a1dcf FOREIGN KEY (sis_batch_id) REFERENCES public.sis_batches(id);


--
-- Name: live_assessments_results fk_rails_61dcfeb426; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.live_assessments_results
    ADD CONSTRAINT fk_rails_61dcfeb426 FOREIGN KEY (assessment_id) REFERENCES public.live_assessments_assessments(id);


--
-- Name: accounts fk_rails_630eca7263; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT fk_rails_630eca7263 FOREIGN KEY (sis_batch_id) REFERENCES public.sis_batches(id);


--
-- Name: wiki_pages fk_rails_6315b78b7d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wiki_pages
    ADD CONSTRAINT fk_rails_6315b78b7d FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: enrollments fk_rails_6359366b63; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enrollments
    ADD CONSTRAINT fk_rails_6359366b63 FOREIGN KEY (associated_user_id) REFERENCES public.users(id);


--
-- Name: content_exports fk_rails_6364a4a05e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_exports
    ADD CONSTRAINT fk_rails_6364a4a05e FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: conditional_release_rules fk_rails_63aa2864f6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conditional_release_rules
    ADD CONSTRAINT fk_rails_63aa2864f6 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: microsoft_sync_partial_sync_changes fk_rails_63aa56f008; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.microsoft_sync_partial_sync_changes
    ADD CONSTRAINT fk_rails_63aa56f008 FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: quiz_submission_events fk_rails_63fa6e527e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_submission_events
    ADD CONSTRAINT fk_rails_63fa6e527e FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: oauth_requests fk_rails_6471c0c593; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_requests
    ADD CONSTRAINT fk_rails_6471c0c593 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: web_conference_participants fk_rails_652989382e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.web_conference_participants
    ADD CONSTRAINT fk_rails_652989382e FOREIGN KEY (web_conference_id) REFERENCES public.web_conferences(id);


--
-- Name: scores fk_rails_6538b6f2d3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scores
    ADD CONSTRAINT fk_rails_6538b6f2d3 FOREIGN KEY (custom_grade_status_id) REFERENCES public.custom_grade_statuses(id);


--
-- Name: viewed_submission_comments fk_rails_653ca85e1b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.viewed_submission_comments
    ADD CONSTRAINT fk_rails_653ca85e1b FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: shared_brand_configs fk_rails_669597e153; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shared_brand_configs
    ADD CONSTRAINT fk_rails_669597e153 FOREIGN KEY (brand_config_md5) REFERENCES public.brand_configs(md5);


--
-- Name: quiz_groups fk_rails_66e04b1c22; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_groups
    ADD CONSTRAINT fk_rails_66e04b1c22 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: auditor_authentication_records_2025_5 fk_rails_675b578eb4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_authentication_records_2025_5
    ADD CONSTRAINT fk_rails_675b578eb4 FOREIGN KEY (pseudonym_id) REFERENCES public.pseudonyms(id);


--
-- Name: discussion_topics fk_rails_6791d1877c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_topics
    ADD CONSTRAINT fk_rails_6791d1877c FOREIGN KEY (old_assignment_id) REFERENCES public.assignments(id);


--
-- Name: account_users fk_rails_685e030c15; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_users
    ADD CONSTRAINT fk_rails_685e030c15 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: auditor_grade_change_records_2025_6 fk_rails_6867a4aef7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_grade_change_records_2025_6
    ADD CONSTRAINT fk_rails_6867a4aef7 FOREIGN KEY (assignment_id) REFERENCES public.assignments(id);


--
-- Name: discussion_entries fk_rails_68ae881f28; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_entries
    ADD CONSTRAINT fk_rails_68ae881f28 FOREIGN KEY (quoted_entry_id) REFERENCES public.discussion_entries(id);


--
-- Name: microsoft_sync_user_mappings fk_rails_69200ebc90; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.microsoft_sync_user_mappings
    ADD CONSTRAINT fk_rails_69200ebc90 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: master_courses_master_templates fk_rails_69a6430b11; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.master_courses_master_templates
    ADD CONSTRAINT fk_rails_69a6430b11 FOREIGN KEY (active_migration_id) REFERENCES public.master_courses_master_migrations(id);


--
-- Name: submission_comments fk_rails_6a44347cb4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submission_comments
    ADD CONSTRAINT fk_rails_6a44347cb4 FOREIGN KEY (provisional_grade_id) REFERENCES public.moderated_grading_provisional_grades(id);


--
-- Name: auditor_pseudonym_records fk_rails_6a675aa6f8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_pseudonym_records
    ADD CONSTRAINT fk_rails_6a675aa6f8 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: group_and_membership_importers fk_rails_6a813cdffb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_and_membership_importers
    ADD CONSTRAINT fk_rails_6a813cdffb FOREIGN KEY (attachment_id) REFERENCES public.attachments(id);


--
-- Name: temporary_enrollment_pairings fk_rails_6c56e522db; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.temporary_enrollment_pairings
    ADD CONSTRAINT fk_rails_6c56e522db FOREIGN KEY (deleted_by_id) REFERENCES public.users(id);


--
-- Name: user_observers fk_rails_6e626831b8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_observers
    ADD CONSTRAINT fk_rails_6e626831b8 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: discussion_entry_drafts fk_rails_6e6a7d2c3f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_entry_drafts
    ADD CONSTRAINT fk_rails_6e6a7d2c3f FOREIGN KEY (discussion_entry_id) REFERENCES public.discussion_entries(id);


--
-- Name: gradebook_filters fk_rails_70149216e6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gradebook_filters
    ADD CONSTRAINT fk_rails_70149216e6 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: discussion_entries fk_rails_70b05820ac; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_entries
    ADD CONSTRAINT fk_rails_70b05820ac FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: grading_period_groups fk_rails_712c487e43; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grading_period_groups
    ADD CONSTRAINT fk_rails_712c487e43 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: observer_alerts fk_rails_71aa3b8381; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.observer_alerts
    ADD CONSTRAINT fk_rails_71aa3b8381 FOREIGN KEY (observer_alert_threshold_id) REFERENCES public.observer_alert_thresholds(id);


--
-- Name: course_account_associations fk_rails_7225a78aa5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_account_associations
    ADD CONSTRAINT fk_rails_7225a78aa5 FOREIGN KEY (course_section_id) REFERENCES public.course_sections(id);


--
-- Name: custom_grade_statuses fk_rails_722fec664d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_grade_statuses
    ADD CONSTRAINT fk_rails_722fec664d FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: user_lmgb_outcome_orderings fk_rails_728e4c54c6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_lmgb_outcome_orderings
    ADD CONSTRAINT fk_rails_728e4c54c6 FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: context_module_progressions fk_rails_736970326a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.context_module_progressions
    ADD CONSTRAINT fk_rails_736970326a FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: content_tags fk_rails_7376a606b8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_tags
    ADD CONSTRAINT fk_rails_7376a606b8 FOREIGN KEY (cloned_item_id) REFERENCES public.cloned_items(id);


--
-- Name: assignment_configuration_tool_lookups fk_rails_73f7ea9f92; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_configuration_tool_lookups
    ADD CONSTRAINT fk_rails_73f7ea9f92 FOREIGN KEY (assignment_id) REFERENCES public.assignments(id);


--
-- Name: wiki_pages fk_rails_74a0fa180b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wiki_pages
    ADD CONSTRAINT fk_rails_74a0fa180b FOREIGN KEY (assignment_id) REFERENCES public.assignments(id);


--
-- Name: grading_period_groups fk_rails_74c3fa7800; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grading_period_groups
    ADD CONSTRAINT fk_rails_74c3fa7800 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: stream_item_instances fk_rails_75522c5fd3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stream_item_instances
    ADD CONSTRAINT fk_rails_75522c5fd3 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: calendar_events fk_rails_75957d2da8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendar_events
    ADD CONSTRAINT fk_rails_75957d2da8 FOREIGN KEY (cloned_item_id) REFERENCES public.cloned_items(id);


--
-- Name: assignment_override_students fk_rails_767df07579; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_override_students
    ADD CONSTRAINT fk_rails_767df07579 FOREIGN KEY (attachment_id) REFERENCES public.attachments(id);


--
-- Name: live_assessments_results fk_rails_768405ee04; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.live_assessments_results
    ADD CONSTRAINT fk_rails_768405ee04 FOREIGN KEY (assessor_id) REFERENCES public.users(id);


--
-- Name: external_feeds fk_rails_7727e39b38; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_feeds
    ADD CONSTRAINT fk_rails_7727e39b38 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: developer_keys fk_rails_777bedfd18; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.developer_keys
    ADD CONSTRAINT fk_rails_777bedfd18 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: user_account_associations fk_rails_77e6070def; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_account_associations
    ADD CONSTRAINT fk_rails_77e6070def FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: context_module_progressions fk_rails_786d10d2ce; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.context_module_progressions
    ADD CONSTRAINT fk_rails_786d10d2ce FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: page_comments fk_rails_78ced27005; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.page_comments
    ADD CONSTRAINT fk_rails_78ced27005 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: observer_alerts fk_rails_792164ef57; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.observer_alerts
    ADD CONSTRAINT fk_rails_792164ef57 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: account_notification_roles fk_rails_794b06ff0e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_notification_roles
    ADD CONSTRAINT fk_rails_794b06ff0e FOREIGN KEY (role_id) REFERENCES public.roles(id);


--
-- Name: auditor_grade_change_records fk_rails_797cff9335; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_grade_change_records
    ADD CONSTRAINT fk_rails_797cff9335 FOREIGN KEY (assignment_id) REFERENCES public.assignments(id);


--
-- Name: epub_exports fk_rails_7b64484d53; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.epub_exports
    ADD CONSTRAINT fk_rails_7b64484d53 FOREIGN KEY (content_export_id) REFERENCES public.content_exports(id);


--
-- Name: auditor_grade_change_records_2025_6 fk_rails_7bd4f65f0f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_grade_change_records_2025_6
    ADD CONSTRAINT fk_rails_7bd4f65f0f FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: roles fk_rails_7c71253d78; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT fk_rails_7c71253d78 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: lti_resource_links fk_rails_7c8c6fa928; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_resource_links
    ADD CONSTRAINT fk_rails_7c8c6fa928 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: lti_resource_handlers fk_rails_7cca6549c4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_resource_handlers
    ADD CONSTRAINT fk_rails_7cca6549c4 FOREIGN KEY (tool_proxy_id) REFERENCES public.lti_tool_proxies(id);


--
-- Name: rubric_criteria fk_rails_7cf7c45a27; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rubric_criteria
    ADD CONSTRAINT fk_rails_7cf7c45a27 FOREIGN KEY (learning_outcome_id) REFERENCES public.learning_outcomes(id);


--
-- Name: roles fk_rails_7d4ded04e1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT fk_rails_7d4ded04e1 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: course_account_associations fk_rails_7d50d15200; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_account_associations
    ADD CONSTRAINT fk_rails_7d50d15200 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: discussion_entry_drafts fk_rails_7d5386d2d8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_entry_drafts
    ADD CONSTRAINT fk_rails_7d5386d2d8 FOREIGN KEY (parent_id) REFERENCES public.discussion_entries(id);


--
-- Name: groups fk_rails_7d60528287; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT fk_rails_7d60528287 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: courses fk_rails_7e42d223b2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT fk_rails_7e42d223b2 FOREIGN KEY (latest_outcome_import_id) REFERENCES public.outcome_imports(id);


--
-- Name: discussion_topic_participants fk_rails_7ec1da0578; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_topic_participants
    ADD CONSTRAINT fk_rails_7ec1da0578 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: auditor_grade_change_records fk_rails_7f96e6972d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_grade_change_records
    ADD CONSTRAINT fk_rails_7f96e6972d FOREIGN KEY (grading_period_id) REFERENCES public.grading_periods(id);


--
-- Name: anonymous_or_moderation_events fk_rails_80aae1e26f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.anonymous_or_moderation_events
    ADD CONSTRAINT fk_rails_80aae1e26f FOREIGN KEY (assignment_id) REFERENCES public.assignments(id);


--
-- Name: quiz_regrades fk_rails_8116556edd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_regrades
    ADD CONSTRAINT fk_rails_8116556edd FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: delayed_messages fk_rails_81d84c7a3d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_messages
    ADD CONSTRAINT fk_rails_81d84c7a3d FOREIGN KEY (notification_policy_id) REFERENCES public.notification_policies(id);


--
-- Name: epub_exports fk_rails_8229c54d0d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.epub_exports
    ADD CONSTRAINT fk_rails_8229c54d0d FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: master_courses_child_subscriptions fk_rails_831debb6b9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.master_courses_child_subscriptions
    ADD CONSTRAINT fk_rails_831debb6b9 FOREIGN KEY (master_template_id) REFERENCES public.master_courses_master_templates(id);


--
-- Name: course_account_associations fk_rails_83b1438238; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_account_associations
    ADD CONSTRAINT fk_rails_83b1438238 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: developer_key_account_bindings fk_rails_8435015b54; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.developer_key_account_bindings
    ADD CONSTRAINT fk_rails_8435015b54 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: discussion_entries fk_rails_846fecac98; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_entries
    ADD CONSTRAINT fk_rails_846fecac98 FOREIGN KEY (editor_id) REFERENCES public.users(id);


--
-- Name: content_participations fk_rails_8513d41810; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_participations
    ADD CONSTRAINT fk_rails_8513d41810 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: role_overrides fk_rails_8571d0f354; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_overrides
    ADD CONSTRAINT fk_rails_8571d0f354 FOREIGN KEY (context_id) REFERENCES public.accounts(id);


--
-- Name: sis_batch_errors fk_rails_85b0d7c870; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sis_batch_errors
    ADD CONSTRAINT fk_rails_85b0d7c870 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: microsoft_sync_partial_sync_changes fk_rails_8642f8ba3a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.microsoft_sync_partial_sync_changes
    ADD CONSTRAINT fk_rails_8642f8ba3a FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: account_reports fk_rails_865683f386; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_reports
    ADD CONSTRAINT fk_rails_865683f386 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: discussion_entry_participants fk_rails_86a01cf993; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_entry_participants
    ADD CONSTRAINT fk_rails_86a01cf993 FOREIGN KEY (discussion_entry_id) REFERENCES public.discussion_entries(id);


--
-- Name: user_notes fk_rails_86c27830da; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_notes
    ADD CONSTRAINT fk_rails_86c27830da FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: sis_post_grades_statuses fk_rails_870e38a0e6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sis_post_grades_statuses
    ADD CONSTRAINT fk_rails_870e38a0e6 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: user_profiles fk_rails_87a6352e58; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_profiles
    ADD CONSTRAINT fk_rails_87a6352e58 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: abstract_courses fk_rails_87ef57da5a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.abstract_courses
    ADD CONSTRAINT fk_rails_87ef57da5a FOREIGN KEY (enrollment_term_id) REFERENCES public.enrollment_terms(id);


--
-- Name: course_sections fk_rails_88559b4f6d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_sections
    ADD CONSTRAINT fk_rails_88559b4f6d FOREIGN KEY (enrollment_term_id) REFERENCES public.enrollment_terms(id);


--
-- Name: polling_poll_submissions fk_rails_8993f10747; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.polling_poll_submissions
    ADD CONSTRAINT fk_rails_8993f10747 FOREIGN KEY (poll_id) REFERENCES public.polling_polls(id);


--
-- Name: accounts fk_rails_89d393ce68; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT fk_rails_89d393ce68 FOREIGN KEY (course_template_id) REFERENCES public.courses(id);


--
-- Name: discussion_entries fk_rails_8a7187368b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_entries
    ADD CONSTRAINT fk_rails_8a7187368b FOREIGN KEY (parent_id) REFERENCES public.discussion_entries(id);


--
-- Name: master_courses_migration_results fk_rails_8a84ef8416; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.master_courses_migration_results
    ADD CONSTRAINT fk_rails_8a84ef8416 FOREIGN KEY (master_migration_id) REFERENCES public.master_courses_master_migrations(id);


--
-- Name: conditional_release_rules fk_rails_8acbb32e82; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conditional_release_rules
    ADD CONSTRAINT fk_rails_8acbb32e82 FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: anonymous_or_moderation_events fk_rails_8c95885a92; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.anonymous_or_moderation_events
    ADD CONSTRAINT fk_rails_8c95885a92 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: rubric_criteria fk_rails_8c9ef923f7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rubric_criteria
    ADD CONSTRAINT fk_rails_8c9ef923f7 FOREIGN KEY (deleted_by_id) REFERENCES public.users(id);


--
-- Name: submissions fk_rails_8d85741475; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submissions
    ADD CONSTRAINT fk_rails_8d85741475 FOREIGN KEY (user_id) REFERENCES public.users(id) DEFERRABLE;


--
-- Name: auditor_feature_flag_records_2025_5 fk_rails_8e744d2c69; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_feature_flag_records_2025_5
    ADD CONSTRAINT fk_rails_8e744d2c69 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: user_account_associations fk_rails_8ec6f29c88; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_account_associations
    ADD CONSTRAINT fk_rails_8ec6f29c88 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: courses fk_rails_8f8adab10c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT fk_rails_8f8adab10c FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: ignores fk_rails_9089e0c809; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ignores
    ADD CONSTRAINT fk_rails_9089e0c809 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: accounts fk_rails_911a8f4c11; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT fk_rails_911a8f4c11 FOREIGN KEY (grading_standard_id) REFERENCES public.grading_standards(id);


--
-- Name: user_merge_data_items fk_rails_91bd08925b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_merge_data_items
    ADD CONSTRAINT fk_rails_91bd08925b FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: live_assessments_submissions fk_rails_924ff0872d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.live_assessments_submissions
    ADD CONSTRAINT fk_rails_924ff0872d FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: master_courses_master_content_tags fk_rails_925590350a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.master_courses_master_content_tags
    ADD CONSTRAINT fk_rails_925590350a FOREIGN KEY (master_template_id) REFERENCES public.master_courses_master_templates(id);


--
-- Name: rubric_criteria fk_rails_928a6c6d8c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rubric_criteria
    ADD CONSTRAINT fk_rails_928a6c6d8c FOREIGN KEY (rubric_id) REFERENCES public.rubrics(id);


--
-- Name: rubric_criteria fk_rails_92ad703662; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rubric_criteria
    ADD CONSTRAINT fk_rails_92ad703662 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: calendar_events fk_rails_930e3c0bf4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendar_events
    ADD CONSTRAINT fk_rails_930e3c0bf4 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: scores fk_rails_933d6ed393; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scores
    ADD CONSTRAINT fk_rails_933d6ed393 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: assignment_overrides fk_rails_93a79682f6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_overrides
    ADD CONSTRAINT fk_rails_93a79682f6 FOREIGN KEY (context_module_id) REFERENCES public.context_modules(id);


--
-- Name: conditional_release_assignment_set_actions fk_rails_941f76f503; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conditional_release_assignment_set_actions
    ADD CONSTRAINT fk_rails_941f76f503 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: master_courses_child_subscriptions fk_rails_95aad9cf8d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.master_courses_child_subscriptions
    ADD CONSTRAINT fk_rails_95aad9cf8d FOREIGN KEY (child_course_id) REFERENCES public.courses(id);


--
-- Name: lti_line_items fk_rails_96e1b2271c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_line_items
    ADD CONSTRAINT fk_rails_96e1b2271c FOREIGN KEY (lti_resource_link_id) REFERENCES public.lti_resource_links(id);


--
-- Name: access_tokens fk_rails_96fc070778; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.access_tokens
    ADD CONSTRAINT fk_rails_96fc070778 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: auditor_pseudonym_records fk_rails_9739b23244; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_pseudonym_records
    ADD CONSTRAINT fk_rails_9739b23244 FOREIGN KEY (pseudonym_id) REFERENCES public.pseudonyms(id);


--
-- Name: report_snapshots fk_rails_983ad88e61; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_snapshots
    ADD CONSTRAINT fk_rails_983ad88e61 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: discussion_topics fk_rails_98edc2f77e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_topics
    ADD CONSTRAINT fk_rails_98edc2f77e FOREIGN KEY (assignment_id) REFERENCES public.assignments(id);


--
-- Name: conversation_message_participants fk_rails_992a8b9e13; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_message_participants
    ADD CONSTRAINT fk_rails_992a8b9e13 FOREIGN KEY (conversation_message_id) REFERENCES public.conversation_messages(id);


--
-- Name: discussion_topics fk_rails_99a031cbb1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_topics
    ADD CONSTRAINT fk_rails_99a031cbb1 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: wiki_pages fk_rails_9a0e88e669; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wiki_pages
    ADD CONSTRAINT fk_rails_9a0e88e669 FOREIGN KEY (old_assignment_id) REFERENCES public.assignments(id);


--
-- Name: account_notifications fk_rails_9a3f0df4a1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_notifications
    ADD CONSTRAINT fk_rails_9a3f0df4a1 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: assignment_groups fk_rails_9a6cbb6167; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_groups
    ADD CONSTRAINT fk_rails_9a6cbb6167 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: score_statistics fk_rails_9a9b28f609; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.score_statistics
    ADD CONSTRAINT fk_rails_9a9b28f609 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: originality_reports fk_rails_9b1dd5b400; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.originality_reports
    ADD CONSTRAINT fk_rails_9b1dd5b400 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: discussion_entries fk_rails_9b275b5da7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_entries
    ADD CONSTRAINT fk_rails_9b275b5da7 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: discussion_topics fk_rails_9b3acbc3f8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_topics
    ADD CONSTRAINT fk_rails_9b3acbc3f8 FOREIGN KEY (attachment_id) REFERENCES public.attachments(id);


--
-- Name: lti_tool_proxy_bindings fk_rails_9b5d93b5c3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_tool_proxy_bindings
    ADD CONSTRAINT fk_rails_9b5d93b5c3 FOREIGN KEY (tool_proxy_id) REFERENCES public.lti_tool_proxies(id);


--
-- Name: pseudonyms fk_rails_9b98a5d814; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pseudonyms
    ADD CONSTRAINT fk_rails_9b98a5d814 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: post_policies fk_rails_9ba9a47075; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_policies
    ADD CONSTRAINT fk_rails_9ba9a47075 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: assignment_override_students fk_rails_9bb878faf3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_override_students
    ADD CONSTRAINT fk_rails_9bb878faf3 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: discussion_entry_drafts fk_rails_9bc52af304; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_entry_drafts
    ADD CONSTRAINT fk_rails_9bc52af304 FOREIGN KEY (root_entry_id) REFERENCES public.discussion_entries(id);


--
-- Name: user_notes fk_rails_9bcd528c60; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_notes
    ADD CONSTRAINT fk_rails_9bcd528c60 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: abstract_courses fk_rails_9c92877701; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.abstract_courses
    ADD CONSTRAINT fk_rails_9c92877701 FOREIGN KEY (sis_batch_id) REFERENCES public.sis_batches(id);


--
-- Name: context_module_progressions fk_rails_9cc1157b30; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.context_module_progressions
    ADD CONSTRAINT fk_rails_9cc1157b30 FOREIGN KEY (context_module_id) REFERENCES public.context_modules(id);


--
-- Name: grading_periods fk_rails_9cc118401a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grading_periods
    ADD CONSTRAINT fk_rails_9cc118401a FOREIGN KEY (grading_period_group_id) REFERENCES public.grading_period_groups(id);


--
-- Name: submissions fk_rails_9e3ddda320; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submissions
    ADD CONSTRAINT fk_rails_9e3ddda320 FOREIGN KEY (grading_period_id) REFERENCES public.grading_periods(id);


--
-- Name: rubric_associations fk_rails_9e5239a751; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rubric_associations
    ADD CONSTRAINT fk_rails_9e5239a751 FOREIGN KEY (rubric_id) REFERENCES public.rubrics(id);


--
-- Name: folders fk_rails_9f43470a04; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.folders
    ADD CONSTRAINT fk_rails_9f43470a04 FOREIGN KEY (parent_folder_id) REFERENCES public.folders(id);


--
-- Name: quizzes fk_rails_9f9beaf05c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quizzes
    ADD CONSTRAINT fk_rails_9f9beaf05c FOREIGN KEY (assignment_id) REFERENCES public.assignments(id);


--
-- Name: assignment_override_students fk_rails_9ffe0aa305; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_override_students
    ADD CONSTRAINT fk_rails_9ffe0aa305 FOREIGN KEY (assignment_id) REFERENCES public.assignments(id);


--
-- Name: learning_outcome_results fk_rails_a093f5ae6a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.learning_outcome_results
    ADD CONSTRAINT fk_rails_a093f5ae6a FOREIGN KEY (learning_outcome_id) REFERENCES public.learning_outcomes(id);


--
-- Name: assignment_override_students fk_rails_a157046dae; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_override_students
    ADD CONSTRAINT fk_rails_a157046dae FOREIGN KEY (wiki_page_id) REFERENCES public.wiki_pages(id);


--
-- Name: moderation_graders fk_rails_a1f077985d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.moderation_graders
    ADD CONSTRAINT fk_rails_a1f077985d FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: content_participations fk_rails_a223bf6cde; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_participations
    ADD CONSTRAINT fk_rails_a223bf6cde FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: outcome_imports fk_rails_a241f096b5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outcome_imports
    ADD CONSTRAINT fk_rails_a241f096b5 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: grading_periods fk_rails_a296a175eb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grading_periods
    ADD CONSTRAINT fk_rails_a296a175eb FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: polling_poll_submissions fk_rails_a327cfe658; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.polling_poll_submissions
    ADD CONSTRAINT fk_rails_a327cfe658 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: eportfolio_entries fk_rails_a3aa9184de; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eportfolio_entries
    ADD CONSTRAINT fk_rails_a3aa9184de FOREIGN KEY (eportfolio_id) REFERENCES public.eportfolios(id);


--
-- Name: custom_grade_statuses fk_rails_a3d1fcbecd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_grade_statuses
    ADD CONSTRAINT fk_rails_a3d1fcbecd FOREIGN KEY (deleted_by_id) REFERENCES public.users(id);


--
-- Name: users fk_rails_a47cd9d666; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_rails_a47cd9d666 FOREIGN KEY (merged_into_user_id) REFERENCES public.users(id);


--
-- Name: moderated_grading_selections fk_rails_a4904a6da8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.moderated_grading_selections
    ADD CONSTRAINT fk_rails_a4904a6da8 FOREIGN KEY (selected_provisional_grade_id) REFERENCES public.moderated_grading_provisional_grades(id);


--
-- Name: grading_standards fk_rails_a4e604bbd9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grading_standards
    ADD CONSTRAINT fk_rails_a4e604bbd9 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: rubric_assessments fk_rails_a502a63cbe; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rubric_assessments
    ADD CONSTRAINT fk_rails_a502a63cbe FOREIGN KEY (assessor_id) REFERENCES public.users(id);


--
-- Name: group_and_membership_importers fk_rails_a56724128d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_and_membership_importers
    ADD CONSTRAINT fk_rails_a56724128d FOREIGN KEY (group_category_id) REFERENCES public.group_categories(id);


--
-- Name: outcome_calculation_methods fk_rails_a59e69390f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outcome_calculation_methods
    ADD CONSTRAINT fk_rails_a59e69390f FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: custom_gradebook_column_data fk_rails_a6263ab6ab; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_gradebook_column_data
    ADD CONSTRAINT fk_rails_a6263ab6ab FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: submission_comments fk_rails_a62b09d198; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submission_comments
    ADD CONSTRAINT fk_rails_a62b09d198 FOREIGN KEY (author_id) REFERENCES public.users(id);


--
-- Name: anonymous_or_moderation_events fk_rails_a862303024; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.anonymous_or_moderation_events
    ADD CONSTRAINT fk_rails_a862303024 FOREIGN KEY (quiz_id) REFERENCES public.quizzes(id);


--
-- Name: scores fk_rails_a8b66a0a6e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scores
    ADD CONSTRAINT fk_rails_a8b66a0a6e FOREIGN KEY (enrollment_id) REFERENCES public.enrollments(id);


--
-- Name: auditor_pseudonym_records_2025_5 fk_rails_a934285979; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_pseudonym_records_2025_5
    ADD CONSTRAINT fk_rails_a934285979 FOREIGN KEY (pseudonym_id) REFERENCES public.pseudonyms(id);


--
-- Name: assignment_overrides fk_rails_aa683b1055; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_overrides
    ADD CONSTRAINT fk_rails_aa683b1055 FOREIGN KEY (attachment_id) REFERENCES public.attachments(id);


--
-- Name: rubrics fk_rails_aa80454086; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rubrics
    ADD CONSTRAINT fk_rails_aa80454086 FOREIGN KEY (rubric_id) REFERENCES public.rubrics(id);


--
-- Name: quiz_submission_events_2025_7 fk_rails_aaa8e94ce0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_submission_events_2025_7
    ADD CONSTRAINT fk_rails_aaa8e94ce0 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: pseudonyms fk_rails_aabcbf9874; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pseudonyms
    ADD CONSTRAINT fk_rails_aabcbf9874 FOREIGN KEY (sis_batch_id) REFERENCES public.sis_batches(id);


--
-- Name: page_views fk_rails_ab13cc7e9a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.page_views
    ADD CONSTRAINT fk_rails_ab13cc7e9a FOREIGN KEY (real_user_id) REFERENCES public.users(id);


--
-- Name: eportfolio_categories fk_rails_ab14eddd76; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eportfolio_categories
    ADD CONSTRAINT fk_rails_ab14eddd76 FOREIGN KEY (eportfolio_id) REFERENCES public.eportfolios(id);


--
-- Name: discussion_entry_drafts fk_rails_ab28e49c6a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_entry_drafts
    ADD CONSTRAINT fk_rails_ab28e49c6a FOREIGN KEY (attachment_id) REFERENCES public.attachments(id);


--
-- Name: lti_tool_consumer_profiles fk_rails_acb13d57c3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_tool_consumer_profiles
    ADD CONSTRAINT fk_rails_acb13d57c3 FOREIGN KEY (developer_key_id) REFERENCES public.developer_keys(id);


--
-- Name: canvadocs_annotation_contexts fk_rails_acf2663758; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.canvadocs_annotation_contexts
    ADD CONSTRAINT fk_rails_acf2663758 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: wiki_pages fk_rails_adcd926cb8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wiki_pages
    ADD CONSTRAINT fk_rails_adcd926cb8 FOREIGN KEY (wiki_id) REFERENCES public.wikis(id);


--
-- Name: accounts fk_rails_add3a59cd7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT fk_rails_add3a59cd7 FOREIGN KEY (parent_account_id) REFERENCES public.accounts(id);


--
-- Name: comment_bank_items fk_rails_adf174e129; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comment_bank_items
    ADD CONSTRAINT fk_rails_adf174e129 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: master_courses_master_content_tags fk_rails_af398d5991; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.master_courses_master_content_tags
    ADD CONSTRAINT fk_rails_af398d5991 FOREIGN KEY (current_migration_id) REFERENCES public.master_courses_master_migrations(id);


--
-- Name: moderated_grading_provisional_grades fk_rails_afa87e4ebc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.moderated_grading_provisional_grades
    ADD CONSTRAINT fk_rails_afa87e4ebc FOREIGN KEY (submission_id) REFERENCES public.submissions(id);


--
-- Name: one_time_passwords fk_rails_afd10ae0cb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.one_time_passwords
    ADD CONSTRAINT fk_rails_afd10ae0cb FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: assignments fk_rails_b035441827; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT fk_rails_b035441827 FOREIGN KEY (grader_section_id) REFERENCES public.course_sections(id);


--
-- Name: user_merge_data_items fk_rails_b23903b809; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_merge_data_items
    ADD CONSTRAINT fk_rails_b23903b809 FOREIGN KEY (user_merge_data_id) REFERENCES public.user_merge_data(id);


--
-- Name: custom_gradebook_column_data fk_rails_b2d446b0b0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_gradebook_column_data
    ADD CONSTRAINT fk_rails_b2d446b0b0 FOREIGN KEY (custom_gradebook_column_id) REFERENCES public.custom_gradebook_columns(id);


--
-- Name: master_courses_master_content_tags fk_rails_b38295638b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.master_courses_master_content_tags
    ADD CONSTRAINT fk_rails_b38295638b FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: auditor_course_records_2025_5 fk_rails_b3b7c188a7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_course_records_2025_5
    ADD CONSTRAINT fk_rails_b3b7c188a7 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: auditor_grade_change_records_2025_5 fk_rails_b3fbdac47c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_grade_change_records_2025_5
    ADD CONSTRAINT fk_rails_b3fbdac47c FOREIGN KEY (student_id) REFERENCES public.users(id);


--
-- Name: conditional_release_rules fk_rails_b40260f69d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conditional_release_rules
    ADD CONSTRAINT fk_rails_b40260f69d FOREIGN KEY (trigger_assignment_id) REFERENCES public.assignments(id);


--
-- Name: gradebook_csvs fk_rails_b4531da5e9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gradebook_csvs
    ADD CONSTRAINT fk_rails_b4531da5e9 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: submissions fk_rails_b470f1112d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submissions
    ADD CONSTRAINT fk_rails_b470f1112d FOREIGN KEY (custom_grade_status_id) REFERENCES public.custom_grade_statuses(id);


--
-- Name: grading_period_groups fk_rails_b4ea3168bc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grading_period_groups
    ADD CONSTRAINT fk_rails_b4ea3168bc FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: auditor_course_records_2025_5 fk_rails_b59b55138b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_course_records_2025_5
    ADD CONSTRAINT fk_rails_b59b55138b FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: user_notes fk_rails_b5a898af1b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_notes
    ADD CONSTRAINT fk_rails_b5a898af1b FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: rubrics fk_rails_b5b6f45923; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rubrics
    ADD CONSTRAINT fk_rails_b5b6f45923 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: assignments fk_rails_b5ed4ab660; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT fk_rails_b5ed4ab660 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: attachments fk_rails_b6a31db404; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attachments
    ADD CONSTRAINT fk_rails_b6a31db404 FOREIGN KEY (root_attachment_id) REFERENCES public.attachments(id);


--
-- Name: master_courses_master_templates fk_rails_b6c30b9788; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.master_courses_master_templates
    ADD CONSTRAINT fk_rails_b6c30b9788 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: enrollment_dates_overrides fk_rails_b6e1788535; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enrollment_dates_overrides
    ADD CONSTRAINT fk_rails_b6e1788535 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: custom_gradebook_columns fk_rails_b72c4423d7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_gradebook_columns
    ADD CONSTRAINT fk_rails_b72c4423d7 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: auditor_grade_change_records_2025_5 fk_rails_b755474f8e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_grade_change_records_2025_5
    ADD CONSTRAINT fk_rails_b755474f8e FOREIGN KEY (grader_id) REFERENCES public.users(id);


--
-- Name: attachments fk_rails_b7c6788fce; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attachments
    ADD CONSTRAINT fk_rails_b7c6788fce FOREIGN KEY (replacement_attachment_id) REFERENCES public.attachments(id);


--
-- Name: course_score_statistics fk_rails_b90138cf50; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_score_statistics
    ADD CONSTRAINT fk_rails_b90138cf50 FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: auditor_grade_change_records_2025_5 fk_rails_ba7a80267b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_grade_change_records_2025_5
    ADD CONSTRAINT fk_rails_ba7a80267b FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: assignment_overrides fk_rails_ba7c38f74c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_overrides
    ADD CONSTRAINT fk_rails_ba7c38f74c FOREIGN KEY (wiki_page_id) REFERENCES public.wiki_pages(id);


--
-- Name: content_shares fk_rails_ba88218dc2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_shares
    ADD CONSTRAINT fk_rails_ba88218dc2 FOREIGN KEY (sender_id) REFERENCES public.users(id);


--
-- Name: master_courses_migration_results fk_rails_ba9413706c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.master_courses_migration_results
    ADD CONSTRAINT fk_rails_ba9413706c FOREIGN KEY (child_subscription_id) REFERENCES public.master_courses_child_subscriptions(id);


--
-- Name: collaborators fk_rails_baeba1010a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collaborators
    ADD CONSTRAINT fk_rails_baeba1010a FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- Name: auditor_course_records fk_rails_baec14f76a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_course_records
    ADD CONSTRAINT fk_rails_baec14f76a FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: scores fk_rails_baf45f32a0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scores
    ADD CONSTRAINT fk_rails_baf45f32a0 FOREIGN KEY (grading_period_id) REFERENCES public.grading_periods(id);


--
-- Name: enrollments fk_rails_bb18af1d4e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enrollments
    ADD CONSTRAINT fk_rails_bb18af1d4e FOREIGN KEY (temporary_enrollment_pairing_id) REFERENCES public.temporary_enrollment_pairings(id);


--
-- Name: account_report_rows fk_rails_bb695932fe; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_report_rows
    ADD CONSTRAINT fk_rails_bb695932fe FOREIGN KEY (account_report_id) REFERENCES public.account_reports(id);


--
-- Name: enrollments fk_rails_bbf3738e95; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enrollments
    ADD CONSTRAINT fk_rails_bbf3738e95 FOREIGN KEY (course_section_id) REFERENCES public.course_sections(id);


--
-- Name: custom_gradebook_column_data fk_rails_bc039f962e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_gradebook_column_data
    ADD CONSTRAINT fk_rails_bc039f962e FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: moderated_grading_selections fk_rails_bc609b6673; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.moderated_grading_selections
    ADD CONSTRAINT fk_rails_bc609b6673 FOREIGN KEY (assignment_id) REFERENCES public.assignments(id);


--
-- Name: assignment_overrides fk_rails_bc94d484ff; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_overrides
    ADD CONSTRAINT fk_rails_bc94d484ff FOREIGN KEY (quiz_id) REFERENCES public.quizzes(id);


--
-- Name: submissions fk_rails_bcaf91aef8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submissions
    ADD CONSTRAINT fk_rails_bcaf91aef8 FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: auditor_grade_change_records fk_rails_bd9b58c417; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_grade_change_records
    ADD CONSTRAINT fk_rails_bd9b58c417 FOREIGN KEY (grader_id) REFERENCES public.users(id);


--
-- Name: assignments fk_rails_be38f24036; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT fk_rails_be38f24036 FOREIGN KEY (group_category_id) REFERENCES public.group_categories(id);


--
-- Name: block_editors fk_rails_bec365c139; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.block_editors
    ADD CONSTRAINT fk_rails_bec365c139 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: sis_batch_roll_back_data fk_rails_bfa1493f8a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sis_batch_roll_back_data
    ADD CONSTRAINT fk_rails_bfa1493f8a FOREIGN KEY (sis_batch_id) REFERENCES public.sis_batches(id);


--
-- Name: outcome_proficiency_ratings fk_rails_c09e7c056d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outcome_proficiency_ratings
    ADD CONSTRAINT fk_rails_c09e7c056d FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: content_migrations fk_rails_c1bf6cc5e9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_migrations
    ADD CONSTRAINT fk_rails_c1bf6cc5e9 FOREIGN KEY (exported_attachment_id) REFERENCES public.attachments(id);


--
-- Name: discussion_entry_participants fk_rails_c376b0a4c9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_entry_participants
    ADD CONSTRAINT fk_rails_c376b0a4c9 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: abstract_courses fk_rails_c38b94c5bc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.abstract_courses
    ADD CONSTRAINT fk_rails_c38b94c5bc FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: conversation_messages fk_rails_c3c322d882; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_messages
    ADD CONSTRAINT fk_rails_c3c322d882 FOREIGN KEY (conversation_id) REFERENCES public.conversations(id);


--
-- Name: discussion_entry_versions fk_rails_c4676280b0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_entry_versions
    ADD CONSTRAINT fk_rails_c4676280b0 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: wiki_page_lookups fk_rails_c478396003; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wiki_page_lookups
    ADD CONSTRAINT fk_rails_c478396003 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: courses fk_rails_c47c5058d9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT fk_rails_c47c5058d9 FOREIGN KEY (abstract_course_id) REFERENCES public.abstract_courses(id);


--
-- Name: auditor_grade_change_records_2025_6 fk_rails_c4f65bd7fc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_grade_change_records_2025_6
    ADD CONSTRAINT fk_rails_c4f65bd7fc FOREIGN KEY (student_id) REFERENCES public.users(id);


--
-- Name: csp_domains fk_rails_c597b23595; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.csp_domains
    ADD CONSTRAINT fk_rails_c597b23595 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: assignment_override_students fk_rails_c64a8a9f6b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_override_students
    ADD CONSTRAINT fk_rails_c64a8a9f6b FOREIGN KEY (context_module_id) REFERENCES public.context_modules(id);


--
-- Name: calendar_events fk_rails_c65a0a767a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendar_events
    ADD CONSTRAINT fk_rails_c65a0a767a FOREIGN KEY (web_conference_id) REFERENCES public.web_conferences(id);


--
-- Name: master_courses_child_subscriptions fk_rails_c6c1412951; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.master_courses_child_subscriptions
    ADD CONSTRAINT fk_rails_c6c1412951 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: polling_poll_choices fk_rails_c6c7f35cfc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.polling_poll_choices
    ADD CONSTRAINT fk_rails_c6c7f35cfc FOREIGN KEY (poll_id) REFERENCES public.polling_polls(id);


--
-- Name: learning_outcome_results fk_rails_c7ade34f0a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.learning_outcome_results
    ADD CONSTRAINT fk_rails_c7ade34f0a FOREIGN KEY (content_tag_id) REFERENCES public.content_tags(id);


--
-- Name: external_feed_entries fk_rails_c8030518e8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_feed_entries
    ADD CONSTRAINT fk_rails_c8030518e8 FOREIGN KEY (external_feed_id) REFERENCES public.external_feeds(id);


--
-- Name: assessment_requests fk_rails_c86f7bbc12; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessment_requests
    ADD CONSTRAINT fk_rails_c86f7bbc12 FOREIGN KEY (assessor_id) REFERENCES public.users(id);


--
-- Name: quizzes fk_rails_c8bbad8938; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quizzes
    ADD CONSTRAINT fk_rails_c8bbad8938 FOREIGN KEY (cloned_item_id) REFERENCES public.cloned_items(id);


--
-- Name: content_migrations fk_rails_c8d17d44ae; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_migrations
    ADD CONSTRAINT fk_rails_c8d17d44ae FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: purgatories fk_rails_c906487417; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purgatories
    ADD CONSTRAINT fk_rails_c906487417 FOREIGN KEY (attachment_id) REFERENCES public.attachments(id);


--
-- Name: account_users fk_rails_c96445f213; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_users
    ADD CONSTRAINT fk_rails_c96445f213 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: lti_ims_registrations fk_rails_cabc9c0468; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_ims_registrations
    ADD CONSTRAINT fk_rails_cabc9c0468 FOREIGN KEY (developer_key_id) REFERENCES public.developer_keys(id);


--
-- Name: enrollment_terms fk_rails_cb0782c2d2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enrollment_terms
    ADD CONSTRAINT fk_rails_cb0782c2d2 FOREIGN KEY (sis_batch_id) REFERENCES public.sis_batches(id);


--
-- Name: content_tags fk_rails_cbe0e9b21a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_tags
    ADD CONSTRAINT fk_rails_cbe0e9b21a FOREIGN KEY (learning_outcome_id) REFERENCES public.learning_outcomes(id);


--
-- Name: rubric_assessments fk_rails_cbe6352121; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rubric_assessments
    ADD CONSTRAINT fk_rails_cbe6352121 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: microsoft_sync_groups fk_rails_cc58db8077; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.microsoft_sync_groups
    ADD CONSTRAINT fk_rails_cc58db8077 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: auditor_grade_change_records fk_rails_ccf8f33d5e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_grade_change_records
    ADD CONSTRAINT fk_rails_ccf8f33d5e FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: communication_channels fk_rails_cd70d006a2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.communication_channels
    ADD CONSTRAINT fk_rails_cd70d006a2 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: outcome_friendly_descriptions fk_rails_cd9ae4732d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outcome_friendly_descriptions
    ADD CONSTRAINT fk_rails_cd9ae4732d FOREIGN KEY (learning_outcome_id) REFERENCES public.learning_outcomes(id);


--
-- Name: assessment_requests fk_rails_cef87e7126; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessment_requests
    ADD CONSTRAINT fk_rails_cef87e7126 FOREIGN KEY (rubric_association_id) REFERENCES public.rubric_associations(id);


--
-- Name: post_policies fk_rails_cf2d119863; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_policies
    ADD CONSTRAINT fk_rails_cf2d119863 FOREIGN KEY (assignment_id) REFERENCES public.assignments(id);


--
-- Name: group_memberships fk_rails_d05778f88b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_memberships
    ADD CONSTRAINT fk_rails_d05778f88b FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- Name: conversation_batches fk_rails_d068cb6c53; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_batches
    ADD CONSTRAINT fk_rails_d068cb6c53 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: web_conferences fk_rails_d0b08135f9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.web_conferences
    ADD CONSTRAINT fk_rails_d0b08135f9 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: favorites fk_rails_d15744e438; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.favorites
    ADD CONSTRAINT fk_rails_d15744e438 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: auditor_feature_flag_records_2025_6 fk_rails_d17e5f8834; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_feature_flag_records_2025_6
    ADD CONSTRAINT fk_rails_d17e5f8834 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: enrollments fk_rails_d1e7d10c0a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enrollments
    ADD CONSTRAINT fk_rails_d1e7d10c0a FOREIGN KEY (role_id) REFERENCES public.roles(id);


--
-- Name: purgatories fk_rails_d1f5462acf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purgatories
    ADD CONSTRAINT fk_rails_d1f5462acf FOREIGN KEY (deleted_by_user_id) REFERENCES public.users(id);


--
-- Name: attachments fk_rails_d24085bab5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attachments
    ADD CONSTRAINT fk_rails_d24085bab5 FOREIGN KEY (usage_rights_id) REFERENCES public.usage_rights(id);


--
-- Name: groups fk_rails_d2e3c28a2f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT fk_rails_d2e3c28a2f FOREIGN KEY (group_category_id) REFERENCES public.group_categories(id);


--
-- Name: moderation_graders fk_rails_d2edcc39ca; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.moderation_graders
    ADD CONSTRAINT fk_rails_d2edcc39ca FOREIGN KEY (assignment_id) REFERENCES public.assignments(id);


--
-- Name: rubric_assessments fk_rails_d38b350cb8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rubric_assessments
    ADD CONSTRAINT fk_rails_d38b350cb8 FOREIGN KEY (rubric_association_id) REFERENCES public.rubric_associations(id);


--
-- Name: wikis fk_rails_d3c395298d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wikis
    ADD CONSTRAINT fk_rails_d3c395298d FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: conversation_batches fk_rails_d421fc74f4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_batches
    ADD CONSTRAINT fk_rails_d421fc74f4 FOREIGN KEY (root_conversation_message_id) REFERENCES public.conversation_messages(id);


--
-- Name: auditor_course_records fk_rails_d5dc35c78c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_course_records
    ADD CONSTRAINT fk_rails_d5dc35c78c FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: content_participation_counts fk_rails_d62b914b96; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_participation_counts
    ADD CONSTRAINT fk_rails_d62b914b96 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: gradebook_uploads fk_rails_d6c567f720; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gradebook_uploads
    ADD CONSTRAINT fk_rails_d6c567f720 FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: lti_results fk_rails_d80f7ad5f3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_results
    ADD CONSTRAINT fk_rails_d80f7ad5f3 FOREIGN KEY (lti_line_item_id) REFERENCES public.lti_line_items(id);


--
-- Name: parallel_importers fk_rails_d8cbdaa461; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parallel_importers
    ADD CONSTRAINT fk_rails_d8cbdaa461 FOREIGN KEY (sis_batch_id) REFERENCES public.sis_batches(id);


--
-- Name: content_tags fk_rails_d8dc8497a2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_tags
    ADD CONSTRAINT fk_rails_d8dc8497a2 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: auditor_authentication_records_2025_6 fk_rails_d9140853db; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_authentication_records_2025_6
    ADD CONSTRAINT fk_rails_d9140853db FOREIGN KEY (pseudonym_id) REFERENCES public.pseudonyms(id);


--
-- Name: discussion_topics fk_rails_da3248778d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_topics
    ADD CONSTRAINT fk_rails_da3248778d FOREIGN KEY (cloned_item_id) REFERENCES public.cloned_items(id);


--
-- Name: context_external_tool_placements fk_rails_dbbdbf40e7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.context_external_tool_placements
    ADD CONSTRAINT fk_rails_dbbdbf40e7 FOREIGN KEY (context_external_tool_id) REFERENCES public.context_external_tools(id);


--
-- Name: auditor_feature_flag_records fk_rails_dbff8d102b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_feature_flag_records
    ADD CONSTRAINT fk_rails_dbff8d102b FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: lti_results fk_rails_dd0f128d6f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_results
    ADD CONSTRAINT fk_rails_dd0f128d6f FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: group_memberships fk_rails_dddd8ff810; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_memberships
    ADD CONSTRAINT fk_rails_dddd8ff810 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: notification_endpoints fk_rails_de537fc04f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_endpoints
    ADD CONSTRAINT fk_rails_de537fc04f FOREIGN KEY (access_token_id) REFERENCES public.access_tokens(id);


--
-- Name: enrollments fk_rails_df257dd853; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enrollments
    ADD CONSTRAINT fk_rails_df257dd853 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: account_report_rows fk_rails_df404c1a41; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_report_rows
    ADD CONSTRAINT fk_rails_df404c1a41 FOREIGN KEY (account_report_runner_id) REFERENCES public.account_report_runners(id);


--
-- Name: wiki_pages fk_rails_df5fec60ce; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wiki_pages
    ADD CONSTRAINT fk_rails_df5fec60ce FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: quiz_migration_alerts fk_rails_df86859617; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_migration_alerts
    ADD CONSTRAINT fk_rails_df86859617 FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: auditor_feature_flag_records_2025_6 fk_rails_df914d3170; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_feature_flag_records_2025_6
    ADD CONSTRAINT fk_rails_df914d3170 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: external_feed_entries fk_rails_e0397e1d17; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_feed_entries
    ADD CONSTRAINT fk_rails_e0397e1d17 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: account_report_runners fk_rails_e03a0118ae; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_report_runners
    ADD CONSTRAINT fk_rails_e03a0118ae FOREIGN KEY (account_report_id) REFERENCES public.account_reports(id);


--
-- Name: course_sections fk_rails_e050b590bb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_sections
    ADD CONSTRAINT fk_rails_e050b590bb FOREIGN KEY (sis_batch_id) REFERENCES public.sis_batches(id);


--
-- Name: course_sections fk_rails_e0676f34c7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_sections
    ADD CONSTRAINT fk_rails_e0676f34c7 FOREIGN KEY (nonxlist_course_id) REFERENCES public.courses(id);


--
-- Name: conditional_release_assignment_sets fk_rails_e074bec622; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conditional_release_assignment_sets
    ADD CONSTRAINT fk_rails_e074bec622 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: discussion_topic_section_visibilities fk_rails_e0c6be759a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_topic_section_visibilities
    ADD CONSTRAINT fk_rails_e0c6be759a FOREIGN KEY (course_section_id) REFERENCES public.course_sections(id);


--
-- Name: lti_tool_configurations fk_rails_e1026baa2d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_tool_configurations
    ADD CONSTRAINT fk_rails_e1026baa2d FOREIGN KEY (developer_key_id) REFERENCES public.developer_keys(id);


--
-- Name: enrollment_terms fk_rails_e182f18b93; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enrollment_terms
    ADD CONSTRAINT fk_rails_e182f18b93 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: discussion_entries fk_rails_e329dc15c5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_entries
    ADD CONSTRAINT fk_rails_e329dc15c5 FOREIGN KEY (discussion_topic_id) REFERENCES public.discussion_topics(id);


--
-- Name: assignment_override_students fk_rails_e35e8eee60; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_override_students
    ADD CONSTRAINT fk_rails_e35e8eee60 FOREIGN KEY (quiz_id) REFERENCES public.quizzes(id);


--
-- Name: submission_comments fk_rails_e4ff9f0115; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submission_comments
    ADD CONSTRAINT fk_rails_e4ff9f0115 FOREIGN KEY (submission_id) REFERENCES public.submissions(id);


--
-- Name: groups fk_rails_e5b00ef0e2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT fk_rails_e5b00ef0e2 FOREIGN KEY (wiki_id) REFERENCES public.wikis(id);


--
-- Name: lti_product_families fk_rails_e64cbae7bd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_product_families
    ADD CONSTRAINT fk_rails_e64cbae7bd FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: quiz_question_regrades fk_rails_e6cc08d5f1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_question_regrades
    ADD CONSTRAINT fk_rails_e6cc08d5f1 FOREIGN KEY (quiz_question_id) REFERENCES public.quiz_questions(id);


--
-- Name: quiz_regrade_runs fk_rails_e7282f482b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_regrade_runs
    ADD CONSTRAINT fk_rails_e7282f482b FOREIGN KEY (quiz_regrade_id) REFERENCES public.quiz_regrades(id);


--
-- Name: web_conferences fk_rails_e776d94dd2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.web_conferences
    ADD CONSTRAINT fk_rails_e776d94dd2 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: user_profile_links fk_rails_e7feec0134; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_profile_links
    ADD CONSTRAINT fk_rails_e7feec0134 FOREIGN KEY (user_profile_id) REFERENCES public.user_profiles(id);


--
-- Name: canvadocs_annotation_contexts fk_rails_e80a1d9a96; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.canvadocs_annotation_contexts
    ADD CONSTRAINT fk_rails_e80a1d9a96 FOREIGN KEY (attachment_id) REFERENCES public.attachments(id);


--
-- Name: gradebook_uploads fk_rails_e845504309; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gradebook_uploads
    ADD CONSTRAINT fk_rails_e845504309 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: enrollments fk_rails_e860e0e46b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enrollments
    ADD CONSTRAINT fk_rails_e860e0e46b FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: user_lmgb_outcome_orderings fk_rails_e99a013d04; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_lmgb_outcome_orderings
    ADD CONSTRAINT fk_rails_e99a013d04 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: live_assessments_submissions fk_rails_e9f0498f2a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.live_assessments_submissions
    ADD CONSTRAINT fk_rails_e9f0498f2a FOREIGN KEY (assessment_id) REFERENCES public.live_assessments_assessments(id);


--
-- Name: master_courses_master_migrations fk_rails_e9ffc47433; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.master_courses_master_migrations
    ADD CONSTRAINT fk_rails_e9ffc47433 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: assignment_override_students fk_rails_ea26ada45d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_override_students
    ADD CONSTRAINT fk_rails_ea26ada45d FOREIGN KEY (assignment_override_id) REFERENCES public.assignment_overrides(id);


--
-- Name: learning_outcome_groups fk_rails_ea5968ad1a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.learning_outcome_groups
    ADD CONSTRAINT fk_rails_ea5968ad1a FOREIGN KEY (source_outcome_group_id) REFERENCES public.learning_outcome_groups(id);


--
-- Name: rubric_assessments fk_rails_eadf99bbb0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rubric_assessments
    ADD CONSTRAINT fk_rails_eadf99bbb0 FOREIGN KEY (rubric_id) REFERENCES public.rubrics(id);


--
-- Name: late_policies fk_rails_eb4f0c93ce; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.late_policies
    ADD CONSTRAINT fk_rails_eb4f0c93ce FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: lti_message_handlers fk_rails_ec356d0f96; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_message_handlers
    ADD CONSTRAINT fk_rails_ec356d0f96 FOREIGN KEY (tool_proxy_id) REFERENCES public.lti_tool_proxies(id);


--
-- Name: access_tokens fk_rails_ecb5f23187; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.access_tokens
    ADD CONSTRAINT fk_rails_ecb5f23187 FOREIGN KEY (real_user_id) REFERENCES public.users(id);


--
-- Name: discussion_topics fk_rails_ecbbce6901; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_topics
    ADD CONSTRAINT fk_rails_ecbbce6901 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: groups fk_rails_ed4ff9a299; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT fk_rails_ed4ff9a299 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: role_overrides fk_rails_ed57234287; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_overrides
    ADD CONSTRAINT fk_rails_ed57234287 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: discussion_entry_versions fk_rails_edbaa1d580; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_entry_versions
    ADD CONSTRAINT fk_rails_edbaa1d580 FOREIGN KEY (discussion_entry_id) REFERENCES public.discussion_entries(id);


--
-- Name: submissions fk_rails_ee2f0735cd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submissions
    ADD CONSTRAINT fk_rails_ee2f0735cd FOREIGN KEY (quiz_submission_id) REFERENCES public.quiz_submissions(id);


--
-- Name: mentions fk_rails_ee320b195f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mentions
    ADD CONSTRAINT fk_rails_ee320b195f FOREIGN KEY (discussion_entry_id) REFERENCES public.discussion_entries(id);


--
-- Name: user_account_associations fk_rails_ee3ce7b901; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_account_associations
    ADD CONSTRAINT fk_rails_ee3ce7b901 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: course_pace_module_items fk_rails_ee4fdfc40d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_pace_module_items
    ADD CONSTRAINT fk_rails_ee4fdfc40d FOREIGN KEY (module_item_id) REFERENCES public.content_tags(id);


--
-- Name: quiz_submission_events_2025_6 fk_rails_ee9880ab29; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_submission_events_2025_6
    ADD CONSTRAINT fk_rails_ee9880ab29 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: discussion_entry_participants fk_rails_ef55fe937a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_entry_participants
    ADD CONSTRAINT fk_rails_ef55fe937a FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: discussion_topics fk_rails_ef64949942; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_topics
    ADD CONSTRAINT fk_rails_ef64949942 FOREIGN KEY (editor_id) REFERENCES public.users(id);


--
-- Name: assignments fk_rails_efc38ac892; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT fk_rails_efc38ac892 FOREIGN KEY (final_grader_id) REFERENCES public.users(id);


--
-- Name: auditor_grade_change_records_2025_6 fk_rails_f0326921c5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_grade_change_records_2025_6
    ADD CONSTRAINT fk_rails_f0326921c5 FOREIGN KEY (grading_period_id) REFERENCES public.grading_periods(id);


--
-- Name: rubric_criteria fk_rails_f062da785f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rubric_criteria
    ADD CONSTRAINT fk_rails_f062da785f FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: auditor_grade_change_records_2025_5 fk_rails_f0fb77c557; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_grade_change_records_2025_5
    ADD CONSTRAINT fk_rails_f0fb77c557 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: courses fk_rails_f4449a81f6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT fk_rails_f4449a81f6 FOREIGN KEY (enrollment_term_id) REFERENCES public.enrollment_terms(id) DEFERRABLE;


--
-- Name: submissions fk_rails_f44ff46cd5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submissions
    ADD CONSTRAINT fk_rails_f44ff46cd5 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: auditor_pseudonym_records_2025_6 fk_rails_f468e0ae29; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_pseudonym_records_2025_6
    ADD CONSTRAINT fk_rails_f468e0ae29 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: anonymous_or_moderation_events fk_rails_f492821432; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.anonymous_or_moderation_events
    ADD CONSTRAINT fk_rails_f492821432 FOREIGN KEY (context_external_tool_id) REFERENCES public.context_external_tools(id);


--
-- Name: context_modules fk_rails_f4c873d758; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.context_modules
    ADD CONSTRAINT fk_rails_f4c873d758 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: account_users fk_rails_f685686f18; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_users
    ADD CONSTRAINT fk_rails_f685686f18 FOREIGN KEY (role_id) REFERENCES public.roles(id);


--
-- Name: accounts fk_rails_f7353907b2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT fk_rails_f7353907b2 FOREIGN KEY (brand_config_md5) REFERENCES public.brand_configs(md5);


--
-- Name: master_courses_child_content_tags fk_rails_f756e6025d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.master_courses_child_content_tags
    ADD CONSTRAINT fk_rails_f756e6025d FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: quiz_question_regrades fk_rails_f7834fb23d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_question_regrades
    ADD CONSTRAINT fk_rails_f7834fb23d FOREIGN KEY (quiz_regrade_id) REFERENCES public.quiz_regrades(id);


--
-- Name: developer_key_account_bindings fk_rails_f8286c83f0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.developer_key_account_bindings
    ADD CONSTRAINT fk_rails_f8286c83f0 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: account_notifications fk_rails_f83172407d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_notifications
    ADD CONSTRAINT fk_rails_f83172407d FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: temporary_enrollment_pairings fk_rails_f83a21f38f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.temporary_enrollment_pairings
    ADD CONSTRAINT fk_rails_f83a21f38f FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: quiz_submission_events_2025_5 fk_rails_f8c2dd0b72; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_submission_events_2025_5
    ADD CONSTRAINT fk_rails_f8c2dd0b72 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: quizzes fk_rails_f8f315b8f7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quizzes
    ADD CONSTRAINT fk_rails_f8f315b8f7 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: quiz_submission_events_2025_5 fk_rails_f936abe497; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_submission_events_2025_5
    ADD CONSTRAINT fk_rails_f936abe497 FOREIGN KEY (quiz_submission_id) REFERENCES public.quiz_submissions(id);


--
-- Name: master_courses_migration_results fk_rails_f94a4e9f5d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.master_courses_migration_results
    ADD CONSTRAINT fk_rails_f94a4e9f5d FOREIGN KEY (content_migration_id) REFERENCES public.content_migrations(id);


--
-- Name: alert_criteria fk_rails_f95d56943d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alert_criteria
    ADD CONSTRAINT fk_rails_f95d56943d FOREIGN KEY (alert_id) REFERENCES public.alerts(id);


--
-- Name: assessment_question_banks fk_rails_f991f9b353; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessment_question_banks
    ADD CONSTRAINT fk_rails_f991f9b353 FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: quiz_submission_events_2025_6 fk_rails_f994e0f2d0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quiz_submission_events_2025_6
    ADD CONSTRAINT fk_rails_f994e0f2d0 FOREIGN KEY (quiz_submission_id) REFERENCES public.quiz_submissions(id);


--
-- Name: courses fk_rails_f9bb591b41; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT fk_rails_f9bb591b41 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: courses fk_rails_fa9ac2c08c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT fk_rails_fa9ac2c08c FOREIGN KEY (template_course_id) REFERENCES public.courses(id);


--
-- Name: wiki_page_lookups fk_rails_fab897d3f1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wiki_page_lookups
    ADD CONSTRAINT fk_rails_fab897d3f1 FOREIGN KEY (wiki_page_id) REFERENCES public.wiki_pages(id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: auditor_grade_change_records_2025_6 fk_rails_fb6629633a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_grade_change_records_2025_6
    ADD CONSTRAINT fk_rails_fb6629633a FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: outcome_friendly_descriptions fk_rails_fb78b53f8f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.outcome_friendly_descriptions
    ADD CONSTRAINT fk_rails_fb78b53f8f FOREIGN KEY (root_account_id) REFERENCES public.accounts(id);


--
-- Name: discussion_topic_participants fk_rails_fb902be971; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_topic_participants
    ADD CONSTRAINT fk_rails_fb902be971 FOREIGN KEY (discussion_topic_id) REFERENCES public.discussion_topics(id);


--
-- Name: session_persistence_tokens fk_rails_fc3a4b8b9e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session_persistence_tokens
    ADD CONSTRAINT fk_rails_fc3a4b8b9e FOREIGN KEY (pseudonym_id) REFERENCES public.pseudonyms(id);


--
-- Name: lti_resource_placements fk_rails_fc443660f6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lti_resource_placements
    ADD CONSTRAINT fk_rails_fc443660f6 FOREIGN KEY (message_handler_id) REFERENCES public.lti_message_handlers(id);


--
-- Name: auditor_grade_change_records fk_rails_fe6334e6a1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_grade_change_records
    ADD CONSTRAINT fk_rails_fe6334e6a1 FOREIGN KEY (student_id) REFERENCES public.users(id);


--
-- Name: user_services fk_rails_fea9a826f7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_services
    ADD CONSTRAINT fk_rails_fea9a826f7 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: auditor_course_records fk_rails_feace04d08; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditor_course_records
    ADD CONSTRAINT fk_rails_feace04d08 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: moderated_grading_provisional_grades provisional_grades_source_provisional_grade_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.moderated_grading_provisional_grades
    ADD CONSTRAINT provisional_grades_source_provisional_grade_fk FOREIGN KEY (source_provisional_grade_id) REFERENCES public.moderated_grading_provisional_grades(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "public"."schema_migrations" (version) VALUES
('20101201000090'),
('20101210192618'),
('20101216224513'),
('20101217224513'),
('20111111214312'),
('20141109202906'),
('20240110105826'),
('20240110232431'),
('20240124155444'),
('20240125213845'),
('20240126154129'),
('20240127030819'),
('20240130210940'),
('20240130230259'),
('20240130230351'),
('20240201220924'),
('20240205215654'),
('20240207152106'),
('20240207181908'),
('20240208204317'),
('20240208225234'),
('20240226152508'),
('20240229160528'),
('20240306205029'),
('20240306205030'),
('20240307201034'),
('20240307214953'),
('20240313152338'),
('20240313153539'),
('20240313154359'),
('20240313154717'),
('20240318220115'),
('748091800218022945873'),
('748091800218022945874');


