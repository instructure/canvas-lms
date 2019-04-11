--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.10
-- Dumped by pg_dump version 9.6.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

SET search_path = public, pg_catalog;

--
-- Name: delayed_jobs_after_delete_row_tr_fn(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION delayed_jobs_after_delete_row_tr_fn() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO public
    AS $$
      DECLARE
        running_count integer;
      BEGIN
        IF OLD.strand IS NOT NULL THEN
          PERFORM pg_advisory_xact_lock(half_md5_as_bigint(OLD.strand));
          running_count := (SELECT COUNT(*) FROM delayed_jobs WHERE strand = OLD.strand AND next_in_strand = 't');
          IF running_count < OLD.max_concurrent THEN
            UPDATE delayed_jobs SET next_in_strand = 't' WHERE id IN (
              SELECT id FROM delayed_jobs j2 WHERE next_in_strand = 'f' AND
              j2.strand = OLD.strand ORDER BY j2.id ASC LIMIT (OLD.max_concurrent - running_count) FOR UPDATE
            );
          END IF;
        END IF;
        RETURN OLD;
      END;
      $$;


--
-- Name: delayed_jobs_before_insert_row_tr_fn(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION delayed_jobs_before_insert_row_tr_fn() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO public
    AS $$
      BEGIN
        IF NEW.strand IS NOT NULL THEN
          PERFORM pg_advisory_xact_lock(half_md5_as_bigint(NEW.strand));
          IF (SELECT COUNT(*) FROM delayed_jobs WHERE strand = NEW.strand) >= NEW.max_concurrent THEN
            NEW.next_in_strand := 'f';
          END IF;
        END IF;
        RETURN NEW;
      END;
      $$;


--
-- Name: half_md5_as_bigint(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION half_md5_as_bigint(strand character varying) RETURNS bigint
    LANGUAGE plpgsql
    SET search_path TO public
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


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: abstract_courses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE abstract_courses (
    id bigint NOT NULL,
    sis_source_id character varying(255),
    sis_batch_id bigint,
    account_id bigint NOT NULL,
    root_account_id bigint NOT NULL,
    short_name character varying(255),
    name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    enrollment_term_id bigint NOT NULL,
    workflow_state character varying(255) NOT NULL,
    stuck_sis_fields text
);


--
-- Name: abstract_courses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE abstract_courses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: abstract_courses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE abstract_courses_id_seq OWNED BY abstract_courses.id;


--
-- Name: access_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE access_tokens (
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
    crypted_refresh_token character varying(255)
);


--
-- Name: access_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE access_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: access_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE access_tokens_id_seq OWNED BY access_tokens.id;


--
-- Name: account_authorization_configs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE account_authorization_configs (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    auth_port integer,
    auth_host character varying(255),
    auth_base character varying(255),
    auth_username character varying(255),
    auth_crypted_password character varying(255),
    auth_password_salt character varying(255),
    auth_type character varying(255),
    auth_over_tls character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
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
    settings json DEFAULT '{}'::json NOT NULL
);


--
-- Name: account_authorization_configs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE account_authorization_configs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_authorization_configs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE account_authorization_configs_id_seq OWNED BY account_authorization_configs.id;


--
-- Name: account_notification_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE account_notification_roles (
    id bigint NOT NULL,
    account_notification_id bigint NOT NULL,
    role_id bigint
);


--
-- Name: account_notification_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE account_notification_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_notification_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE account_notification_roles_id_seq OWNED BY account_notification_roles.id;


--
-- Name: account_notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE account_notifications (
    id bigint NOT NULL,
    subject character varying(255),
    icon character varying(255) DEFAULT 'warning'::character varying,
    message text,
    account_id bigint NOT NULL,
    user_id bigint,
    start_at timestamp without time zone NOT NULL,
    end_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    required_account_service character varying(255),
    months_in_display_cycle integer
);


--
-- Name: account_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE account_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE account_notifications_id_seq OWNED BY account_notifications.id;


--
-- Name: account_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE account_reports (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    message text,
    account_id bigint NOT NULL,
    attachment_id bigint,
    workflow_state character varying(255) DEFAULT 'created'::character varying NOT NULL,
    report_type character varying(255),
    progress integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    parameters text,
    current_line integer,
    total_lines integer,
    start_at timestamp without time zone,
    end_at timestamp without time zone
);


--
-- Name: account_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE account_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE account_reports_id_seq OWNED BY account_reports.id;


--
-- Name: account_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE account_users (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    role_id bigint NOT NULL,
    workflow_state character varying DEFAULT 'active'::character varying NOT NULL
);


--
-- Name: account_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE account_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE account_users_id_seq OWNED BY account_users.id;


--
-- Name: accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE accounts (
    id bigint NOT NULL,
    name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    workflow_state character varying(255) DEFAULT 'active'::character varying NOT NULL,
    deleted_at timestamp without time zone,
    parent_account_id bigint,
    sis_source_id character varying(255),
    sis_batch_id bigint,
    current_sis_batch_id bigint,
    root_account_id bigint,
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
    turnitin_originality character varying(255)
);


--
-- Name: accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE accounts_id_seq OWNED BY accounts.id;


--
-- Name: alert_criteria; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE alert_criteria (
    id bigint NOT NULL,
    alert_id bigint,
    criterion_type character varying(255),
    threshold double precision
);


--
-- Name: alert_criteria_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE alert_criteria_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: alert_criteria_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE alert_criteria_id_seq OWNED BY alert_criteria.id;


--
-- Name: alerts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE alerts (
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

CREATE SEQUENCE alerts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: alerts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE alerts_id_seq OWNED BY alerts.id;


--
-- Name: appointment_group_contexts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE appointment_group_contexts (
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

CREATE SEQUENCE appointment_group_contexts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: appointment_group_contexts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE appointment_group_contexts_id_seq OWNED BY appointment_group_contexts.id;


--
-- Name: appointment_group_sub_contexts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE appointment_group_sub_contexts (
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

CREATE SEQUENCE appointment_group_sub_contexts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: appointment_group_sub_contexts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE appointment_group_sub_contexts_id_seq OWNED BY appointment_group_sub_contexts.id;


--
-- Name: appointment_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE appointment_groups (
    id bigint NOT NULL,
    title character varying(255),
    description text,
    location_name character varying(255),
    location_address character varying(255),
    context_id bigint,
    context_type character varying(255),
    context_code character varying(255),
    sub_context_id bigint,
    sub_context_type character varying(255),
    sub_context_code character varying(255),
    workflow_state character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    start_at timestamp without time zone,
    end_at timestamp without time zone,
    participants_per_appointment integer,
    max_appointments_per_participant integer,
    min_appointments_per_participant integer DEFAULT 0,
    participant_visibility character varying(255)
);


--
-- Name: appointment_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE appointment_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: appointment_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE appointment_groups_id_seq OWNED BY appointment_groups.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: assessment_question_bank_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE assessment_question_bank_users (
    id bigint NOT NULL,
    assessment_question_bank_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: assessment_question_bank_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE assessment_question_bank_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assessment_question_bank_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE assessment_question_bank_users_id_seq OWNED BY assessment_question_bank_users.id;


--
-- Name: assessment_question_banks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE assessment_question_banks (
    id bigint NOT NULL,
    context_id bigint,
    context_type character varying(255),
    title text,
    workflow_state character varying(255) NOT NULL,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    migration_id character varying(255)
);


--
-- Name: assessment_question_banks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE assessment_question_banks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assessment_question_banks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE assessment_question_banks_id_seq OWNED BY assessment_question_banks.id;


--
-- Name: assessment_questions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE assessment_questions (
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
    "position" integer
);


--
-- Name: assessment_questions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE assessment_questions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assessment_questions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE assessment_questions_id_seq OWNED BY assessment_questions.id;


--
-- Name: assessment_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE assessment_requests (
    id bigint NOT NULL,
    rubric_assessment_id bigint,
    user_id bigint NOT NULL,
    asset_id bigint NOT NULL,
    asset_type character varying(255) NOT NULL,
    assessor_asset_id bigint NOT NULL,
    assessor_asset_type character varying(255) NOT NULL,
    workflow_state character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    uuid character varying(255),
    rubric_association_id bigint,
    assessor_id bigint NOT NULL
);


--
-- Name: assessment_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE assessment_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assessment_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE assessment_requests_id_seq OWNED BY assessment_requests.id;


--
-- Name: asset_user_accesses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE asset_user_accesses (
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
    membership_type character varying(255)
);


--
-- Name: asset_user_accesses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE asset_user_accesses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: asset_user_accesses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE asset_user_accesses_id_seq OWNED BY asset_user_accesses.id;


--
-- Name: assignment_configuration_tool_lookups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE assignment_configuration_tool_lookups (
    id bigint NOT NULL,
    assignment_id bigint NOT NULL,
    tool_id bigint,
    tool_type character varying(255) NOT NULL,
    subscription_id character varying,
    tool_product_code character varying,
    tool_vendor_code character varying,
    tool_resource_type_code character varying
);


--
-- Name: assignment_configuration_tool_lookups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE assignment_configuration_tool_lookups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assignment_configuration_tool_lookups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE assignment_configuration_tool_lookups_id_seq OWNED BY assignment_configuration_tool_lookups.id;


--
-- Name: assignment_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE assignment_groups (
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
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    cloned_item_id bigint,
    context_code character varying(255),
    migration_id character varying(255),
    sis_source_id character varying(255),
    integration_data text
);


--
-- Name: assignment_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE assignment_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assignment_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE assignment_groups_id_seq OWNED BY assignment_groups.id;


--
-- Name: assignment_override_students; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE assignment_override_students (
    id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    assignment_id bigint,
    assignment_override_id bigint NOT NULL,
    user_id bigint NOT NULL,
    quiz_id bigint
);


--
-- Name: assignment_override_students_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE assignment_override_students_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assignment_override_students_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE assignment_override_students_id_seq OWNED BY assignment_override_students.id;


--
-- Name: assignment_overrides; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE assignment_overrides (
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
    quiz_version integer
);


--
-- Name: assignment_overrides_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE assignment_overrides_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assignment_overrides_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE assignment_overrides_id_seq OWNED BY assignment_overrides.id;


--
-- Name: assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE assignments (
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
    workflow_state character varying(255) NOT NULL,
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
    context_code character varying(255),
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
    lti_context_id character varying
);


--
-- Name: course_sections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE course_sections (
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
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    workflow_state character varying(255) DEFAULT 'active'::character varying NOT NULL,
    restrict_enrollments_to_section_dates boolean,
    nonxlist_course_id bigint,
    stuck_sis_fields text,
    integration_id character varying(255)
);


--
-- Name: courses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE courses (
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
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
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
    home_page_announcement_limit integer
);


--
-- Name: enrollments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE enrollments (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    course_id bigint NOT NULL,
    type character varying(255) NOT NULL,
    uuid character varying(255),
    workflow_state character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
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
    limit_privileges_to_course_section boolean,
    last_activity_at timestamp without time zone,
    total_activity_time integer,
    role_id bigint NOT NULL,
    graded_at timestamp without time zone
);


--
-- Name: group_memberships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE group_memberships (
    id bigint NOT NULL,
    group_id bigint NOT NULL,
    workflow_state character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_id bigint NOT NULL,
    uuid character varying(255) NOT NULL,
    sis_batch_id bigint,
    moderator boolean
);


--
-- Name: groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE groups (
    id bigint NOT NULL,
    name character varying(255),
    workflow_state character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
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
-- Name: submissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE submissions (
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
    process_attempts integer DEFAULT 0,
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
    has_rubric_assessment boolean,
    attempt integer,
    context_code character varying(255),
    media_object_id bigint,
    turnitin_data text,
    has_admin_comment boolean DEFAULT false NOT NULL,
    cached_due_date timestamp without time zone,
    excused boolean,
    graded_anonymously boolean,
    late_policy_status character varying(16),
    points_deducted numeric(6,2),
    grading_period_id bigint,
    seconds_late_override bigint
);


--
-- Name: assignment_student_visibilities; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW assignment_student_visibilities AS
 SELECT DISTINCT a.id AS assignment_id,
    e.user_id,
    c.id AS course_id
   FROM ((((((((assignments a
     JOIN courses c ON (((a.context_id = c.id) AND ((a.context_type)::text = 'Course'::text))))
     JOIN enrollments e ON (((e.course_id = c.id) AND ((e.type)::text = ANY (ARRAY[('StudentEnrollment'::character varying)::text, ('StudentViewEnrollment'::character varying)::text])) AND ((e.workflow_state)::text <> 'deleted'::text))))
     JOIN course_sections cs ON (((cs.course_id = c.id) AND (e.course_section_id = cs.id))))
     LEFT JOIN group_memberships gm ON (((gm.user_id = e.user_id) AND ((gm.workflow_state)::text = 'accepted'::text))))
     LEFT JOIN groups g ON ((((g.context_type)::text = 'Course'::text) AND (g.context_id = c.id) AND ((g.workflow_state)::text = 'available'::text) AND (gm.group_id = g.id))))
     LEFT JOIN assignment_override_students aos ON (((aos.assignment_id = a.id) AND (aos.user_id = e.user_id))))
     LEFT JOIN assignment_overrides ao ON (((ao.assignment_id = a.id) AND ((ao.workflow_state)::text = 'active'::text) AND ((((ao.set_type)::text = 'CourseSection'::text) AND (ao.set_id = cs.id)) OR (((ao.set_type)::text = 'ADHOC'::text) AND (ao.set_id IS NULL) AND (ao.id = aos.assignment_override_id)) OR (((ao.set_type)::text = 'Group'::text) AND (ao.set_id = g.id))))))
     LEFT JOIN submissions s ON (((s.user_id = e.user_id) AND (s.assignment_id = a.id) AND (s.score IS NOT NULL))))
  WHERE (((a.workflow_state)::text <> ALL (ARRAY[('deleted'::character varying)::text, ('unpublished'::character varying)::text])) AND (((a.only_visible_to_overrides = true) AND ((ao.id IS NOT NULL) OR (s.id IS NOT NULL))) OR (COALESCE(a.only_visible_to_overrides, false) = false)));


--
-- Name: assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE assignments_id_seq OWNED BY assignments.id;


--
-- Name: attachment_associations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE attachment_associations (
    id bigint NOT NULL,
    attachment_id bigint,
    context_id bigint,
    context_type character varying(255)
);


--
-- Name: attachment_associations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE attachment_associations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: attachment_associations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE attachment_associations_id_seq OWNED BY attachment_associations.id;


--
-- Name: attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE attachments (
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
    last_lock_at timestamp without time zone,
    last_unlock_at timestamp without time zone,
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
    instfs_uuid character varying
);


--
-- Name: attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE attachments_id_seq OWNED BY attachments.id;


--
-- Name: bookmarks_bookmarks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE bookmarks_bookmarks (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    name character varying(255) NOT NULL,
    url character varying(255) NOT NULL,
    "position" integer,
    json text
);


--
-- Name: bookmarks_bookmarks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE bookmarks_bookmarks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bookmarks_bookmarks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE bookmarks_bookmarks_id_seq OWNED BY bookmarks_bookmarks.id;


--
-- Name: brand_configs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE brand_configs (
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
-- Name: cached_grade_distributions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE cached_grade_distributions (
    course_id bigint NOT NULL,
    s0 integer DEFAULT 0 NOT NULL,
    s1 integer DEFAULT 0 NOT NULL,
    s2 integer DEFAULT 0 NOT NULL,
    s3 integer DEFAULT 0 NOT NULL,
    s4 integer DEFAULT 0 NOT NULL,
    s5 integer DEFAULT 0 NOT NULL,
    s6 integer DEFAULT 0 NOT NULL,
    s7 integer DEFAULT 0 NOT NULL,
    s8 integer DEFAULT 0 NOT NULL,
    s9 integer DEFAULT 0 NOT NULL,
    s10 integer DEFAULT 0 NOT NULL,
    s11 integer DEFAULT 0 NOT NULL,
    s12 integer DEFAULT 0 NOT NULL,
    s13 integer DEFAULT 0 NOT NULL,
    s14 integer DEFAULT 0 NOT NULL,
    s15 integer DEFAULT 0 NOT NULL,
    s16 integer DEFAULT 0 NOT NULL,
    s17 integer DEFAULT 0 NOT NULL,
    s18 integer DEFAULT 0 NOT NULL,
    s19 integer DEFAULT 0 NOT NULL,
    s20 integer DEFAULT 0 NOT NULL,
    s21 integer DEFAULT 0 NOT NULL,
    s22 integer DEFAULT 0 NOT NULL,
    s23 integer DEFAULT 0 NOT NULL,
    s24 integer DEFAULT 0 NOT NULL,
    s25 integer DEFAULT 0 NOT NULL,
    s26 integer DEFAULT 0 NOT NULL,
    s27 integer DEFAULT 0 NOT NULL,
    s28 integer DEFAULT 0 NOT NULL,
    s29 integer DEFAULT 0 NOT NULL,
    s30 integer DEFAULT 0 NOT NULL,
    s31 integer DEFAULT 0 NOT NULL,
    s32 integer DEFAULT 0 NOT NULL,
    s33 integer DEFAULT 0 NOT NULL,
    s34 integer DEFAULT 0 NOT NULL,
    s35 integer DEFAULT 0 NOT NULL,
    s36 integer DEFAULT 0 NOT NULL,
    s37 integer DEFAULT 0 NOT NULL,
    s38 integer DEFAULT 0 NOT NULL,
    s39 integer DEFAULT 0 NOT NULL,
    s40 integer DEFAULT 0 NOT NULL,
    s41 integer DEFAULT 0 NOT NULL,
    s42 integer DEFAULT 0 NOT NULL,
    s43 integer DEFAULT 0 NOT NULL,
    s44 integer DEFAULT 0 NOT NULL,
    s45 integer DEFAULT 0 NOT NULL,
    s46 integer DEFAULT 0 NOT NULL,
    s47 integer DEFAULT 0 NOT NULL,
    s48 integer DEFAULT 0 NOT NULL,
    s49 integer DEFAULT 0 NOT NULL,
    s50 integer DEFAULT 0 NOT NULL,
    s51 integer DEFAULT 0 NOT NULL,
    s52 integer DEFAULT 0 NOT NULL,
    s53 integer DEFAULT 0 NOT NULL,
    s54 integer DEFAULT 0 NOT NULL,
    s55 integer DEFAULT 0 NOT NULL,
    s56 integer DEFAULT 0 NOT NULL,
    s57 integer DEFAULT 0 NOT NULL,
    s58 integer DEFAULT 0 NOT NULL,
    s59 integer DEFAULT 0 NOT NULL,
    s60 integer DEFAULT 0 NOT NULL,
    s61 integer DEFAULT 0 NOT NULL,
    s62 integer DEFAULT 0 NOT NULL,
    s63 integer DEFAULT 0 NOT NULL,
    s64 integer DEFAULT 0 NOT NULL,
    s65 integer DEFAULT 0 NOT NULL,
    s66 integer DEFAULT 0 NOT NULL,
    s67 integer DEFAULT 0 NOT NULL,
    s68 integer DEFAULT 0 NOT NULL,
    s69 integer DEFAULT 0 NOT NULL,
    s70 integer DEFAULT 0 NOT NULL,
    s71 integer DEFAULT 0 NOT NULL,
    s72 integer DEFAULT 0 NOT NULL,
    s73 integer DEFAULT 0 NOT NULL,
    s74 integer DEFAULT 0 NOT NULL,
    s75 integer DEFAULT 0 NOT NULL,
    s76 integer DEFAULT 0 NOT NULL,
    s77 integer DEFAULT 0 NOT NULL,
    s78 integer DEFAULT 0 NOT NULL,
    s79 integer DEFAULT 0 NOT NULL,
    s80 integer DEFAULT 0 NOT NULL,
    s81 integer DEFAULT 0 NOT NULL,
    s82 integer DEFAULT 0 NOT NULL,
    s83 integer DEFAULT 0 NOT NULL,
    s84 integer DEFAULT 0 NOT NULL,
    s85 integer DEFAULT 0 NOT NULL,
    s86 integer DEFAULT 0 NOT NULL,
    s87 integer DEFAULT 0 NOT NULL,
    s88 integer DEFAULT 0 NOT NULL,
    s89 integer DEFAULT 0 NOT NULL,
    s90 integer DEFAULT 0 NOT NULL,
    s91 integer DEFAULT 0 NOT NULL,
    s92 integer DEFAULT 0 NOT NULL,
    s93 integer DEFAULT 0 NOT NULL,
    s94 integer DEFAULT 0 NOT NULL,
    s95 integer DEFAULT 0 NOT NULL,
    s96 integer DEFAULT 0 NOT NULL,
    s97 integer DEFAULT 0 NOT NULL,
    s98 integer DEFAULT 0 NOT NULL,
    s99 integer DEFAULT 0 NOT NULL,
    s100 integer DEFAULT 0 NOT NULL
);


--
-- Name: calendar_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE calendar_events (
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
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
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
    timetable_code character varying(255)
);


--
-- Name: calendar_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE calendar_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: calendar_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE calendar_events_id_seq OWNED BY calendar_events.id;


--
-- Name: canvadocs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE canvadocs (
    id bigint NOT NULL,
    document_id character varying(255),
    process_state character varying(255),
    attachment_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    has_annotations boolean
);


--
-- Name: canvadocs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE canvadocs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: canvadocs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE canvadocs_id_seq OWNED BY canvadocs.id;


--
-- Name: canvadocs_submissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE canvadocs_submissions (
    id bigint NOT NULL,
    canvadoc_id bigint,
    crocodoc_document_id bigint,
    submission_id bigint NOT NULL
);


--
-- Name: canvadocs_submissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE canvadocs_submissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: canvadocs_submissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE canvadocs_submissions_id_seq OWNED BY canvadocs_submissions.id;


--
-- Name: cloned_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE cloned_items (
    id bigint NOT NULL,
    original_item_id bigint,
    original_item_type character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: cloned_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cloned_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cloned_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cloned_items_id_seq OWNED BY cloned_items.id;


--
-- Name: collaborations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE collaborations (
    id bigint NOT NULL,
    collaboration_type character varying(255),
    document_id character varying(255),
    user_id bigint,
    context_id bigint,
    context_type character varying(255),
    url character varying(255),
    uuid character varying(255),
    data text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    description text,
    title character varying(255) NOT NULL,
    workflow_state character varying(255) DEFAULT 'active'::character varying NOT NULL,
    deleted_at timestamp without time zone,
    context_code character varying(255),
    type character varying(255)
);


--
-- Name: collaborations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE collaborations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: collaborations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE collaborations_id_seq OWNED BY collaborations.id;


--
-- Name: collaborators; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE collaborators (
    id bigint NOT NULL,
    user_id bigint,
    collaboration_id bigint,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    authorized_service_user_id character varying(255),
    group_id bigint
);


--
-- Name: collaborators_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE collaborators_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: collaborators_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE collaborators_id_seq OWNED BY collaborators.id;


--
-- Name: communication_channels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE communication_channels (
    id bigint NOT NULL,
    path character varying(255) NOT NULL,
    path_type character varying(255) DEFAULT 'email'::character varying NOT NULL,
    "position" integer,
    user_id bigint NOT NULL,
    pseudonym_id bigint,
    bounce_count integer DEFAULT 0,
    workflow_state character varying(255) NOT NULL,
    confirmation_code character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    build_pseudonym_on_confirm boolean,
    last_bounce_at timestamp without time zone,
    last_bounce_details text,
    last_suppression_bounce_at timestamp without time zone,
    last_transient_bounce_at timestamp without time zone,
    last_transient_bounce_details text,
    confirmation_code_expires_at timestamp without time zone
);


--
-- Name: communication_channels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE communication_channels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: communication_channels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE communication_channels_id_seq OWNED BY communication_channels.id;


--
-- Name: content_exports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE content_exports (
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
    context_id bigint
);


--
-- Name: content_exports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE content_exports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: content_exports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE content_exports_id_seq OWNED BY content_exports.id;


--
-- Name: content_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE content_migrations (
    id bigint NOT NULL,
    context_id bigint NOT NULL,
    user_id bigint,
    workflow_state character varying(255) NOT NULL,
    migration_settings text,
    started_at timestamp without time zone,
    finished_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    progress double precision,
    context_type character varying(255),
    attachment_id bigint,
    overview_attachment_id bigint,
    exported_attachment_id bigint,
    source_course_id bigint,
    migration_type character varying(255),
    child_subscription_id bigint
);


--
-- Name: content_migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE content_migrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: content_migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE content_migrations_id_seq OWNED BY content_migrations.id;


--
-- Name: content_participation_counts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE content_participation_counts (
    id bigint NOT NULL,
    content_type character varying(255),
    context_type character varying(255),
    context_id bigint,
    user_id bigint,
    unread_count integer DEFAULT 0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: content_participation_counts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE content_participation_counts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: content_participation_counts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE content_participation_counts_id_seq OWNED BY content_participation_counts.id;


--
-- Name: content_participations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE content_participations (
    id bigint NOT NULL,
    content_type character varying(255) NOT NULL,
    content_id bigint NOT NULL,
    user_id bigint NOT NULL,
    workflow_state character varying(255) NOT NULL
);


--
-- Name: content_participations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE content_participations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: content_participations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE content_participations_id_seq OWNED BY content_participations.id;


--
-- Name: content_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE content_tags (
    id bigint NOT NULL,
    content_id bigint,
    content_type character varying(255),
    context_id bigint NOT NULL,
    context_type character varying(255) NOT NULL,
    title text,
    tag character varying(255),
    url text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
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
    new_tab boolean
);


--
-- Name: content_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE content_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: content_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE content_tags_id_seq OWNED BY content_tags.id;


--
-- Name: context_external_tool_assignment_lookups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE context_external_tool_assignment_lookups (
    id bigint NOT NULL,
    assignment_id bigint NOT NULL,
    context_external_tool_id bigint NOT NULL
);


--
-- Name: context_external_tool_assignment_lookups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE context_external_tool_assignment_lookups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: context_external_tool_assignment_lookups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE context_external_tool_assignment_lookups_id_seq OWNED BY context_external_tool_assignment_lookups.id;


--
-- Name: context_external_tool_placements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE context_external_tool_placements (
    id bigint NOT NULL,
    placement_type character varying(255),
    context_external_tool_id bigint NOT NULL
);


--
-- Name: context_external_tool_placements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE context_external_tool_placements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: context_external_tool_placements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE context_external_tool_placements_id_seq OWNED BY context_external_tool_placements.id;


--
-- Name: context_external_tools; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE context_external_tools (
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
    app_center_id character varying(255)
);


--
-- Name: context_external_tools_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE context_external_tools_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: context_external_tools_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE context_external_tools_id_seq OWNED BY context_external_tools.id;


--
-- Name: context_module_progressions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE context_module_progressions (
    id bigint NOT NULL,
    context_module_id bigint,
    user_id bigint,
    requirements_met text,
    workflow_state character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    collapsed boolean DEFAULT true,
    current_position integer,
    completed_at timestamp without time zone,
    current boolean,
    lock_version integer DEFAULT 0 NOT NULL,
    evaluated_at timestamp without time zone,
    incomplete_requirements text
);


--
-- Name: context_module_progressions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE context_module_progressions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: context_module_progressions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE context_module_progressions_id_seq OWNED BY context_module_progressions.id;


--
-- Name: context_modules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE context_modules (
    id bigint NOT NULL,
    context_id bigint NOT NULL,
    context_type character varying(255) NOT NULL,
    name text,
    "position" integer,
    prerequisites text,
    completion_requirements text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    workflow_state character varying(255) DEFAULT 'active'::character varying NOT NULL,
    deleted_at timestamp without time zone,
    unlock_at timestamp without time zone,
    migration_id character varying(255),
    require_sequential_progress boolean,
    cloned_item_id bigint,
    completion_events text,
    requirement_count integer
);


--
-- Name: context_modules_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE context_modules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: context_modules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE context_modules_id_seq OWNED BY context_modules.id;


--
-- Name: conversation_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE conversation_batches (
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

CREATE SEQUENCE conversation_batches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: conversation_batches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE conversation_batches_id_seq OWNED BY conversation_batches.id;


--
-- Name: conversation_message_participants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE conversation_message_participants (
    id bigint NOT NULL,
    conversation_message_id bigint,
    conversation_participant_id bigint,
    tags text,
    user_id bigint,
    workflow_state character varying(255),
    deleted_at timestamp without time zone
);


--
-- Name: conversation_message_participants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE conversation_message_participants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: conversation_message_participants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE conversation_message_participants_id_seq OWNED BY conversation_message_participants.id;


--
-- Name: conversation_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE conversation_messages (
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
    has_media_objects boolean
);


--
-- Name: conversation_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE conversation_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: conversation_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE conversation_messages_id_seq OWNED BY conversation_messages.id;


--
-- Name: conversation_participants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE conversation_participants (
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

CREATE SEQUENCE conversation_participants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: conversation_participants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE conversation_participants_id_seq OWNED BY conversation_participants.id;


--
-- Name: conversations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE conversations (
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

CREATE SEQUENCE conversations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: conversations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE conversations_id_seq OWNED BY conversations.id;


--
-- Name: course_account_associations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE course_account_associations (
    id bigint NOT NULL,
    course_id bigint NOT NULL,
    account_id bigint NOT NULL,
    depth integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    course_section_id bigint
);


--
-- Name: course_account_associations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE course_account_associations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: course_account_associations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE course_account_associations_id_seq OWNED BY course_account_associations.id;


--
-- Name: course_sections_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE course_sections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: course_sections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE course_sections_id_seq OWNED BY course_sections.id;


--
-- Name: courses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE courses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: courses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE courses_id_seq OWNED BY courses.id;


--
-- Name: crocodoc_documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE crocodoc_documents (
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

CREATE SEQUENCE crocodoc_documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: crocodoc_documents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE crocodoc_documents_id_seq OWNED BY crocodoc_documents.id;


--
-- Name: custom_data; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE custom_data (
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

CREATE SEQUENCE custom_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: custom_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE custom_data_id_seq OWNED BY custom_data.id;


--
-- Name: custom_gradebook_column_data; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE custom_gradebook_column_data (
    id bigint NOT NULL,
    content character varying(255) NOT NULL,
    user_id bigint NOT NULL,
    custom_gradebook_column_id bigint NOT NULL
);


--
-- Name: custom_gradebook_column_data_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE custom_gradebook_column_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: custom_gradebook_column_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE custom_gradebook_column_data_id_seq OWNED BY custom_gradebook_column_data.id;


--
-- Name: custom_gradebook_columns; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE custom_gradebook_columns (
    id bigint NOT NULL,
    title character varying(255) NOT NULL,
    "position" integer NOT NULL,
    workflow_state character varying(255) DEFAULT 'active'::character varying NOT NULL,
    course_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    teacher_notes boolean DEFAULT false NOT NULL
);


--
-- Name: custom_gradebook_columns_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE custom_gradebook_columns_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: custom_gradebook_columns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE custom_gradebook_columns_id_seq OWNED BY custom_gradebook_columns.id;


--
-- Name: delayed_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE delayed_jobs (
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
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    tag character varying(255),
    max_attempts integer,
    strand character varying(255),
    next_in_strand boolean DEFAULT true NOT NULL,
    source character varying(255),
    max_concurrent integer DEFAULT 1 NOT NULL,
    expires_at timestamp without time zone
);


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE delayed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE delayed_jobs_id_seq OWNED BY delayed_jobs.id;


--
-- Name: delayed_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE delayed_messages (
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
    root_account_id bigint
);


--
-- Name: delayed_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE delayed_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delayed_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE delayed_messages_id_seq OWNED BY delayed_messages.id;


--
-- Name: delayed_notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE delayed_notifications (
    id bigint NOT NULL,
    notification_id bigint NOT NULL,
    asset_id bigint NOT NULL,
    asset_type character varying(255) NOT NULL,
    recipient_keys text,
    workflow_state character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    asset_context_type character varying(255),
    asset_context_id bigint
);


--
-- Name: delayed_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE delayed_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delayed_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE delayed_notifications_id_seq OWNED BY delayed_notifications.id;


--
-- Name: developer_keys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE developer_keys (
    id bigint NOT NULL,
    api_key character varying(255),
    email character varying(255),
    user_name character varying(255),
    account_id bigint,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_id bigint,
    name character varying(255),
    redirect_uri character varying(255),
    icon_url character varying(255),
    sns_arn character varying(255),
    trusted boolean,
    force_token_reuse boolean,
    workflow_state character varying(255) DEFAULT 'active'::character varying NOT NULL,
    replace_tokens boolean,
    auto_expire_tokens boolean,
    redirect_uris character varying(255)[] DEFAULT '{}'::character varying[] NOT NULL,
    notes text,
    access_token_count integer DEFAULT 0 NOT NULL,
    vendor_code character varying
);


--
-- Name: developer_keys_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE developer_keys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: developer_keys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE developer_keys_id_seq OWNED BY developer_keys.id;


--
-- Name: discussion_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE discussion_entries (
    id bigint NOT NULL,
    message text,
    discussion_topic_id bigint,
    user_id bigint,
    parent_id bigint,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    attachment_id bigint,
    workflow_state character varying(255) DEFAULT 'active'::character varying,
    deleted_at timestamp without time zone,
    migration_id character varying(255),
    editor_id bigint,
    root_entry_id bigint,
    depth integer,
    rating_count integer,
    rating_sum integer
);


--
-- Name: discussion_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE discussion_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: discussion_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE discussion_entries_id_seq OWNED BY discussion_entries.id;


--
-- Name: discussion_entry_participants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE discussion_entry_participants (
    id bigint NOT NULL,
    discussion_entry_id bigint NOT NULL,
    user_id bigint NOT NULL,
    workflow_state character varying(255) NOT NULL,
    forced_read_state boolean,
    rating integer
);


--
-- Name: discussion_entry_participants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE discussion_entry_participants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: discussion_entry_participants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE discussion_entry_participants_id_seq OWNED BY discussion_entry_participants.id;


--
-- Name: discussion_topic_materialized_views; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE discussion_topic_materialized_views (
    discussion_topic_id bigint NOT NULL,
    json_structure character varying(10485760),
    participants_array character varying(10485760),
    entry_ids_array character varying(10485760),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    generation_started_at timestamp without time zone
);


--
-- Name: discussion_topic_participants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE discussion_topic_participants (
    id bigint NOT NULL,
    discussion_topic_id bigint NOT NULL,
    user_id bigint NOT NULL,
    unread_entry_count integer DEFAULT 0 NOT NULL,
    workflow_state character varying(255) NOT NULL,
    subscribed boolean
);


--
-- Name: discussion_topic_participants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE discussion_topic_participants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: discussion_topic_participants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE discussion_topic_participants_id_seq OWNED BY discussion_topic_participants.id;


--
-- Name: discussion_topics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE discussion_topics (
    id bigint NOT NULL,
    title character varying(255),
    message text,
    context_id bigint NOT NULL,
    context_type character varying(255) NOT NULL,
    type character varying(255),
    user_id bigint,
    workflow_state character varying(255) NOT NULL,
    last_reply_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
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
    todo_date timestamp without time zone
);


--
-- Name: discussion_topics_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE discussion_topics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: discussion_topics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE discussion_topics_id_seq OWNED BY discussion_topics.id;


--
-- Name: enrollment_dates_overrides; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE enrollment_dates_overrides (
    id bigint NOT NULL,
    enrollment_term_id bigint,
    enrollment_type character varying(255),
    context_id bigint,
    context_type character varying(255),
    start_at timestamp without time zone,
    end_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: enrollment_dates_overrides_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE enrollment_dates_overrides_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: enrollment_dates_overrides_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE enrollment_dates_overrides_id_seq OWNED BY enrollment_dates_overrides.id;


--
-- Name: enrollment_states; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE enrollment_states (
    enrollment_id bigint NOT NULL,
    state character varying(255),
    state_is_current boolean DEFAULT false NOT NULL,
    state_started_at timestamp without time zone,
    state_valid_until timestamp without time zone,
    restricted_access boolean DEFAULT false NOT NULL,
    access_is_current boolean DEFAULT false NOT NULL,
    lock_version integer DEFAULT 0 NOT NULL
);


--
-- Name: enrollment_terms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE enrollment_terms (
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
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    workflow_state character varying(255) DEFAULT 'active'::character varying NOT NULL,
    stuck_sis_fields text,
    integration_id character varying(255),
    grading_period_group_id bigint
);


--
-- Name: enrollment_terms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE enrollment_terms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: enrollment_terms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE enrollment_terms_id_seq OWNED BY enrollment_terms.id;


--
-- Name: enrollments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE enrollments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: enrollments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE enrollments_id_seq OWNED BY enrollments.id;


--
-- Name: eportfolio_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE eportfolio_categories (
    id bigint NOT NULL,
    eportfolio_id bigint NOT NULL,
    name character varying(255),
    "position" integer,
    slug character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: eportfolio_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE eportfolio_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: eportfolio_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE eportfolio_categories_id_seq OWNED BY eportfolio_categories.id;


--
-- Name: eportfolio_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE eportfolio_entries (
    id bigint NOT NULL,
    eportfolio_id bigint NOT NULL,
    eportfolio_category_id bigint NOT NULL,
    "position" integer,
    name character varying(255),
    allow_comments boolean,
    show_comments boolean,
    slug character varying(255),
    content text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: eportfolio_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE eportfolio_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: eportfolio_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE eportfolio_entries_id_seq OWNED BY eportfolio_entries.id;


--
-- Name: eportfolios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE eportfolios (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    name character varying(255),
    public boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    uuid character varying(255),
    workflow_state character varying(255) DEFAULT 'active'::character varying NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: eportfolios_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE eportfolios_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: eportfolios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE eportfolios_id_seq OWNED BY eportfolios.id;


--
-- Name: epub_exports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE epub_exports (
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

CREATE SEQUENCE epub_exports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: epub_exports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE epub_exports_id_seq OWNED BY epub_exports.id;


--
-- Name: error_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE error_reports (
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
    subject character varying(255),
    request_context_id character varying(255),
    account_id bigint,
    zendesk_ticket_id bigint,
    data text,
    category character varying(255)
);


--
-- Name: error_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE error_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: error_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE error_reports_id_seq OWNED BY error_reports.id;


--
-- Name: event_stream_failures; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE event_stream_failures (
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

CREATE SEQUENCE event_stream_failures_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: event_stream_failures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE event_stream_failures_id_seq OWNED BY event_stream_failures.id;


--
-- Name: external_feed_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE external_feed_entries (
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
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: external_feed_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE external_feed_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: external_feed_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE external_feed_entries_id_seq OWNED BY external_feed_entries.id;


--
-- Name: external_feeds; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE external_feeds (
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
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    verbosity character varying(255),
    migration_id character varying(255)
);


--
-- Name: external_feeds_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE external_feeds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: external_feeds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE external_feeds_id_seq OWNED BY external_feeds.id;


--
-- Name: external_integration_keys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE external_integration_keys (
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

CREATE SEQUENCE external_integration_keys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: external_integration_keys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE external_integration_keys_id_seq OWNED BY external_integration_keys.id;


--
-- Name: failed_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE failed_jobs (
    id bigint NOT NULL,
    priority integer DEFAULT 0,
    attempts integer DEFAULT 0,
    handler character varying(512000),
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
    original_job_id bigint,
    source character varying(255),
    expires_at timestamp without time zone
);


--
-- Name: failed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE failed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: failed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE failed_jobs_id_seq OWNED BY failed_jobs.id;


--
-- Name: favorites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE favorites (
    id bigint NOT NULL,
    user_id bigint,
    context_id bigint,
    context_type character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: favorites_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE favorites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: favorites_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE favorites_id_seq OWNED BY favorites.id;


--
-- Name: feature_flags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE feature_flags (
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

CREATE SEQUENCE feature_flags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feature_flags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE feature_flags_id_seq OWNED BY feature_flags.id;


--
-- Name: folders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE folders (
    id bigint NOT NULL,
    name character varying(255),
    full_name text,
    context_id bigint NOT NULL,
    context_type character varying(255) NOT NULL,
    parent_folder_id bigint,
    workflow_state character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    locked boolean,
    lock_at timestamp without time zone,
    unlock_at timestamp without time zone,
    last_lock_at timestamp without time zone,
    last_unlock_at timestamp without time zone,
    cloned_item_id bigint,
    "position" integer,
    submission_context_code character varying(255)
);


--
-- Name: folders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE folders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: folders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE folders_id_seq OWNED BY folders.id;


--
-- Name: gradebook_csvs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE gradebook_csvs (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    attachment_id bigint NOT NULL,
    progress_id bigint NOT NULL,
    course_id bigint NOT NULL
);


--
-- Name: gradebook_csvs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE gradebook_csvs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: gradebook_csvs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE gradebook_csvs_id_seq OWNED BY gradebook_csvs.id;


--
-- Name: gradebook_uploads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE gradebook_uploads (
    id bigint NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    course_id bigint NOT NULL,
    user_id bigint NOT NULL,
    progress_id bigint NOT NULL,
    gradebook character varying(10485760)
);


--
-- Name: gradebook_uploads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE gradebook_uploads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: gradebook_uploads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE gradebook_uploads_id_seq OWNED BY gradebook_uploads.id;


--
-- Name: grading_period_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE grading_period_groups (
    id bigint NOT NULL,
    course_id bigint,
    account_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    workflow_state character varying(255) DEFAULT 'active'::character varying NOT NULL,
    title character varying(255),
    weighted boolean,
    display_totals_for_all_grading_periods boolean DEFAULT false NOT NULL
);


--
-- Name: grading_period_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE grading_period_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: grading_period_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE grading_period_groups_id_seq OWNED BY grading_period_groups.id;


--
-- Name: grading_periods; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE grading_periods (
    id bigint NOT NULL,
    weight double precision,
    start_date timestamp without time zone NOT NULL,
    end_date timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    title character varying(255),
    workflow_state character varying(255) DEFAULT 'active'::character varying NOT NULL,
    grading_period_group_id integer NOT NULL,
    close_date timestamp without time zone
);


--
-- Name: grading_periods_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE grading_periods_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: grading_periods_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE grading_periods_id_seq OWNED BY grading_periods.id;


--
-- Name: grading_standards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE grading_standards (
    id bigint NOT NULL,
    title character varying(255),
    data text,
    context_id bigint NOT NULL,
    context_type character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_id bigint,
    usage_count integer,
    context_code character varying(255),
    workflow_state character varying(255) NOT NULL,
    migration_id character varying(255),
    version integer
);


--
-- Name: grading_standards_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE grading_standards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: grading_standards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE grading_standards_id_seq OWNED BY grading_standards.id;


--
-- Name: group_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE group_categories (
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
    updated_at timestamp without time zone
);


--
-- Name: group_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE group_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: group_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE group_categories_id_seq OWNED BY group_categories.id;


--
-- Name: group_memberships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE group_memberships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: group_memberships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE group_memberships_id_seq OWNED BY group_memberships.id;


--
-- Name: groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE groups_id_seq OWNED BY groups.id;


--
-- Name: ignores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE ignores (
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

CREATE SEQUENCE ignores_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ignores_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ignores_id_seq OWNED BY ignores.id;


--
-- Name: late_policies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE late_policies (
    id bigint NOT NULL,
    course_id bigint NOT NULL,
    missing_submission_deduction_enabled boolean DEFAULT false NOT NULL,
    missing_submission_deduction numeric(5,2) DEFAULT 0 NOT NULL,
    late_submission_deduction_enabled boolean DEFAULT false NOT NULL,
    late_submission_deduction numeric(5,2) DEFAULT 0 NOT NULL,
    late_submission_interval character varying(16) DEFAULT 'day'::character varying NOT NULL,
    late_submission_minimum_percent_enabled boolean DEFAULT false NOT NULL,
    late_submission_minimum_percent numeric(5,2) DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: late_policies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE late_policies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: late_policies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE late_policies_id_seq OWNED BY late_policies.id;


--
-- Name: learning_outcome_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE learning_outcome_groups (
    id bigint NOT NULL,
    context_id bigint,
    context_type character varying(255),
    title character varying(255) NOT NULL,
    learning_outcome_group_id bigint,
    root_learning_outcome_group_id bigint,
    workflow_state character varying(255) NOT NULL,
    description text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    migration_id character varying(255),
    vendor_guid character varying(255),
    low_grade character varying(255),
    high_grade character varying(255),
    vendor_guid_2 character varying(255),
    migration_id_2 character varying(255)
);


--
-- Name: learning_outcome_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE learning_outcome_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: learning_outcome_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE learning_outcome_groups_id_seq OWNED BY learning_outcome_groups.id;


--
-- Name: learning_outcome_question_results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE learning_outcome_question_results (
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
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    submitted_at timestamp without time zone
);


--
-- Name: learning_outcome_question_results_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE learning_outcome_question_results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: learning_outcome_question_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE learning_outcome_question_results_id_seq OWNED BY learning_outcome_question_results.id;


--
-- Name: learning_outcome_results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE learning_outcome_results (
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
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
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
    submitted_at timestamp without time zone
);


--
-- Name: learning_outcome_results_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE learning_outcome_results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: learning_outcome_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE learning_outcome_results_id_seq OWNED BY learning_outcome_results.id;


--
-- Name: learning_outcomes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE learning_outcomes (
    id bigint NOT NULL,
    context_id bigint,
    context_type character varying(255),
    short_description character varying(255) NOT NULL,
    context_code character varying(255),
    description text,
    data text,
    workflow_state character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    migration_id character varying(255),
    vendor_guid character varying(255),
    low_grade character varying(255),
    high_grade character varying(255),
    display_name character varying(255),
    calculation_method character varying(255),
    calculation_int smallint,
    vendor_guid_2 character varying(255),
    migration_id_2 character varying(255)
);


--
-- Name: learning_outcomes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE learning_outcomes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: learning_outcomes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE learning_outcomes_id_seq OWNED BY learning_outcomes.id;


--
-- Name: live_assessments_assessments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE live_assessments_assessments (
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

CREATE SEQUENCE live_assessments_assessments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: live_assessments_assessments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE live_assessments_assessments_id_seq OWNED BY live_assessments_assessments.id;


--
-- Name: live_assessments_results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE live_assessments_results (
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

CREATE SEQUENCE live_assessments_results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: live_assessments_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE live_assessments_results_id_seq OWNED BY live_assessments_results.id;


--
-- Name: live_assessments_submissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE live_assessments_submissions (
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

CREATE SEQUENCE live_assessments_submissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: live_assessments_submissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE live_assessments_submissions_id_seq OWNED BY live_assessments_submissions.id;


--
-- Name: lti_message_handlers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE lti_message_handlers (
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

CREATE SEQUENCE lti_message_handlers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lti_message_handlers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE lti_message_handlers_id_seq OWNED BY lti_message_handlers.id;


--
-- Name: lti_product_families; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE lti_product_families (
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

CREATE SEQUENCE lti_product_families_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lti_product_families_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE lti_product_families_id_seq OWNED BY lti_product_families.id;


--
-- Name: lti_resource_handlers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE lti_resource_handlers (
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

CREATE SEQUENCE lti_resource_handlers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lti_resource_handlers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE lti_resource_handlers_id_seq OWNED BY lti_resource_handlers.id;


--
-- Name: lti_resource_placements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE lti_resource_placements (
    id bigint NOT NULL,
    placement character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    message_handler_id bigint
);


--
-- Name: lti_resource_placements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE lti_resource_placements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lti_resource_placements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE lti_resource_placements_id_seq OWNED BY lti_resource_placements.id;


--
-- Name: lti_tool_consumer_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE lti_tool_consumer_profiles (
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

CREATE SEQUENCE lti_tool_consumer_profiles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lti_tool_consumer_profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE lti_tool_consumer_profiles_id_seq OWNED BY lti_tool_consumer_profiles.id;


--
-- Name: lti_tool_proxies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE lti_tool_proxies (
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
    registration_url text
);


--
-- Name: lti_tool_proxies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE lti_tool_proxies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lti_tool_proxies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE lti_tool_proxies_id_seq OWNED BY lti_tool_proxies.id;


--
-- Name: lti_tool_proxy_bindings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE lti_tool_proxy_bindings (
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

CREATE SEQUENCE lti_tool_proxy_bindings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lti_tool_proxy_bindings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE lti_tool_proxy_bindings_id_seq OWNED BY lti_tool_proxy_bindings.id;


--
-- Name: lti_tool_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE lti_tool_settings (
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

CREATE SEQUENCE lti_tool_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lti_tool_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE lti_tool_settings_id_seq OWNED BY lti_tool_settings.id;


--
-- Name: master_courses_child_content_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE master_courses_child_content_tags (
    id bigint NOT NULL,
    child_subscription_id bigint NOT NULL,
    content_type character varying(255) NOT NULL,
    content_id bigint NOT NULL,
    downstream_changes text,
    migration_id character varying
);


--
-- Name: master_courses_child_content_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE master_courses_child_content_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: master_courses_child_content_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE master_courses_child_content_tags_id_seq OWNED BY master_courses_child_content_tags.id;


--
-- Name: master_courses_child_subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE master_courses_child_subscriptions (
    id bigint NOT NULL,
    master_template_id bigint NOT NULL,
    child_course_id bigint NOT NULL,
    workflow_state character varying(255) NOT NULL,
    use_selective_copy boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: master_courses_child_subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE master_courses_child_subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: master_courses_child_subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE master_courses_child_subscriptions_id_seq OWNED BY master_courses_child_subscriptions.id;


--
-- Name: master_courses_master_content_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE master_courses_master_content_tags (
    id bigint NOT NULL,
    master_template_id bigint NOT NULL,
    content_type character varying(255) NOT NULL,
    content_id bigint NOT NULL,
    current_migration_id bigint,
    restrictions text,
    migration_id character varying,
    use_default_restrictions boolean DEFAULT false NOT NULL
);


--
-- Name: master_courses_master_content_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE master_courses_master_content_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: master_courses_master_content_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE master_courses_master_content_tags_id_seq OWNED BY master_courses_master_content_tags.id;


--
-- Name: master_courses_master_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE master_courses_master_migrations (
    id bigint NOT NULL,
    master_template_id bigint NOT NULL,
    user_id bigint,
    export_results text,
    import_results text,
    exports_started_at timestamp without time zone,
    imports_queued_at timestamp without time zone,
    workflow_state character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    imports_completed_at timestamp without time zone,
    comment text,
    send_notification boolean DEFAULT false NOT NULL,
    migration_settings text
);


--
-- Name: master_courses_master_migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE master_courses_master_migrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: master_courses_master_migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE master_courses_master_migrations_id_seq OWNED BY master_courses_master_migrations.id;


--
-- Name: master_courses_master_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE master_courses_master_templates (
    id bigint NOT NULL,
    course_id bigint NOT NULL,
    full_course boolean DEFAULT true NOT NULL,
    workflow_state character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    active_migration_id bigint,
    default_restrictions text,
    use_default_restrictions_by_type boolean DEFAULT false NOT NULL,
    default_restrictions_by_type text
);


--
-- Name: master_courses_master_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE master_courses_master_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: master_courses_master_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE master_courses_master_templates_id_seq OWNED BY master_courses_master_templates.id;


--
-- Name: master_courses_migration_results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE master_courses_migration_results (
    id bigint NOT NULL,
    master_migration_id bigint NOT NULL,
    content_migration_id bigint NOT NULL,
    child_subscription_id bigint NOT NULL,
    import_type character varying NOT NULL,
    state character varying NOT NULL,
    results text
);


--
-- Name: master_courses_migration_results_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE master_courses_migration_results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: master_courses_migration_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE master_courses_migration_results_id_seq OWNED BY master_courses_migration_results.id;


--
-- Name: media_objects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE media_objects (
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
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    attachment_id bigint,
    total_size integer,
    old_media_id character varying(255)
);


--
-- Name: media_objects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE media_objects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: media_objects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE media_objects_id_seq OWNED BY media_objects.id;


--
-- Name: media_tracks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE media_tracks (
    id bigint NOT NULL,
    user_id bigint,
    media_object_id bigint NOT NULL,
    kind character varying(255) DEFAULT 'subtitles'::character varying,
    locale character varying(255) DEFAULT 'en'::character varying,
    content text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: media_tracks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE media_tracks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: media_tracks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE media_tracks_id_seq OWNED BY media_tracks.id;


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE messages (
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
    asset_context_id bigint,
    asset_context_type character varying(255),
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

CREATE SEQUENCE messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE messages_id_seq OWNED BY messages.id;


--
-- Name: migration_issues; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE migration_issues (
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

CREATE SEQUENCE migration_issues_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: migration_issues_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE migration_issues_id_seq OWNED BY migration_issues.id;


--
-- Name: moderated_grading_provisional_grades; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE moderated_grading_provisional_grades (
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

CREATE SEQUENCE moderated_grading_provisional_grades_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: moderated_grading_provisional_grades_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE moderated_grading_provisional_grades_id_seq OWNED BY moderated_grading_provisional_grades.id;


--
-- Name: moderated_grading_selections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE moderated_grading_selections (
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

CREATE SEQUENCE moderated_grading_selections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: moderated_grading_selections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE moderated_grading_selections_id_seq OWNED BY moderated_grading_selections.id;


--
-- Name: notification_endpoints; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE notification_endpoints (
    id bigint NOT NULL,
    access_token_id bigint NOT NULL,
    token character varying(255) NOT NULL,
    arn character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: notification_endpoints_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE notification_endpoints_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notification_endpoints_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE notification_endpoints_id_seq OWNED BY notification_endpoints.id;


--
-- Name: notification_policies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE notification_policies (
    id bigint NOT NULL,
    notification_id bigint,
    communication_channel_id bigint NOT NULL,
    frequency character varying(255) DEFAULT 'immediately'::character varying NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: notification_policies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE notification_policies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notification_policies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE notification_policies_id_seq OWNED BY notification_policies.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE notifications (
    id bigint NOT NULL,
    workflow_state character varying(255) NOT NULL,
    name character varying(255),
    subject character varying(255),
    category character varying(255),
    delay_for integer DEFAULT 120,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    main_link character varying(255)
);


--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE notifications_id_seq OWNED BY notifications.id;


--
-- Name: oauth_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE oauth_requests (
    id bigint NOT NULL,
    token character varying(255),
    secret character varying(255),
    user_secret character varying(255),
    return_url character varying(4096),
    workflow_state character varying(255),
    user_id bigint,
    original_host_with_port character varying(255),
    service character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: oauth_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE oauth_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE oauth_requests_id_seq OWNED BY oauth_requests.id;


--
-- Name: one_time_passwords; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE one_time_passwords (
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

CREATE SEQUENCE one_time_passwords_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: one_time_passwords_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE one_time_passwords_id_seq OWNED BY one_time_passwords.id;


--
-- Name: originality_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE originality_reports (
    id bigint NOT NULL,
    attachment_id bigint NOT NULL,
    originality_score double precision,
    originality_report_attachment_id bigint,
    originality_report_url text,
    originality_report_lti_url text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    submission_id bigint NOT NULL,
    workflow_state character varying DEFAULT 'pending'::character varying NOT NULL,
    link_id text
);


--
-- Name: originality_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE originality_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: originality_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE originality_reports_id_seq OWNED BY originality_reports.id;


--
-- Name: page_comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE page_comments (
    id bigint NOT NULL,
    message text,
    page_id bigint,
    page_type character varying(255),
    user_id bigint,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: page_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE page_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: page_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE page_comments_id_seq OWNED BY page_comments.id;


--
-- Name: page_views; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE page_views (
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
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
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
-- Name: page_views_rollups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE page_views_rollups (
    id bigint NOT NULL,
    course_id bigint NOT NULL,
    date date NOT NULL,
    category character varying(255) NOT NULL,
    views integer DEFAULT 0 NOT NULL,
    participations integer DEFAULT 0 NOT NULL
);


--
-- Name: page_views_rollups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE page_views_rollups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: page_views_rollups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE page_views_rollups_id_seq OWNED BY page_views_rollups.id;


--
-- Name: planner_notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE planner_notes (
    id bigint NOT NULL,
    todo_date timestamp without time zone NOT NULL,
    title character varying NOT NULL,
    details text,
    user_id bigint NOT NULL,
    course_id bigint,
    workflow_state character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: planner_notes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE planner_notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: planner_notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE planner_notes_id_seq OWNED BY planner_notes.id;


--
-- Name: planner_overrides; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE planner_overrides (
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

CREATE SEQUENCE planner_overrides_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: planner_overrides_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE planner_overrides_id_seq OWNED BY planner_overrides.id;


--
-- Name: plugin_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE plugin_settings (
    id bigint NOT NULL,
    name character varying(255) DEFAULT ''::character varying NOT NULL,
    settings text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    disabled boolean
);


--
-- Name: plugin_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE plugin_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: plugin_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE plugin_settings_id_seq OWNED BY plugin_settings.id;


--
-- Name: polling_poll_choices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE polling_poll_choices (
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

CREATE SEQUENCE polling_poll_choices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: polling_poll_choices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE polling_poll_choices_id_seq OWNED BY polling_poll_choices.id;


--
-- Name: polling_poll_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE polling_poll_sessions (
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

CREATE SEQUENCE polling_poll_sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: polling_poll_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE polling_poll_sessions_id_seq OWNED BY polling_poll_sessions.id;


--
-- Name: polling_poll_submissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE polling_poll_submissions (
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

CREATE SEQUENCE polling_poll_submissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: polling_poll_submissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE polling_poll_submissions_id_seq OWNED BY polling_poll_submissions.id;


--
-- Name: polling_polls; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE polling_polls (
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

CREATE SEQUENCE polling_polls_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: polling_polls_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE polling_polls_id_seq OWNED BY polling_polls.id;


--
-- Name: profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE profiles (
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

CREATE SEQUENCE profiles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE profiles_id_seq OWNED BY profiles.id;


--
-- Name: progresses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE progresses (
    id bigint NOT NULL,
    context_id bigint NOT NULL,
    context_type character varying(255) NOT NULL,
    user_id bigint,
    tag character varying(255) NOT NULL,
    completion double precision,
    delayed_job_id character varying(255),
    workflow_state character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    message text,
    cache_key_context character varying(255),
    results text
);


--
-- Name: progresses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE progresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: progresses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE progresses_id_seq OWNED BY progresses.id;


--
-- Name: pseudonyms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE pseudonyms (
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
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    password_auto_generated boolean,
    deleted_at timestamp without time zone,
    sis_batch_id bigint,
    sis_user_id character varying(255),
    sis_ssha character varying(255),
    communication_channel_id bigint,
    sis_communication_channel_id bigint,
    stuck_sis_fields text,
    integration_id character varying(255),
    authentication_provider_id bigint
);


--
-- Name: pseudonyms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE pseudonyms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pseudonyms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE pseudonyms_id_seq OWNED BY pseudonyms.id;


--
-- Name: purgatories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE purgatories (
    id bigint NOT NULL,
    attachment_id bigint NOT NULL,
    deleted_by_user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    workflow_state character varying DEFAULT 'active'::character varying NOT NULL,
    old_filename character varying NOT NULL
);


--
-- Name: purgatories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE purgatories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: purgatories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE purgatories_id_seq OWNED BY purgatories.id;


--
-- Name: quiz_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE quiz_groups (
    id bigint NOT NULL,
    quiz_id bigint NOT NULL,
    name character varying(255),
    pick_count integer,
    question_points double precision,
    "position" integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    migration_id character varying(255),
    assessment_question_bank_id bigint
);


--
-- Name: quiz_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE quiz_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: quiz_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE quiz_groups_id_seq OWNED BY quiz_groups.id;


--
-- Name: quiz_question_regrades; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE quiz_question_regrades (
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

CREATE SEQUENCE quiz_question_regrades_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: quiz_question_regrades_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE quiz_question_regrades_id_seq OWNED BY quiz_question_regrades.id;


--
-- Name: quiz_questions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE quiz_questions (
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
    duplicate_index integer
);


--
-- Name: quiz_questions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE quiz_questions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: quiz_questions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE quiz_questions_id_seq OWNED BY quiz_questions.id;


--
-- Name: quiz_regrade_runs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE quiz_regrade_runs (
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

CREATE SEQUENCE quiz_regrade_runs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: quiz_regrade_runs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE quiz_regrade_runs_id_seq OWNED BY quiz_regrade_runs.id;


--
-- Name: quiz_regrades; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE quiz_regrades (
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

CREATE SEQUENCE quiz_regrades_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: quiz_regrades_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE quiz_regrades_id_seq OWNED BY quiz_regrades.id;


--
-- Name: quiz_statistics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE quiz_statistics (
    id bigint NOT NULL,
    quiz_id bigint,
    includes_all_versions boolean,
    anonymous boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    report_type character varying(255)
);


--
-- Name: quiz_statistics_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE quiz_statistics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: quiz_statistics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE quiz_statistics_id_seq OWNED BY quiz_statistics.id;


--
-- Name: quizzes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE quizzes (
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
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
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
    show_correct_answers_last_attempt boolean DEFAULT false NOT NULL
);


--
-- Name: quiz_student_visibilities; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW quiz_student_visibilities AS
 SELECT DISTINCT q.id AS quiz_id,
    e.user_id,
    c.id AS course_id
   FROM (((((((quizzes q
     JOIN courses c ON (((q.context_id = c.id) AND ((q.context_type)::text = 'Course'::text))))
     JOIN enrollments e ON (((e.course_id = c.id) AND ((e.type)::text = ANY (ARRAY[('StudentEnrollment'::character varying)::text, ('StudentViewEnrollment'::character varying)::text])) AND ((e.workflow_state)::text <> 'deleted'::text))))
     JOIN course_sections cs ON (((cs.course_id = c.id) AND (e.course_section_id = cs.id))))
     LEFT JOIN assignment_override_students aos ON (((aos.quiz_id = q.id) AND (aos.user_id = e.user_id))))
     LEFT JOIN assignment_overrides ao ON (((ao.quiz_id = q.id) AND ((ao.workflow_state)::text = 'active'::text) AND ((((ao.set_type)::text = 'CourseSection'::text) AND (ao.set_id = cs.id)) OR (((ao.set_type)::text = 'ADHOC'::text) AND (ao.set_id IS NULL) AND (ao.id = aos.assignment_override_id))))))
     LEFT JOIN assignments a ON (((a.context_id = q.context_id) AND ((a.submission_types)::text ~~ 'online_quiz'::text) AND (a.id = q.assignment_id))))
     LEFT JOIN submissions s ON (((s.user_id = e.user_id) AND (s.assignment_id = a.id) AND (s.score IS NOT NULL))))
  WHERE (((q.workflow_state)::text <> ALL (ARRAY[('deleted'::character varying)::text, ('unpublished'::character varying)::text])) AND (((q.only_visible_to_overrides = true) AND ((ao.id IS NOT NULL) OR (s.id IS NOT NULL))) OR (COALESCE(q.only_visible_to_overrides, false) = false)));


--
-- Name: quiz_submission_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE quiz_submission_events (
    id bigint NOT NULL,
    attempt integer NOT NULL,
    event_type character varying(255) NOT NULL,
    quiz_submission_id bigint NOT NULL,
    event_data text,
    created_at timestamp without time zone NOT NULL,
    client_timestamp timestamp without time zone
);


--
-- Name: quiz_submission_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE quiz_submission_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: quiz_submission_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE quiz_submission_events_id_seq OWNED BY quiz_submission_events.id;


--
-- Name: quiz_submission_events_2018_12; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE quiz_submission_events_2018_12 (
    id bigint DEFAULT nextval('quiz_submission_events_id_seq'::regclass),
    attempt integer,
    event_type character varying(255),
    quiz_submission_id bigint,
    event_data text,
    created_at timestamp without time zone,
    CONSTRAINT quiz_submission_events_2018_12_created_at_check CHECK (((created_at >= '2018-12-01 00:00:00'::timestamp without time zone) AND (created_at < '2019-01-01 00:00:00'::timestamp without time zone)))
)
INHERITS (quiz_submission_events);


--
-- Name: quiz_submission_events_2019_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE quiz_submission_events_2019_1 (
    id bigint DEFAULT nextval('quiz_submission_events_id_seq'::regclass),
    attempt integer,
    event_type character varying(255),
    quiz_submission_id bigint,
    event_data text,
    created_at timestamp without time zone,
    CONSTRAINT quiz_submission_events_2019_1_created_at_check CHECK (((created_at >= '2019-01-01 00:00:00'::timestamp without time zone) AND (created_at < '2019-02-01 00:00:00'::timestamp without time zone)))
)
INHERITS (quiz_submission_events);


--
-- Name: quiz_submission_events_2019_2; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE quiz_submission_events_2019_2 (
    id bigint DEFAULT nextval('quiz_submission_events_id_seq'::regclass),
    attempt integer,
    event_type character varying(255),
    quiz_submission_id bigint,
    event_data text,
    created_at timestamp without time zone,
    CONSTRAINT quiz_submission_events_2019_2_created_at_check CHECK (((created_at >= '2019-02-01 00:00:00'::timestamp without time zone) AND (created_at < '2019-03-01 00:00:00'::timestamp without time zone)))
)
INHERITS (quiz_submission_events);


--
-- Name: quiz_submission_events_2019_3; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE quiz_submission_events_2019_3 (
    id bigint DEFAULT nextval('quiz_submission_events_id_seq'::regclass),
    attempt integer,
    event_type character varying(255),
    quiz_submission_id bigint,
    event_data text,
    created_at timestamp without time zone,
    client_timestamp timestamp without time zone,
    CONSTRAINT quiz_submission_events_2019_3_created_at_check CHECK (((created_at >= '2019-03-01 00:00:00'::timestamp without time zone) AND (created_at < '2019-04-01 00:00:00'::timestamp without time zone)))
)
INHERITS (quiz_submission_events);


--
-- Name: quiz_submission_events_2019_4; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE quiz_submission_events_2019_4 (
    id bigint DEFAULT nextval('quiz_submission_events_id_seq'::regclass),
    attempt integer,
    event_type character varying(255),
    quiz_submission_id bigint,
    event_data text,
    created_at timestamp without time zone,
    client_timestamp timestamp without time zone,
    CONSTRAINT quiz_submission_events_2019_4_created_at_check CHECK (((created_at >= '2019-04-01 00:00:00'::timestamp without time zone) AND (created_at < '2019-05-01 00:00:00'::timestamp without time zone)))
)
INHERITS (quiz_submission_events);


--
-- Name: quiz_submission_events_2019_5; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE quiz_submission_events_2019_5 (
    id bigint DEFAULT nextval('quiz_submission_events_id_seq'::regclass),
    attempt integer,
    event_type character varying(255),
    quiz_submission_id bigint,
    event_data text,
    created_at timestamp without time zone,
    client_timestamp timestamp without time zone,
    CONSTRAINT quiz_submission_events_2019_5_created_at_check CHECK (((created_at >= '2019-05-01 00:00:00'::timestamp without time zone) AND (created_at < '2019-06-01 00:00:00'::timestamp without time zone)))
)
INHERITS (quiz_submission_events);


--
-- Name: quiz_submission_events_2019_6; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE quiz_submission_events_2019_6 (
    id bigint DEFAULT nextval('quiz_submission_events_id_seq'::regclass),
    attempt integer,
    event_type character varying(255),
    quiz_submission_id bigint,
    event_data text,
    created_at timestamp without time zone,
    client_timestamp timestamp without time zone,
    CONSTRAINT quiz_submission_events_2019_6_created_at_check CHECK (((created_at >= '2019-06-01 00:00:00'::timestamp without time zone) AND (created_at < '2019-07-01 00:00:00'::timestamp without time zone)))
)
INHERITS (quiz_submission_events);


--
-- Name: quiz_submission_snapshots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE quiz_submission_snapshots (
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

CREATE SEQUENCE quiz_submission_snapshots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: quiz_submission_snapshots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE quiz_submission_snapshots_id_seq OWNED BY quiz_submission_snapshots.id;


--
-- Name: quiz_submissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE quiz_submissions (
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
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
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
    question_references_fixed boolean
);


--
-- Name: quiz_submissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE quiz_submissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: quiz_submissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE quiz_submissions_id_seq OWNED BY quiz_submissions.id;


--
-- Name: quizzes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE quizzes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: quizzes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE quizzes_id_seq OWNED BY quizzes.id;


--
-- Name: report_snapshots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE report_snapshots (
    id bigint NOT NULL,
    report_type character varying(255),
    data text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    account_id bigint
);


--
-- Name: report_snapshots_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE report_snapshots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: report_snapshots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE report_snapshots_id_seq OWNED BY report_snapshots.id;


--
-- Name: role_overrides; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE role_overrides (
    id bigint NOT NULL,
    permission character varying(255),
    enabled boolean DEFAULT true NOT NULL,
    locked boolean DEFAULT false NOT NULL,
    context_id bigint,
    context_type character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    applies_to_self boolean DEFAULT true NOT NULL,
    applies_to_descendants boolean DEFAULT true NOT NULL,
    role_id bigint NOT NULL
);


--
-- Name: role_overrides_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE role_overrides_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: role_overrides_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE role_overrides_id_seq OWNED BY role_overrides.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE roles (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    base_role_type character varying(255) NOT NULL,
    account_id bigint,
    workflow_state character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    root_account_id bigint
);


--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE roles_id_seq OWNED BY roles.id;


--
-- Name: rubric_assessments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE rubric_assessments (
    id bigint NOT NULL,
    user_id bigint,
    rubric_id bigint NOT NULL,
    rubric_association_id bigint,
    score double precision,
    data text,
    comments text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    artifact_id bigint NOT NULL,
    artifact_type character varying(255) NOT NULL,
    assessment_type character varying(255) NOT NULL,
    assessor_id bigint,
    artifact_attempt integer
);


--
-- Name: rubric_assessments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE rubric_assessments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rubric_assessments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE rubric_assessments_id_seq OWNED BY rubric_assessments.id;


--
-- Name: rubric_associations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE rubric_associations (
    id bigint NOT NULL,
    rubric_id bigint NOT NULL,
    association_id bigint NOT NULL,
    association_type character varying(255) NOT NULL,
    use_for_grading boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    title character varying(255),
    summary_data text,
    purpose character varying(255) NOT NULL,
    url character varying(255),
    context_id bigint NOT NULL,
    context_type character varying(255) NOT NULL,
    hide_score_total boolean,
    bookmarked boolean DEFAULT true,
    context_code character varying(255)
);


--
-- Name: rubric_associations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE rubric_associations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rubric_associations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE rubric_associations_id_seq OWNED BY rubric_associations.id;


--
-- Name: rubrics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE rubrics (
    id bigint NOT NULL,
    user_id bigint,
    rubric_id bigint,
    context_id bigint NOT NULL,
    context_type character varying(255) NOT NULL,
    data text,
    points_possible double precision,
    title character varying(255),
    description text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    reusable boolean DEFAULT false,
    public boolean DEFAULT false,
    read_only boolean DEFAULT false,
    association_count integer DEFAULT 0,
    free_form_criterion_comments boolean,
    context_code character varying(255),
    migration_id character varying(255),
    hide_score_total boolean,
    workflow_state character varying(255) DEFAULT 'active'::character varying NOT NULL
);


--
-- Name: rubrics_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE rubrics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rubrics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE rubrics_id_seq OWNED BY rubrics.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: scores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE scores (
    id bigint NOT NULL,
    enrollment_id bigint NOT NULL,
    grading_period_id bigint,
    workflow_state character varying(255) DEFAULT 'active'::character varying NOT NULL,
    current_score double precision,
    final_score double precision,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: scores_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE scores_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scores_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE scores_id_seq OWNED BY scores.id;


--
-- Name: scribd_mime_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE scribd_mime_types (
    id bigint NOT NULL,
    extension character varying(255),
    name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: scribd_mime_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE scribd_mime_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scribd_mime_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE scribd_mime_types_id_seq OWNED BY scribd_mime_types.id;


--
-- Name: session_persistence_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE session_persistence_tokens (
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

CREATE SEQUENCE session_persistence_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: session_persistence_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE session_persistence_tokens_id_seq OWNED BY session_persistence_tokens.id;


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sessions (
    id bigint NOT NULL,
    session_id character varying(255) NOT NULL,
    data text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sessions_id_seq OWNED BY sessions.id;


--
-- Name: settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE settings (
    id bigint NOT NULL,
    name character varying(255),
    value text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE settings_id_seq OWNED BY settings.id;


--
-- Name: shared_brand_configs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE shared_brand_configs (
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

CREATE SEQUENCE shared_brand_configs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: shared_brand_configs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE shared_brand_configs_id_seq OWNED BY shared_brand_configs.id;


--
-- Name: sis_batch_error_files; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sis_batch_error_files (
    id bigint NOT NULL,
    sis_batch_id bigint NOT NULL,
    attachment_id bigint NOT NULL
);


--
-- Name: sis_batch_error_files_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sis_batch_error_files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sis_batch_error_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sis_batch_error_files_id_seq OWNED BY sis_batch_error_files.id;


--
-- Name: sis_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sis_batches (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    ended_at timestamp without time zone,
    workflow_state character varying(255) NOT NULL,
    data text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
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
    change_threshold integer
);


--
-- Name: sis_batches_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sis_batches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sis_batches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sis_batches_id_seq OWNED BY sis_batches.id;


--
-- Name: sis_post_grades_statuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sis_post_grades_statuses (
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

CREATE SEQUENCE sis_post_grades_statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sis_post_grades_statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sis_post_grades_statuses_id_seq OWNED BY sis_post_grades_statuses.id;


--
-- Name: stream_item_instances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE stream_item_instances (
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

CREATE SEQUENCE stream_item_instances_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stream_item_instances_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE stream_item_instances_id_seq OWNED BY stream_item_instances.id;


--
-- Name: stream_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE stream_items (
    id bigint NOT NULL,
    data text NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    context_type character varying(255),
    context_id bigint,
    asset_type character varying(255) NOT NULL,
    asset_id bigint,
    notification_category character varying(255)
);


--
-- Name: stream_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE stream_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stream_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE stream_items_id_seq OWNED BY stream_items.id;


--
-- Name: submission_comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE submission_comments (
    id bigint NOT NULL,
    comment text,
    submission_id bigint,
    author_id bigint,
    author_name character varying(255),
    group_comment_id character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
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
    draft boolean DEFAULT false NOT NULL
);


--
-- Name: submission_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE submission_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: submission_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE submission_comments_id_seq OWNED BY submission_comments.id;


--
-- Name: submission_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE submission_versions (
    id bigint NOT NULL,
    context_id bigint,
    context_type character varying(255),
    version_id bigint,
    user_id bigint,
    assignment_id bigint
);


--
-- Name: submission_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE submission_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: submission_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE submission_versions_id_seq OWNED BY submission_versions.id;


--
-- Name: submissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE submissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: submissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE submissions_id_seq OWNED BY submissions.id;


--
-- Name: switchman_shards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE switchman_shards (
    id bigint NOT NULL,
    name character varying(255),
    database_server_id character varying(255),
    "default" boolean DEFAULT false NOT NULL,
    settings text
);


--
-- Name: switchman_shards_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE switchman_shards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: switchman_shards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE switchman_shards_id_seq OWNED BY switchman_shards.id;


--
-- Name: thumbnails; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE thumbnails (
    id bigint NOT NULL,
    parent_id bigint,
    content_type character varying(255) NOT NULL,
    filename character varying(255) NOT NULL,
    thumbnail character varying(255),
    size integer NOT NULL,
    width integer,
    height integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    uuid character varying(255),
    namespace character varying(255)
);


--
-- Name: thumbnails_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE thumbnails_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: thumbnails_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE thumbnails_id_seq OWNED BY thumbnails.id;


--
-- Name: usage_rights; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE usage_rights (
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

CREATE SEQUENCE usage_rights_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: usage_rights_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE usage_rights_id_seq OWNED BY usage_rights.id;


--
-- Name: user_account_associations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE user_account_associations (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    account_id bigint NOT NULL,
    depth integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: user_account_associations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_account_associations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_account_associations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_account_associations_id_seq OWNED BY user_account_associations.id;


--
-- Name: user_merge_data; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE user_merge_data (
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

CREATE SEQUENCE user_merge_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_merge_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_merge_data_id_seq OWNED BY user_merge_data.id;


--
-- Name: user_merge_data_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE user_merge_data_records (
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

CREATE SEQUENCE user_merge_data_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_merge_data_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_merge_data_records_id_seq OWNED BY user_merge_data_records.id;


--
-- Name: user_notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE user_notes (
    id bigint NOT NULL,
    user_id bigint,
    note text,
    title character varying(255),
    created_by_id bigint,
    workflow_state character varying(255) DEFAULT 'active'::character varying NOT NULL,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: user_notes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_notes_id_seq OWNED BY user_notes.id;


--
-- Name: user_observers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE user_observers (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    observer_id bigint NOT NULL,
    workflow_state character varying(255) DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    sis_batch_id bigint
);


--
-- Name: user_observers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_observers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_observers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_observers_id_seq OWNED BY user_observers.id;


--
-- Name: user_profile_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE user_profile_links (
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

CREATE SEQUENCE user_profile_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_profile_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_profile_links_id_seq OWNED BY user_profile_links.id;


--
-- Name: user_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE user_profiles (
    id bigint NOT NULL,
    bio text,
    title character varying(255),
    user_id bigint
);


--
-- Name: user_profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_profiles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_profiles_id_seq OWNED BY user_profiles.id;


--
-- Name: user_services; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE user_services (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    token text,
    secret character varying(255),
    protocol character varying(255),
    service character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
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

CREATE SEQUENCE user_services_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_services_id_seq OWNED BY user_services.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE users (
    id bigint NOT NULL,
    name character varying(255),
    sortable_name character varying(255),
    workflow_state character varying(255) NOT NULL,
    time_zone character varying(255),
    uuid character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    avatar_image_url character varying(255),
    avatar_image_source character varying(255),
    avatar_image_updated_at timestamp without time zone,
    phone character varying(255),
    school_name character varying(255),
    school_position character varying(255),
    short_name character varying(255),
    deleted_at timestamp without time zone,
    show_user_services boolean DEFAULT true,
    gender character varying(255),
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
    birthdate timestamp without time zone,
    otp_secret_key_enc character varying(255),
    otp_secret_key_salt character varying(255),
    otp_communication_channel_id bigint,
    initial_enrollment_type character varying(255),
    crocodoc_id integer,
    last_logged_out timestamp without time zone,
    lti_context_id character varying(255),
    turnitin_id bigint
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE versions (
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

CREATE SEQUENCE versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE versions_id_seq OWNED BY versions.id;


--
-- Name: versions_0; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE versions_0 (
    id bigint DEFAULT nextval('versions_id_seq'::regclass),
    versionable_id bigint,
    versionable_type character varying(255),
    number integer,
    yaml text,
    created_at timestamp without time zone,
    CONSTRAINT versions_0_versionable_id_check CHECK ((versionable_id < 5000000))
)
INHERITS (versions);


--
-- Name: versions_1; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE versions_1 (
    id bigint DEFAULT nextval('versions_id_seq'::regclass),
    versionable_id bigint,
    versionable_type character varying(255),
    number integer,
    yaml text,
    created_at timestamp without time zone,
    CONSTRAINT versions_1_versionable_id_check CHECK (((versionable_id >= 5000000) AND (versionable_id < 10000000)))
)
INHERITS (versions);


--
-- Name: versions_2; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE versions_2 (
    id bigint DEFAULT nextval('versions_id_seq'::regclass),
    versionable_id bigint,
    versionable_type character varying(255),
    number integer,
    yaml text,
    created_at timestamp without time zone,
    CONSTRAINT versions_2_versionable_id_check CHECK (((versionable_id >= 10000000) AND (versionable_id < 15000000)))
)
INHERITS (versions);


--
-- Name: web_conference_participants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE web_conference_participants (
    id bigint NOT NULL,
    user_id bigint,
    web_conference_id bigint,
    participation_type character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: web_conference_participants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE web_conference_participants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: web_conference_participants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE web_conference_participants_id_seq OWNED BY web_conference_participants.id;


--
-- Name: web_conferences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE web_conferences (
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
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    uuid character varying(255),
    invited_user_ids character varying(255),
    ended_at timestamp without time zone,
    start_at timestamp without time zone,
    end_at timestamp without time zone,
    context_code character varying(255),
    type character varying(255),
    settings text,
    recording_ready boolean
);


--
-- Name: web_conferences_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE web_conferences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: web_conferences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE web_conferences_id_seq OWNED BY web_conferences.id;


--
-- Name: wiki_pages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE wiki_pages (
    id bigint NOT NULL,
    wiki_id bigint NOT NULL,
    title character varying(255),
    body text,
    workflow_state character varying(255) NOT NULL,
    user_id bigint,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    url text,
    protected_editing boolean DEFAULT false,
    editing_roles character varying(255),
    view_count integer DEFAULT 0,
    revised_at timestamp without time zone,
    could_be_locked boolean,
    cloned_item_id bigint,
    migration_id character varying(255),
    assignment_id bigint,
    old_assignment_id bigint,
    todo_date timestamp without time zone,
    context_id bigint NOT NULL,
    context_type character varying NOT NULL
);


--
-- Name: wiki_pages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE wiki_pages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wiki_pages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE wiki_pages_id_seq OWNED BY wiki_pages.id;


--
-- Name: wikis; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE wikis (
    id bigint NOT NULL,
    title character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    front_page_url text,
    has_no_front_page boolean
);


--
-- Name: wikis_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE wikis_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wikis_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE wikis_id_seq OWNED BY wikis.id;


--
-- Name: abstract_courses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY abstract_courses ALTER COLUMN id SET DEFAULT nextval('abstract_courses_id_seq'::regclass);


--
-- Name: access_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY access_tokens ALTER COLUMN id SET DEFAULT nextval('access_tokens_id_seq'::regclass);


--
-- Name: account_authorization_configs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY account_authorization_configs ALTER COLUMN id SET DEFAULT nextval('account_authorization_configs_id_seq'::regclass);


--
-- Name: account_notification_roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY account_notification_roles ALTER COLUMN id SET DEFAULT nextval('account_notification_roles_id_seq'::regclass);


--
-- Name: account_notifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY account_notifications ALTER COLUMN id SET DEFAULT nextval('account_notifications_id_seq'::regclass);


--
-- Name: account_reports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY account_reports ALTER COLUMN id SET DEFAULT nextval('account_reports_id_seq'::regclass);


--
-- Name: account_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY account_users ALTER COLUMN id SET DEFAULT nextval('account_users_id_seq'::regclass);


--
-- Name: accounts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY accounts ALTER COLUMN id SET DEFAULT nextval('accounts_id_seq'::regclass);


--
-- Name: alert_criteria id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY alert_criteria ALTER COLUMN id SET DEFAULT nextval('alert_criteria_id_seq'::regclass);


--
-- Name: alerts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY alerts ALTER COLUMN id SET DEFAULT nextval('alerts_id_seq'::regclass);


--
-- Name: appointment_group_contexts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY appointment_group_contexts ALTER COLUMN id SET DEFAULT nextval('appointment_group_contexts_id_seq'::regclass);


--
-- Name: appointment_group_sub_contexts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY appointment_group_sub_contexts ALTER COLUMN id SET DEFAULT nextval('appointment_group_sub_contexts_id_seq'::regclass);


--
-- Name: appointment_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY appointment_groups ALTER COLUMN id SET DEFAULT nextval('appointment_groups_id_seq'::regclass);


--
-- Name: assessment_question_bank_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY assessment_question_bank_users ALTER COLUMN id SET DEFAULT nextval('assessment_question_bank_users_id_seq'::regclass);


--
-- Name: assessment_question_banks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY assessment_question_banks ALTER COLUMN id SET DEFAULT nextval('assessment_question_banks_id_seq'::regclass);


--
-- Name: assessment_questions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY assessment_questions ALTER COLUMN id SET DEFAULT nextval('assessment_questions_id_seq'::regclass);


--
-- Name: assessment_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY assessment_requests ALTER COLUMN id SET DEFAULT nextval('assessment_requests_id_seq'::regclass);


--
-- Name: asset_user_accesses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY asset_user_accesses ALTER COLUMN id SET DEFAULT nextval('asset_user_accesses_id_seq'::regclass);


--
-- Name: assignment_configuration_tool_lookups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY assignment_configuration_tool_lookups ALTER COLUMN id SET DEFAULT nextval('assignment_configuration_tool_lookups_id_seq'::regclass);


--
-- Name: assignment_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY assignment_groups ALTER COLUMN id SET DEFAULT nextval('assignment_groups_id_seq'::regclass);


--
-- Name: assignment_override_students id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY assignment_override_students ALTER COLUMN id SET DEFAULT nextval('assignment_override_students_id_seq'::regclass);


--
-- Name: assignment_overrides id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY assignment_overrides ALTER COLUMN id SET DEFAULT nextval('assignment_overrides_id_seq'::regclass);


--
-- Name: assignments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY assignments ALTER COLUMN id SET DEFAULT nextval('assignments_id_seq'::regclass);


--
-- Name: attachment_associations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY attachment_associations ALTER COLUMN id SET DEFAULT nextval('attachment_associations_id_seq'::regclass);


--
-- Name: attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY attachments ALTER COLUMN id SET DEFAULT nextval('attachments_id_seq'::regclass);


--
-- Name: bookmarks_bookmarks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY bookmarks_bookmarks ALTER COLUMN id SET DEFAULT nextval('bookmarks_bookmarks_id_seq'::regclass);


--
-- Name: calendar_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY calendar_events ALTER COLUMN id SET DEFAULT nextval('calendar_events_id_seq'::regclass);


--
-- Name: canvadocs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY canvadocs ALTER COLUMN id SET DEFAULT nextval('canvadocs_id_seq'::regclass);


--
-- Name: canvadocs_submissions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY canvadocs_submissions ALTER COLUMN id SET DEFAULT nextval('canvadocs_submissions_id_seq'::regclass);


--
-- Name: cloned_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY cloned_items ALTER COLUMN id SET DEFAULT nextval('cloned_items_id_seq'::regclass);


--
-- Name: collaborations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY collaborations ALTER COLUMN id SET DEFAULT nextval('collaborations_id_seq'::regclass);


--
-- Name: collaborators id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY collaborators ALTER COLUMN id SET DEFAULT nextval('collaborators_id_seq'::regclass);


--
-- Name: communication_channels id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY communication_channels ALTER COLUMN id SET DEFAULT nextval('communication_channels_id_seq'::regclass);


--
-- Name: content_exports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY content_exports ALTER COLUMN id SET DEFAULT nextval('content_exports_id_seq'::regclass);


--
-- Name: content_migrations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY content_migrations ALTER COLUMN id SET DEFAULT nextval('content_migrations_id_seq'::regclass);


--
-- Name: content_participation_counts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY content_participation_counts ALTER COLUMN id SET DEFAULT nextval('content_participation_counts_id_seq'::regclass);


--
-- Name: content_participations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY content_participations ALTER COLUMN id SET DEFAULT nextval('content_participations_id_seq'::regclass);


--
-- Name: content_tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY content_tags ALTER COLUMN id SET DEFAULT nextval('content_tags_id_seq'::regclass);


--
-- Name: context_external_tool_assignment_lookups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY context_external_tool_assignment_lookups ALTER COLUMN id SET DEFAULT nextval('context_external_tool_assignment_lookups_id_seq'::regclass);


--
-- Name: context_external_tool_placements id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY context_external_tool_placements ALTER COLUMN id SET DEFAULT nextval('context_external_tool_placements_id_seq'::regclass);


--
-- Name: context_external_tools id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY context_external_tools ALTER COLUMN id SET DEFAULT nextval('context_external_tools_id_seq'::regclass);


--
-- Name: context_module_progressions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY context_module_progressions ALTER COLUMN id SET DEFAULT nextval('context_module_progressions_id_seq'::regclass);


--
-- Name: context_modules id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY context_modules ALTER COLUMN id SET DEFAULT nextval('context_modules_id_seq'::regclass);


--
-- Name: conversation_batches id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY conversation_batches ALTER COLUMN id SET DEFAULT nextval('conversation_batches_id_seq'::regclass);


--
-- Name: conversation_message_participants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY conversation_message_participants ALTER COLUMN id SET DEFAULT nextval('conversation_message_participants_id_seq'::regclass);


--
-- Name: conversation_messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY conversation_messages ALTER COLUMN id SET DEFAULT nextval('conversation_messages_id_seq'::regclass);


--
-- Name: conversation_participants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY conversation_participants ALTER COLUMN id SET DEFAULT nextval('conversation_participants_id_seq'::regclass);


--
-- Name: conversations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY conversations ALTER COLUMN id SET DEFAULT nextval('conversations_id_seq'::regclass);


--
-- Name: course_account_associations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY course_account_associations ALTER COLUMN id SET DEFAULT nextval('course_account_associations_id_seq'::regclass);


--
-- Name: course_sections id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY course_sections ALTER COLUMN id SET DEFAULT nextval('course_sections_id_seq'::regclass);


--
-- Name: courses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY courses ALTER COLUMN id SET DEFAULT nextval('courses_id_seq'::regclass);


--
-- Name: crocodoc_documents id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY crocodoc_documents ALTER COLUMN id SET DEFAULT nextval('crocodoc_documents_id_seq'::regclass);


--
-- Name: custom_data id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY custom_data ALTER COLUMN id SET DEFAULT nextval('custom_data_id_seq'::regclass);


--
-- Name: custom_gradebook_column_data id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY custom_gradebook_column_data ALTER COLUMN id SET DEFAULT nextval('custom_gradebook_column_data_id_seq'::regclass);


--
-- Name: custom_gradebook_columns id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY custom_gradebook_columns ALTER COLUMN id SET DEFAULT nextval('custom_gradebook_columns_id_seq'::regclass);


--
-- Name: delayed_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY delayed_jobs ALTER COLUMN id SET DEFAULT nextval('delayed_jobs_id_seq'::regclass);


--
-- Name: delayed_messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY delayed_messages ALTER COLUMN id SET DEFAULT nextval('delayed_messages_id_seq'::regclass);


--
-- Name: delayed_notifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY delayed_notifications ALTER COLUMN id SET DEFAULT nextval('delayed_notifications_id_seq'::regclass);


--
-- Name: developer_keys id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY developer_keys ALTER COLUMN id SET DEFAULT nextval('developer_keys_id_seq'::regclass);


--
-- Name: discussion_entries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY discussion_entries ALTER COLUMN id SET DEFAULT nextval('discussion_entries_id_seq'::regclass);


--
-- Name: discussion_entry_participants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY discussion_entry_participants ALTER COLUMN id SET DEFAULT nextval('discussion_entry_participants_id_seq'::regclass);


--
-- Name: discussion_topic_participants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY discussion_topic_participants ALTER COLUMN id SET DEFAULT nextval('discussion_topic_participants_id_seq'::regclass);


--
-- Name: discussion_topics id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY discussion_topics ALTER COLUMN id SET DEFAULT nextval('discussion_topics_id_seq'::regclass);


--
-- Name: enrollment_dates_overrides id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY enrollment_dates_overrides ALTER COLUMN id SET DEFAULT nextval('enrollment_dates_overrides_id_seq'::regclass);


--
-- Name: enrollment_terms id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY enrollment_terms ALTER COLUMN id SET DEFAULT nextval('enrollment_terms_id_seq'::regclass);


--
-- Name: enrollments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY enrollments ALTER COLUMN id SET DEFAULT nextval('enrollments_id_seq'::regclass);


--
-- Name: eportfolio_categories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY eportfolio_categories ALTER COLUMN id SET DEFAULT nextval('eportfolio_categories_id_seq'::regclass);


--
-- Name: eportfolio_entries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY eportfolio_entries ALTER COLUMN id SET DEFAULT nextval('eportfolio_entries_id_seq'::regclass);


--
-- Name: eportfolios id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY eportfolios ALTER COLUMN id SET DEFAULT nextval('eportfolios_id_seq'::regclass);


--
-- Name: epub_exports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY epub_exports ALTER COLUMN id SET DEFAULT nextval('epub_exports_id_seq'::regclass);


--
-- Name: error_reports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY error_reports ALTER COLUMN id SET DEFAULT nextval('error_reports_id_seq'::regclass);


--
-- Name: event_stream_failures id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY event_stream_failures ALTER COLUMN id SET DEFAULT nextval('event_stream_failures_id_seq'::regclass);


--
-- Name: external_feed_entries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY external_feed_entries ALTER COLUMN id SET DEFAULT nextval('external_feed_entries_id_seq'::regclass);


--
-- Name: external_feeds id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY external_feeds ALTER COLUMN id SET DEFAULT nextval('external_feeds_id_seq'::regclass);


--
-- Name: external_integration_keys id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY external_integration_keys ALTER COLUMN id SET DEFAULT nextval('external_integration_keys_id_seq'::regclass);


--
-- Name: failed_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY failed_jobs ALTER COLUMN id SET DEFAULT nextval('failed_jobs_id_seq'::regclass);


--
-- Name: favorites id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY favorites ALTER COLUMN id SET DEFAULT nextval('favorites_id_seq'::regclass);


--
-- Name: feature_flags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY feature_flags ALTER COLUMN id SET DEFAULT nextval('feature_flags_id_seq'::regclass);


--
-- Name: folders id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY folders ALTER COLUMN id SET DEFAULT nextval('folders_id_seq'::regclass);


--
-- Name: gradebook_csvs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY gradebook_csvs ALTER COLUMN id SET DEFAULT nextval('gradebook_csvs_id_seq'::regclass);


--
-- Name: gradebook_uploads id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY gradebook_uploads ALTER COLUMN id SET DEFAULT nextval('gradebook_uploads_id_seq'::regclass);


--
-- Name: grading_period_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY grading_period_groups ALTER COLUMN id SET DEFAULT nextval('grading_period_groups_id_seq'::regclass);


--
-- Name: grading_periods id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY grading_periods ALTER COLUMN id SET DEFAULT nextval('grading_periods_id_seq'::regclass);


--
-- Name: grading_standards id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY grading_standards ALTER COLUMN id SET DEFAULT nextval('grading_standards_id_seq'::regclass);


--
-- Name: group_categories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY group_categories ALTER COLUMN id SET DEFAULT nextval('group_categories_id_seq'::regclass);


--
-- Name: group_memberships id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY group_memberships ALTER COLUMN id SET DEFAULT nextval('group_memberships_id_seq'::regclass);


--
-- Name: groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY groups ALTER COLUMN id SET DEFAULT nextval('groups_id_seq'::regclass);


--
-- Name: ignores id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY ignores ALTER COLUMN id SET DEFAULT nextval('ignores_id_seq'::regclass);


--
-- Name: late_policies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY late_policies ALTER COLUMN id SET DEFAULT nextval('late_policies_id_seq'::regclass);


--
-- Name: learning_outcome_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY learning_outcome_groups ALTER COLUMN id SET DEFAULT nextval('learning_outcome_groups_id_seq'::regclass);


--
-- Name: learning_outcome_question_results id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY learning_outcome_question_results ALTER COLUMN id SET DEFAULT nextval('learning_outcome_question_results_id_seq'::regclass);


--
-- Name: learning_outcome_results id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY learning_outcome_results ALTER COLUMN id SET DEFAULT nextval('learning_outcome_results_id_seq'::regclass);


--
-- Name: learning_outcomes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY learning_outcomes ALTER COLUMN id SET DEFAULT nextval('learning_outcomes_id_seq'::regclass);


--
-- Name: live_assessments_assessments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY live_assessments_assessments ALTER COLUMN id SET DEFAULT nextval('live_assessments_assessments_id_seq'::regclass);


--
-- Name: live_assessments_results id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY live_assessments_results ALTER COLUMN id SET DEFAULT nextval('live_assessments_results_id_seq'::regclass);


--
-- Name: live_assessments_submissions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY live_assessments_submissions ALTER COLUMN id SET DEFAULT nextval('live_assessments_submissions_id_seq'::regclass);


--
-- Name: lti_message_handlers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY lti_message_handlers ALTER COLUMN id SET DEFAULT nextval('lti_message_handlers_id_seq'::regclass);


--
-- Name: lti_product_families id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY lti_product_families ALTER COLUMN id SET DEFAULT nextval('lti_product_families_id_seq'::regclass);


--
-- Name: lti_resource_handlers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY lti_resource_handlers ALTER COLUMN id SET DEFAULT nextval('lti_resource_handlers_id_seq'::regclass);


--
-- Name: lti_resource_placements id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY lti_resource_placements ALTER COLUMN id SET DEFAULT nextval('lti_resource_placements_id_seq'::regclass);


--
-- Name: lti_tool_consumer_profiles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY lti_tool_consumer_profiles ALTER COLUMN id SET DEFAULT nextval('lti_tool_consumer_profiles_id_seq'::regclass);


--
-- Name: lti_tool_proxies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY lti_tool_proxies ALTER COLUMN id SET DEFAULT nextval('lti_tool_proxies_id_seq'::regclass);


--
-- Name: lti_tool_proxy_bindings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY lti_tool_proxy_bindings ALTER COLUMN id SET DEFAULT nextval('lti_tool_proxy_bindings_id_seq'::regclass);


--
-- Name: lti_tool_settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY lti_tool_settings ALTER COLUMN id SET DEFAULT nextval('lti_tool_settings_id_seq'::regclass);


--
-- Name: master_courses_child_content_tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY master_courses_child_content_tags ALTER COLUMN id SET DEFAULT nextval('master_courses_child_content_tags_id_seq'::regclass);


--
-- Name: master_courses_child_subscriptions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY master_courses_child_subscriptions ALTER COLUMN id SET DEFAULT nextval('master_courses_child_subscriptions_id_seq'::regclass);


--
-- Name: master_courses_master_content_tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY master_courses_master_content_tags ALTER COLUMN id SET DEFAULT nextval('master_courses_master_content_tags_id_seq'::regclass);


--
-- Name: master_courses_master_migrations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY master_courses_master_migrations ALTER COLUMN id SET DEFAULT nextval('master_courses_master_migrations_id_seq'::regclass);


--
-- Name: master_courses_master_templates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY master_courses_master_templates ALTER COLUMN id SET DEFAULT nextval('master_courses_master_templates_id_seq'::regclass);


--
-- Name: master_courses_migration_results id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY master_courses_migration_results ALTER COLUMN id SET DEFAULT nextval('master_courses_migration_results_id_seq'::regclass);


--
-- Name: media_objects id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY media_objects ALTER COLUMN id SET DEFAULT nextval('media_objects_id_seq'::regclass);


--
-- Name: media_tracks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY media_tracks ALTER COLUMN id SET DEFAULT nextval('media_tracks_id_seq'::regclass);


--
-- Name: messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY messages ALTER COLUMN id SET DEFAULT nextval('messages_id_seq'::regclass);


--
-- Name: migration_issues id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY migration_issues ALTER COLUMN id SET DEFAULT nextval('migration_issues_id_seq'::regclass);


--
-- Name: moderated_grading_provisional_grades id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY moderated_grading_provisional_grades ALTER COLUMN id SET DEFAULT nextval('moderated_grading_provisional_grades_id_seq'::regclass);


--
-- Name: moderated_grading_selections id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY moderated_grading_selections ALTER COLUMN id SET DEFAULT nextval('moderated_grading_selections_id_seq'::regclass);


--
-- Name: notification_endpoints id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY notification_endpoints ALTER COLUMN id SET DEFAULT nextval('notification_endpoints_id_seq'::regclass);


--
-- Name: notification_policies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY notification_policies ALTER COLUMN id SET DEFAULT nextval('notification_policies_id_seq'::regclass);


--
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY notifications ALTER COLUMN id SET DEFAULT nextval('notifications_id_seq'::regclass);


--
-- Name: oauth_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY oauth_requests ALTER COLUMN id SET DEFAULT nextval('oauth_requests_id_seq'::regclass);


--
-- Name: one_time_passwords id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY one_time_passwords ALTER COLUMN id SET DEFAULT nextval('one_time_passwords_id_seq'::regclass);


--
-- Name: originality_reports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY originality_reports ALTER COLUMN id SET DEFAULT nextval('originality_reports_id_seq'::regclass);


--
-- Name: page_comments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY page_comments ALTER COLUMN id SET DEFAULT nextval('page_comments_id_seq'::regclass);


--
-- Name: page_views_rollups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY page_views_rollups ALTER COLUMN id SET DEFAULT nextval('page_views_rollups_id_seq'::regclass);


--
-- Name: planner_notes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY planner_notes ALTER COLUMN id SET DEFAULT nextval('planner_notes_id_seq'::regclass);


--
-- Name: planner_overrides id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY planner_overrides ALTER COLUMN id SET DEFAULT nextval('planner_overrides_id_seq'::regclass);


--
-- Name: plugin_settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY plugin_settings ALTER COLUMN id SET DEFAULT nextval('plugin_settings_id_seq'::regclass);


--
-- Name: polling_poll_choices id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY polling_poll_choices ALTER COLUMN id SET DEFAULT nextval('polling_poll_choices_id_seq'::regclass);


--
-- Name: polling_poll_sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY polling_poll_sessions ALTER COLUMN id SET DEFAULT nextval('polling_poll_sessions_id_seq'::regclass);


--
-- Name: polling_poll_submissions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY polling_poll_submissions ALTER COLUMN id SET DEFAULT nextval('polling_poll_submissions_id_seq'::regclass);


--
-- Name: polling_polls id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY polling_polls ALTER COLUMN id SET DEFAULT nextval('polling_polls_id_seq'::regclass);


--
-- Name: profiles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY profiles ALTER COLUMN id SET DEFAULT nextval('profiles_id_seq'::regclass);


--
-- Name: progresses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY progresses ALTER COLUMN id SET DEFAULT nextval('progresses_id_seq'::regclass);


--
-- Name: pseudonyms id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY pseudonyms ALTER COLUMN id SET DEFAULT nextval('pseudonyms_id_seq'::regclass);


--
-- Name: purgatories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY purgatories ALTER COLUMN id SET DEFAULT nextval('purgatories_id_seq'::regclass);


--
-- Name: quiz_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY quiz_groups ALTER COLUMN id SET DEFAULT nextval('quiz_groups_id_seq'::regclass);


--
-- Name: quiz_question_regrades id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY quiz_question_regrades ALTER COLUMN id SET DEFAULT nextval('quiz_question_regrades_id_seq'::regclass);


--
-- Name: quiz_questions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY quiz_questions ALTER COLUMN id SET DEFAULT nextval('quiz_questions_id_seq'::regclass);


--
-- Name: quiz_regrade_runs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY quiz_regrade_runs ALTER COLUMN id SET DEFAULT nextval('quiz_regrade_runs_id_seq'::regclass);


--
-- Name: quiz_regrades id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY quiz_regrades ALTER COLUMN id SET DEFAULT nextval('quiz_regrades_id_seq'::regclass);


--
-- Name: quiz_statistics id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY quiz_statistics ALTER COLUMN id SET DEFAULT nextval('quiz_statistics_id_seq'::regclass);


--
-- Name: quiz_submission_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY quiz_submission_events ALTER COLUMN id SET DEFAULT nextval('quiz_submission_events_id_seq'::regclass);


--
-- Name: quiz_submission_snapshots id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY quiz_submission_snapshots ALTER COLUMN id SET DEFAULT nextval('quiz_submission_snapshots_id_seq'::regclass);


--
-- Name: quiz_submissions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY quiz_submissions ALTER COLUMN id SET DEFAULT nextval('quiz_submissions_id_seq'::regclass);


--
-- Name: quizzes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY quizzes ALTER COLUMN id SET DEFAULT nextval('quizzes_id_seq'::regclass);


--
-- Name: report_snapshots id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY report_snapshots ALTER COLUMN id SET DEFAULT nextval('report_snapshots_id_seq'::regclass);


--
-- Name: role_overrides id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY role_overrides ALTER COLUMN id SET DEFAULT nextval('role_overrides_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY roles ALTER COLUMN id SET DEFAULT nextval('roles_id_seq'::regclass);


--
-- Name: rubric_assessments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY rubric_assessments ALTER COLUMN id SET DEFAULT nextval('rubric_assessments_id_seq'::regclass);


--
-- Name: rubric_associations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY rubric_associations ALTER COLUMN id SET DEFAULT nextval('rubric_associations_id_seq'::regclass);


--
-- Name: rubrics id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY rubrics ALTER COLUMN id SET DEFAULT nextval('rubrics_id_seq'::regclass);


--
-- Name: scores id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY scores ALTER COLUMN id SET DEFAULT nextval('scores_id_seq'::regclass);


--
-- Name: scribd_mime_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY scribd_mime_types ALTER COLUMN id SET DEFAULT nextval('scribd_mime_types_id_seq'::regclass);


--
-- Name: session_persistence_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY session_persistence_tokens ALTER COLUMN id SET DEFAULT nextval('session_persistence_tokens_id_seq'::regclass);


--
-- Name: sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sessions ALTER COLUMN id SET DEFAULT nextval('sessions_id_seq'::regclass);


--
-- Name: settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY settings ALTER COLUMN id SET DEFAULT nextval('settings_id_seq'::regclass);


--
-- Name: shared_brand_configs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY shared_brand_configs ALTER COLUMN id SET DEFAULT nextval('shared_brand_configs_id_seq'::regclass);


--
-- Name: sis_batch_error_files id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sis_batch_error_files ALTER COLUMN id SET DEFAULT nextval('sis_batch_error_files_id_seq'::regclass);


--
-- Name: sis_batches id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sis_batches ALTER COLUMN id SET DEFAULT nextval('sis_batches_id_seq'::regclass);


--
-- Name: sis_post_grades_statuses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sis_post_grades_statuses ALTER COLUMN id SET DEFAULT nextval('sis_post_grades_statuses_id_seq'::regclass);


--
-- Name: stream_item_instances id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY stream_item_instances ALTER COLUMN id SET DEFAULT nextval('stream_item_instances_id_seq'::regclass);


--
-- Name: stream_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY stream_items ALTER COLUMN id SET DEFAULT nextval('stream_items_id_seq'::regclass);


--
-- Name: submission_comments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY submission_comments ALTER COLUMN id SET DEFAULT nextval('submission_comments_id_seq'::regclass);


--
-- Name: submission_versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY submission_versions ALTER COLUMN id SET DEFAULT nextval('submission_versions_id_seq'::regclass);


--
-- Name: submissions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY submissions ALTER COLUMN id SET DEFAULT nextval('submissions_id_seq'::regclass);


--
-- Name: switchman_shards id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY switchman_shards ALTER COLUMN id SET DEFAULT nextval('switchman_shards_id_seq'::regclass);


--
-- Name: thumbnails id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY thumbnails ALTER COLUMN id SET DEFAULT nextval('thumbnails_id_seq'::regclass);


--
-- Name: usage_rights id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY usage_rights ALTER COLUMN id SET DEFAULT nextval('usage_rights_id_seq'::regclass);


--
-- Name: user_account_associations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_account_associations ALTER COLUMN id SET DEFAULT nextval('user_account_associations_id_seq'::regclass);


--
-- Name: user_merge_data id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_merge_data ALTER COLUMN id SET DEFAULT nextval('user_merge_data_id_seq'::regclass);


--
-- Name: user_merge_data_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_merge_data_records ALTER COLUMN id SET DEFAULT nextval('user_merge_data_records_id_seq'::regclass);


--
-- Name: user_notes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_notes ALTER COLUMN id SET DEFAULT nextval('user_notes_id_seq'::regclass);


--
-- Name: user_observers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_observers ALTER COLUMN id SET DEFAULT nextval('user_observers_id_seq'::regclass);


--
-- Name: user_profile_links id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_profile_links ALTER COLUMN id SET DEFAULT nextval('user_profile_links_id_seq'::regclass);


--
-- Name: user_profiles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_profiles ALTER COLUMN id SET DEFAULT nextval('user_profiles_id_seq'::regclass);


--
-- Name: user_services id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_services ALTER COLUMN id SET DEFAULT nextval('user_services_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY versions ALTER COLUMN id SET DEFAULT nextval('versions_id_seq'::regclass);


--
-- Name: web_conference_participants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY web_conference_participants ALTER COLUMN id SET DEFAULT nextval('web_conference_participants_id_seq'::regclass);


--
-- Name: web_conferences id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY web_conferences ALTER COLUMN id SET DEFAULT nextval('web_conferences_id_seq'::regclass);


--
-- Name: wiki_pages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY wiki_pages ALTER COLUMN id SET DEFAULT nextval('wiki_pages_id_seq'::regclass);


--
-- Name: wikis id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY wikis ALTER COLUMN id SET DEFAULT nextval('wikis_id_seq'::regclass);


--
-- Name: abstract_courses abstract_courses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY abstract_courses
    ADD CONSTRAINT abstract_courses_pkey PRIMARY KEY (id);


--
-- Name: access_tokens access_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY access_tokens
    ADD CONSTRAINT access_tokens_pkey PRIMARY KEY (id);


--
-- Name: account_authorization_configs account_authorization_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY account_authorization_configs
    ADD CONSTRAINT account_authorization_configs_pkey PRIMARY KEY (id);


--
-- Name: account_notification_roles account_notification_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY account_notification_roles
    ADD CONSTRAINT account_notification_roles_pkey PRIMARY KEY (id);


--
-- Name: account_notifications account_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY account_notifications
    ADD CONSTRAINT account_notifications_pkey PRIMARY KEY (id);


--
-- Name: account_reports account_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY account_reports
    ADD CONSTRAINT account_reports_pkey PRIMARY KEY (id);


--
-- Name: account_users account_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY account_users
    ADD CONSTRAINT account_users_pkey PRIMARY KEY (id);


--
-- Name: accounts accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);


--
-- Name: alert_criteria alert_criteria_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY alert_criteria
    ADD CONSTRAINT alert_criteria_pkey PRIMARY KEY (id);


--
-- Name: alerts alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY alerts
    ADD CONSTRAINT alerts_pkey PRIMARY KEY (id);


--
-- Name: appointment_group_contexts appointment_group_contexts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY appointment_group_contexts
    ADD CONSTRAINT appointment_group_contexts_pkey PRIMARY KEY (id);


--
-- Name: appointment_group_sub_contexts appointment_group_sub_contexts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY appointment_group_sub_contexts
    ADD CONSTRAINT appointment_group_sub_contexts_pkey PRIMARY KEY (id);


--
-- Name: appointment_groups appointment_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY appointment_groups
    ADD CONSTRAINT appointment_groups_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: assessment_question_bank_users assessment_question_bank_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY assessment_question_bank_users
    ADD CONSTRAINT assessment_question_bank_users_pkey PRIMARY KEY (id);


--
-- Name: assessment_question_banks assessment_question_banks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY assessment_question_banks
    ADD CONSTRAINT assessment_question_banks_pkey PRIMARY KEY (id);


--
-- Name: assessment_questions assessment_questions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY assessment_questions
    ADD CONSTRAINT assessment_questions_pkey PRIMARY KEY (id);


--
-- Name: assessment_requests assessment_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY assessment_requests
    ADD CONSTRAINT assessment_requests_pkey PRIMARY KEY (id);


--
-- Name: asset_user_accesses asset_user_accesses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY asset_user_accesses
    ADD CONSTRAINT asset_user_accesses_pkey PRIMARY KEY (id);


--
-- Name: assignment_configuration_tool_lookups assignment_configuration_tool_lookups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY assignment_configuration_tool_lookups
    ADD CONSTRAINT assignment_configuration_tool_lookups_pkey PRIMARY KEY (id);


--
-- Name: assignment_groups assignment_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY assignment_groups
    ADD CONSTRAINT assignment_groups_pkey PRIMARY KEY (id);


--
-- Name: assignment_override_students assignment_override_students_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY assignment_override_students
    ADD CONSTRAINT assignment_override_students_pkey PRIMARY KEY (id);


--
-- Name: assignment_overrides assignment_overrides_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY assignment_overrides
    ADD CONSTRAINT assignment_overrides_pkey PRIMARY KEY (id);


--
-- Name: assignments assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY assignments
    ADD CONSTRAINT assignments_pkey PRIMARY KEY (id);


--
-- Name: attachment_associations attachment_associations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY attachment_associations
    ADD CONSTRAINT attachment_associations_pkey PRIMARY KEY (id);


--
-- Name: attachments attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY attachments
    ADD CONSTRAINT attachments_pkey PRIMARY KEY (id);


--
-- Name: bookmarks_bookmarks bookmarks_bookmarks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bookmarks_bookmarks
    ADD CONSTRAINT bookmarks_bookmarks_pkey PRIMARY KEY (id);


--
-- Name: brand_configs brand_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY brand_configs
    ADD CONSTRAINT brand_configs_pkey PRIMARY KEY (md5);


--
-- Name: cached_grade_distributions cached_grade_distributions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cached_grade_distributions
    ADD CONSTRAINT cached_grade_distributions_pkey PRIMARY KEY (course_id);


--
-- Name: calendar_events calendar_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY calendar_events
    ADD CONSTRAINT calendar_events_pkey PRIMARY KEY (id);


--
-- Name: canvadocs canvadocs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY canvadocs
    ADD CONSTRAINT canvadocs_pkey PRIMARY KEY (id);


--
-- Name: canvadocs_submissions canvadocs_submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY canvadocs_submissions
    ADD CONSTRAINT canvadocs_submissions_pkey PRIMARY KEY (id);


--
-- Name: cloned_items cloned_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cloned_items
    ADD CONSTRAINT cloned_items_pkey PRIMARY KEY (id);


--
-- Name: collaborations collaborations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY collaborations
    ADD CONSTRAINT collaborations_pkey PRIMARY KEY (id);


--
-- Name: collaborators collaborators_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY collaborators
    ADD CONSTRAINT collaborators_pkey PRIMARY KEY (id);


--
-- Name: communication_channels communication_channels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY communication_channels
    ADD CONSTRAINT communication_channels_pkey PRIMARY KEY (id);


--
-- Name: content_exports content_exports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY content_exports
    ADD CONSTRAINT content_exports_pkey PRIMARY KEY (id);


--
-- Name: content_migrations content_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY content_migrations
    ADD CONSTRAINT content_migrations_pkey PRIMARY KEY (id);


--
-- Name: content_participation_counts content_participation_counts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY content_participation_counts
    ADD CONSTRAINT content_participation_counts_pkey PRIMARY KEY (id);


--
-- Name: content_participations content_participations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY content_participations
    ADD CONSTRAINT content_participations_pkey PRIMARY KEY (id);


--
-- Name: content_tags content_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY content_tags
    ADD CONSTRAINT content_tags_pkey PRIMARY KEY (id);


--
-- Name: context_external_tool_assignment_lookups context_external_tool_assignment_lookups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY context_external_tool_assignment_lookups
    ADD CONSTRAINT context_external_tool_assignment_lookups_pkey PRIMARY KEY (id);


--
-- Name: context_external_tool_placements context_external_tool_placements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY context_external_tool_placements
    ADD CONSTRAINT context_external_tool_placements_pkey PRIMARY KEY (id);


--
-- Name: context_external_tools context_external_tools_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY context_external_tools
    ADD CONSTRAINT context_external_tools_pkey PRIMARY KEY (id);


--
-- Name: context_module_progressions context_module_progressions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY context_module_progressions
    ADD CONSTRAINT context_module_progressions_pkey PRIMARY KEY (id);


--
-- Name: context_modules context_modules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY context_modules
    ADD CONSTRAINT context_modules_pkey PRIMARY KEY (id);


--
-- Name: conversation_batches conversation_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY conversation_batches
    ADD CONSTRAINT conversation_batches_pkey PRIMARY KEY (id);


--
-- Name: conversation_message_participants conversation_message_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY conversation_message_participants
    ADD CONSTRAINT conversation_message_participants_pkey PRIMARY KEY (id);


--
-- Name: conversation_messages conversation_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY conversation_messages
    ADD CONSTRAINT conversation_messages_pkey PRIMARY KEY (id);


--
-- Name: conversation_participants conversation_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY conversation_participants
    ADD CONSTRAINT conversation_participants_pkey PRIMARY KEY (id);


--
-- Name: conversations conversations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY conversations
    ADD CONSTRAINT conversations_pkey PRIMARY KEY (id);


--
-- Name: course_account_associations course_account_associations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY course_account_associations
    ADD CONSTRAINT course_account_associations_pkey PRIMARY KEY (id);


--
-- Name: course_sections course_sections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY course_sections
    ADD CONSTRAINT course_sections_pkey PRIMARY KEY (id);


--
-- Name: courses courses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY courses
    ADD CONSTRAINT courses_pkey PRIMARY KEY (id);


--
-- Name: crocodoc_documents crocodoc_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY crocodoc_documents
    ADD CONSTRAINT crocodoc_documents_pkey PRIMARY KEY (id);


--
-- Name: custom_data custom_data_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY custom_data
    ADD CONSTRAINT custom_data_pkey PRIMARY KEY (id);


--
-- Name: custom_gradebook_column_data custom_gradebook_column_data_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY custom_gradebook_column_data
    ADD CONSTRAINT custom_gradebook_column_data_pkey PRIMARY KEY (id);


--
-- Name: custom_gradebook_columns custom_gradebook_columns_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY custom_gradebook_columns
    ADD CONSTRAINT custom_gradebook_columns_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs delayed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY delayed_jobs
    ADD CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id);


--
-- Name: delayed_messages delayed_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY delayed_messages
    ADD CONSTRAINT delayed_messages_pkey PRIMARY KEY (id);


--
-- Name: delayed_notifications delayed_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY delayed_notifications
    ADD CONSTRAINT delayed_notifications_pkey PRIMARY KEY (id);


--
-- Name: developer_keys developer_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY developer_keys
    ADD CONSTRAINT developer_keys_pkey PRIMARY KEY (id);


--
-- Name: discussion_entries discussion_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY discussion_entries
    ADD CONSTRAINT discussion_entries_pkey PRIMARY KEY (id);


--
-- Name: discussion_entry_participants discussion_entry_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY discussion_entry_participants
    ADD CONSTRAINT discussion_entry_participants_pkey PRIMARY KEY (id);


--
-- Name: discussion_topic_materialized_views discussion_topic_materialized_views_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY discussion_topic_materialized_views
    ADD CONSTRAINT discussion_topic_materialized_views_pkey PRIMARY KEY (discussion_topic_id);


--
-- Name: discussion_topic_participants discussion_topic_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY discussion_topic_participants
    ADD CONSTRAINT discussion_topic_participants_pkey PRIMARY KEY (id);


--
-- Name: discussion_topics discussion_topics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY discussion_topics
    ADD CONSTRAINT discussion_topics_pkey PRIMARY KEY (id);


--
-- Name: enrollment_dates_overrides enrollment_dates_overrides_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY enrollment_dates_overrides
    ADD CONSTRAINT enrollment_dates_overrides_pkey PRIMARY KEY (id);


--
-- Name: enrollment_states enrollment_states_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY enrollment_states
    ADD CONSTRAINT enrollment_states_pkey PRIMARY KEY (enrollment_id);


--
-- Name: enrollment_terms enrollment_terms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY enrollment_terms
    ADD CONSTRAINT enrollment_terms_pkey PRIMARY KEY (id);


--
-- Name: enrollments enrollments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY enrollments
    ADD CONSTRAINT enrollments_pkey PRIMARY KEY (id);


--
-- Name: eportfolio_categories eportfolio_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY eportfolio_categories
    ADD CONSTRAINT eportfolio_categories_pkey PRIMARY KEY (id);


--
-- Name: eportfolio_entries eportfolio_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY eportfolio_entries
    ADD CONSTRAINT eportfolio_entries_pkey PRIMARY KEY (id);


--
-- Name: eportfolios eportfolios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY eportfolios
    ADD CONSTRAINT eportfolios_pkey PRIMARY KEY (id);


--
-- Name: epub_exports epub_exports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY epub_exports
    ADD CONSTRAINT epub_exports_pkey PRIMARY KEY (id);


--
-- Name: error_reports error_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY error_reports
    ADD CONSTRAINT error_reports_pkey PRIMARY KEY (id);


--
-- Name: event_stream_failures event_stream_failures_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY event_stream_failures
    ADD CONSTRAINT event_stream_failures_pkey PRIMARY KEY (id);


--
-- Name: external_feed_entries external_feed_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY external_feed_entries
    ADD CONSTRAINT external_feed_entries_pkey PRIMARY KEY (id);


--
-- Name: external_feeds external_feeds_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY external_feeds
    ADD CONSTRAINT external_feeds_pkey PRIMARY KEY (id);


--
-- Name: external_integration_keys external_integration_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY external_integration_keys
    ADD CONSTRAINT external_integration_keys_pkey PRIMARY KEY (id);


--
-- Name: failed_jobs failed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY failed_jobs
    ADD CONSTRAINT failed_jobs_pkey PRIMARY KEY (id);


--
-- Name: favorites favorites_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY favorites
    ADD CONSTRAINT favorites_pkey PRIMARY KEY (id);


--
-- Name: feature_flags feature_flags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY feature_flags
    ADD CONSTRAINT feature_flags_pkey PRIMARY KEY (id);


--
-- Name: folders folders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY folders
    ADD CONSTRAINT folders_pkey PRIMARY KEY (id);


--
-- Name: gradebook_csvs gradebook_csvs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gradebook_csvs
    ADD CONSTRAINT gradebook_csvs_pkey PRIMARY KEY (id);


--
-- Name: gradebook_uploads gradebook_uploads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gradebook_uploads
    ADD CONSTRAINT gradebook_uploads_pkey PRIMARY KEY (id);


--
-- Name: grading_period_groups grading_period_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY grading_period_groups
    ADD CONSTRAINT grading_period_groups_pkey PRIMARY KEY (id);


--
-- Name: grading_periods grading_periods_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY grading_periods
    ADD CONSTRAINT grading_periods_pkey PRIMARY KEY (id);


--
-- Name: grading_standards grading_standards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY grading_standards
    ADD CONSTRAINT grading_standards_pkey PRIMARY KEY (id);


--
-- Name: group_categories group_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY group_categories
    ADD CONSTRAINT group_categories_pkey PRIMARY KEY (id);


--
-- Name: group_memberships group_memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY group_memberships
    ADD CONSTRAINT group_memberships_pkey PRIMARY KEY (id);


--
-- Name: groups groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (id);


--
-- Name: ignores ignores_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ignores
    ADD CONSTRAINT ignores_pkey PRIMARY KEY (id);


--
-- Name: late_policies late_policies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY late_policies
    ADD CONSTRAINT late_policies_pkey PRIMARY KEY (id);


--
-- Name: learning_outcome_groups learning_outcome_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY learning_outcome_groups
    ADD CONSTRAINT learning_outcome_groups_pkey PRIMARY KEY (id);


--
-- Name: learning_outcome_question_results learning_outcome_question_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY learning_outcome_question_results
    ADD CONSTRAINT learning_outcome_question_results_pkey PRIMARY KEY (id);


--
-- Name: learning_outcome_results learning_outcome_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY learning_outcome_results
    ADD CONSTRAINT learning_outcome_results_pkey PRIMARY KEY (id);


--
-- Name: learning_outcomes learning_outcomes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY learning_outcomes
    ADD CONSTRAINT learning_outcomes_pkey PRIMARY KEY (id);


--
-- Name: live_assessments_assessments live_assessments_assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY live_assessments_assessments
    ADD CONSTRAINT live_assessments_assessments_pkey PRIMARY KEY (id);


--
-- Name: live_assessments_results live_assessments_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY live_assessments_results
    ADD CONSTRAINT live_assessments_results_pkey PRIMARY KEY (id);


--
-- Name: live_assessments_submissions live_assessments_submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY live_assessments_submissions
    ADD CONSTRAINT live_assessments_submissions_pkey PRIMARY KEY (id);


--
-- Name: lti_message_handlers lti_message_handlers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY lti_message_handlers
    ADD CONSTRAINT lti_message_handlers_pkey PRIMARY KEY (id);


--
-- Name: lti_product_families lti_product_families_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY lti_product_families
    ADD CONSTRAINT lti_product_families_pkey PRIMARY KEY (id);


--
-- Name: lti_resource_handlers lti_resource_handlers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY lti_resource_handlers
    ADD CONSTRAINT lti_resource_handlers_pkey PRIMARY KEY (id);


--
-- Name: lti_resource_placements lti_resource_placements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY lti_resource_placements
    ADD CONSTRAINT lti_resource_placements_pkey PRIMARY KEY (id);


--
-- Name: lti_tool_consumer_profiles lti_tool_consumer_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY lti_tool_consumer_profiles
    ADD CONSTRAINT lti_tool_consumer_profiles_pkey PRIMARY KEY (id);


--
-- Name: lti_tool_proxies lti_tool_proxies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY lti_tool_proxies
    ADD CONSTRAINT lti_tool_proxies_pkey PRIMARY KEY (id);


--
-- Name: lti_tool_proxy_bindings lti_tool_proxy_bindings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY lti_tool_proxy_bindings
    ADD CONSTRAINT lti_tool_proxy_bindings_pkey PRIMARY KEY (id);


--
-- Name: lti_tool_settings lti_tool_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY lti_tool_settings
    ADD CONSTRAINT lti_tool_settings_pkey PRIMARY KEY (id);


--
-- Name: master_courses_child_content_tags master_courses_child_content_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY master_courses_child_content_tags
    ADD CONSTRAINT master_courses_child_content_tags_pkey PRIMARY KEY (id);


--
-- Name: master_courses_child_subscriptions master_courses_child_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY master_courses_child_subscriptions
    ADD CONSTRAINT master_courses_child_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: master_courses_master_content_tags master_courses_master_content_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY master_courses_master_content_tags
    ADD CONSTRAINT master_courses_master_content_tags_pkey PRIMARY KEY (id);


--
-- Name: master_courses_master_migrations master_courses_master_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY master_courses_master_migrations
    ADD CONSTRAINT master_courses_master_migrations_pkey PRIMARY KEY (id);


--
-- Name: master_courses_master_templates master_courses_master_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY master_courses_master_templates
    ADD CONSTRAINT master_courses_master_templates_pkey PRIMARY KEY (id);


--
-- Name: master_courses_migration_results master_courses_migration_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY master_courses_migration_results
    ADD CONSTRAINT master_courses_migration_results_pkey PRIMARY KEY (id);


--
-- Name: media_objects media_objects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY media_objects
    ADD CONSTRAINT media_objects_pkey PRIMARY KEY (id);


--
-- Name: media_tracks media_tracks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY media_tracks
    ADD CONSTRAINT media_tracks_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: migration_issues migration_issues_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY migration_issues
    ADD CONSTRAINT migration_issues_pkey PRIMARY KEY (id);


--
-- Name: moderated_grading_provisional_grades moderated_grading_provisional_grades_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY moderated_grading_provisional_grades
    ADD CONSTRAINT moderated_grading_provisional_grades_pkey PRIMARY KEY (id);


--
-- Name: moderated_grading_selections moderated_grading_selections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY moderated_grading_selections
    ADD CONSTRAINT moderated_grading_selections_pkey PRIMARY KEY (id);


--
-- Name: notification_endpoints notification_endpoints_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY notification_endpoints
    ADD CONSTRAINT notification_endpoints_pkey PRIMARY KEY (id);


--
-- Name: notification_policies notification_policies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY notification_policies
    ADD CONSTRAINT notification_policies_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: oauth_requests oauth_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY oauth_requests
    ADD CONSTRAINT oauth_requests_pkey PRIMARY KEY (id);


--
-- Name: one_time_passwords one_time_passwords_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY one_time_passwords
    ADD CONSTRAINT one_time_passwords_pkey PRIMARY KEY (id);


--
-- Name: originality_reports originality_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY originality_reports
    ADD CONSTRAINT originality_reports_pkey PRIMARY KEY (id);


--
-- Name: page_comments page_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY page_comments
    ADD CONSTRAINT page_comments_pkey PRIMARY KEY (id);


--
-- Name: page_views page_views_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY page_views
    ADD CONSTRAINT page_views_pkey PRIMARY KEY (request_id);


--
-- Name: page_views_rollups page_views_rollups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY page_views_rollups
    ADD CONSTRAINT page_views_rollups_pkey PRIMARY KEY (id);


--
-- Name: planner_notes planner_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY planner_notes
    ADD CONSTRAINT planner_notes_pkey PRIMARY KEY (id);


--
-- Name: planner_overrides planner_overrides_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY planner_overrides
    ADD CONSTRAINT planner_overrides_pkey PRIMARY KEY (id);


--
-- Name: plugin_settings plugin_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY plugin_settings
    ADD CONSTRAINT plugin_settings_pkey PRIMARY KEY (id);


--
-- Name: polling_poll_choices polling_poll_choices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY polling_poll_choices
    ADD CONSTRAINT polling_poll_choices_pkey PRIMARY KEY (id);


--
-- Name: polling_poll_sessions polling_poll_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY polling_poll_sessions
    ADD CONSTRAINT polling_poll_sessions_pkey PRIMARY KEY (id);


--
-- Name: polling_poll_submissions polling_poll_submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY polling_poll_submissions
    ADD CONSTRAINT polling_poll_submissions_pkey PRIMARY KEY (id);


--
-- Name: polling_polls polling_polls_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY polling_polls
    ADD CONSTRAINT polling_polls_pkey PRIMARY KEY (id);


--
-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);


--
-- Name: progresses progresses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY progresses
    ADD CONSTRAINT progresses_pkey PRIMARY KEY (id);


--
-- Name: pseudonyms pseudonyms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY pseudonyms
    ADD CONSTRAINT pseudonyms_pkey PRIMARY KEY (id);


--
-- Name: purgatories purgatories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY purgatories
    ADD CONSTRAINT purgatories_pkey PRIMARY KEY (id);


--
-- Name: quiz_groups quiz_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY quiz_groups
    ADD CONSTRAINT quiz_groups_pkey PRIMARY KEY (id);


--
-- Name: quiz_question_regrades quiz_question_regrades_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY quiz_question_regrades
    ADD CONSTRAINT quiz_question_regrades_pkey PRIMARY KEY (id);


--
-- Name: quiz_questions quiz_questions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY quiz_questions
    ADD CONSTRAINT quiz_questions_pkey PRIMARY KEY (id);


--
-- Name: quiz_regrade_runs quiz_regrade_runs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY quiz_regrade_runs
    ADD CONSTRAINT quiz_regrade_runs_pkey PRIMARY KEY (id);


--
-- Name: quiz_regrades quiz_regrades_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY quiz_regrades
    ADD CONSTRAINT quiz_regrades_pkey PRIMARY KEY (id);


--
-- Name: quiz_statistics quiz_statistics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY quiz_statistics
    ADD CONSTRAINT quiz_statistics_pkey PRIMARY KEY (id);


--
-- Name: quiz_submission_events_2018_12 quiz_submission_events_2018_12_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY quiz_submission_events_2018_12
    ADD CONSTRAINT quiz_submission_events_2018_12_pkey PRIMARY KEY (id);


--
-- Name: quiz_submission_events_2019_1 quiz_submission_events_2019_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY quiz_submission_events_2019_1
    ADD CONSTRAINT quiz_submission_events_2019_1_pkey PRIMARY KEY (id);


--
-- Name: quiz_submission_events_2019_2 quiz_submission_events_2019_2_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY quiz_submission_events_2019_2
    ADD CONSTRAINT quiz_submission_events_2019_2_pkey PRIMARY KEY (id);


--
-- Name: quiz_submission_events_2019_3 quiz_submission_events_2019_3_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY quiz_submission_events_2019_3
    ADD CONSTRAINT quiz_submission_events_2019_3_pkey PRIMARY KEY (id);


--
-- Name: quiz_submission_events_2019_4 quiz_submission_events_2019_4_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY quiz_submission_events_2019_4
    ADD CONSTRAINT quiz_submission_events_2019_4_pkey PRIMARY KEY (id);


--
-- Name: quiz_submission_events_2019_5 quiz_submission_events_2019_5_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY quiz_submission_events_2019_5
    ADD CONSTRAINT quiz_submission_events_2019_5_pkey PRIMARY KEY (id);


--
-- Name: quiz_submission_events_2019_6 quiz_submission_events_2019_6_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY quiz_submission_events_2019_6
    ADD CONSTRAINT quiz_submission_events_2019_6_pkey PRIMARY KEY (id);


--
-- Name: quiz_submission_events quiz_submission_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY quiz_submission_events
    ADD CONSTRAINT quiz_submission_events_pkey PRIMARY KEY (id);


--
-- Name: quiz_submission_snapshots quiz_submission_snapshots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY quiz_submission_snapshots
    ADD CONSTRAINT quiz_submission_snapshots_pkey PRIMARY KEY (id);


--
-- Name: quiz_submissions quiz_submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY quiz_submissions
    ADD CONSTRAINT quiz_submissions_pkey PRIMARY KEY (id);


--
-- Name: quizzes quizzes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY quizzes
    ADD CONSTRAINT quizzes_pkey PRIMARY KEY (id);


--
-- Name: report_snapshots report_snapshots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY report_snapshots
    ADD CONSTRAINT report_snapshots_pkey PRIMARY KEY (id);


--
-- Name: role_overrides role_overrides_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY role_overrides
    ADD CONSTRAINT role_overrides_pkey PRIMARY KEY (id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: rubric_assessments rubric_assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY rubric_assessments
    ADD CONSTRAINT rubric_assessments_pkey PRIMARY KEY (id);


--
-- Name: rubric_associations rubric_associations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY rubric_associations
    ADD CONSTRAINT rubric_associations_pkey PRIMARY KEY (id);


--
-- Name: rubrics rubrics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY rubrics
    ADD CONSTRAINT rubrics_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: scores scores_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY scores
    ADD CONSTRAINT scores_pkey PRIMARY KEY (id);


--
-- Name: scribd_mime_types scribd_mime_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY scribd_mime_types
    ADD CONSTRAINT scribd_mime_types_pkey PRIMARY KEY (id);


--
-- Name: session_persistence_tokens session_persistence_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY session_persistence_tokens
    ADD CONSTRAINT session_persistence_tokens_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: settings settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY settings
    ADD CONSTRAINT settings_pkey PRIMARY KEY (id);


--
-- Name: shared_brand_configs shared_brand_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY shared_brand_configs
    ADD CONSTRAINT shared_brand_configs_pkey PRIMARY KEY (id);


--
-- Name: sis_batch_error_files sis_batch_error_files_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sis_batch_error_files
    ADD CONSTRAINT sis_batch_error_files_pkey PRIMARY KEY (id);


--
-- Name: sis_batches sis_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sis_batches
    ADD CONSTRAINT sis_batches_pkey PRIMARY KEY (id);


--
-- Name: sis_post_grades_statuses sis_post_grades_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sis_post_grades_statuses
    ADD CONSTRAINT sis_post_grades_statuses_pkey PRIMARY KEY (id);


--
-- Name: stream_item_instances stream_item_instances_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY stream_item_instances
    ADD CONSTRAINT stream_item_instances_pkey PRIMARY KEY (id);


--
-- Name: stream_items stream_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY stream_items
    ADD CONSTRAINT stream_items_pkey PRIMARY KEY (id);


--
-- Name: submission_comments submission_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY submission_comments
    ADD CONSTRAINT submission_comments_pkey PRIMARY KEY (id);


--
-- Name: submission_versions submission_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY submission_versions
    ADD CONSTRAINT submission_versions_pkey PRIMARY KEY (id);


--
-- Name: submissions submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY submissions
    ADD CONSTRAINT submissions_pkey PRIMARY KEY (id);


--
-- Name: switchman_shards switchman_shards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY switchman_shards
    ADD CONSTRAINT switchman_shards_pkey PRIMARY KEY (id);


--
-- Name: thumbnails thumbnails_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY thumbnails
    ADD CONSTRAINT thumbnails_pkey PRIMARY KEY (id);


--
-- Name: usage_rights usage_rights_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY usage_rights
    ADD CONSTRAINT usage_rights_pkey PRIMARY KEY (id);


--
-- Name: user_account_associations user_account_associations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_account_associations
    ADD CONSTRAINT user_account_associations_pkey PRIMARY KEY (id);


--
-- Name: user_merge_data user_merge_data_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_merge_data
    ADD CONSTRAINT user_merge_data_pkey PRIMARY KEY (id);


--
-- Name: user_merge_data_records user_merge_data_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_merge_data_records
    ADD CONSTRAINT user_merge_data_records_pkey PRIMARY KEY (id);


--
-- Name: user_notes user_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_notes
    ADD CONSTRAINT user_notes_pkey PRIMARY KEY (id);


--
-- Name: user_observers user_observers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_observers
    ADD CONSTRAINT user_observers_pkey PRIMARY KEY (id);


--
-- Name: user_profile_links user_profile_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_profile_links
    ADD CONSTRAINT user_profile_links_pkey PRIMARY KEY (id);


--
-- Name: user_profiles user_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_profiles
    ADD CONSTRAINT user_profiles_pkey PRIMARY KEY (id);


--
-- Name: user_services user_services_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_services
    ADD CONSTRAINT user_services_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: versions_0 versions_0_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY versions_0
    ADD CONSTRAINT versions_0_pkey PRIMARY KEY (id);


--
-- Name: versions_1 versions_1_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY versions_1
    ADD CONSTRAINT versions_1_pkey PRIMARY KEY (id);


--
-- Name: versions_2 versions_2_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY versions_2
    ADD CONSTRAINT versions_2_pkey PRIMARY KEY (id);


--
-- Name: versions versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (id);


--
-- Name: web_conference_participants web_conference_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY web_conference_participants
    ADD CONSTRAINT web_conference_participants_pkey PRIMARY KEY (id);


--
-- Name: web_conferences web_conferences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY web_conferences
    ADD CONSTRAINT web_conferences_pkey PRIMARY KEY (id);


--
-- Name: wiki_pages wiki_pages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY wiki_pages
    ADD CONSTRAINT wiki_pages_pkey PRIMARY KEY (id);


--
-- Name: wikis wikis_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY wikis
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
-- Name: by_sent_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX by_sent_at ON public.delayed_messages USING btree (send_at);


--
-- Name: ccid_raid_ws_sa; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ccid_raid_ws_sa ON public.delayed_messages USING btree (communication_channel_id, root_account_id, workflow_state, send_at);


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

CREATE INDEX get_delayed_jobs_index ON public.delayed_jobs USING btree (priority, run_at) WHERE ((locked_at IS NULL) AND ((queue)::text = 'canvas_queue'::text) AND (next_in_strand = true));


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
-- Name: index_access_tokens_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_access_tokens_on_user_id ON public.access_tokens USING btree (user_id);


--
-- Name: index_account_authorization_configs_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_authorization_configs_on_account_id ON public.account_authorization_configs USING btree (account_id);


--
-- Name: index_account_authorization_configs_on_metadata_uri; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_authorization_configs_on_metadata_uri ON public.account_authorization_configs USING btree (metadata_uri) WHERE (metadata_uri IS NOT NULL);


--
-- Name: index_account_authorization_configs_on_workflow_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_authorization_configs_on_workflow_state ON public.account_authorization_configs USING btree (workflow_state);


--
-- Name: index_account_notification_roles_on_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_account_notification_roles_on_role_id ON public.account_notification_roles USING btree (account_notification_id, role_id);


--
-- Name: index_account_notifications_by_account_and_timespan; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_notifications_by_account_and_timespan ON public.account_notifications USING btree (account_id, end_at, start_at);


--
-- Name: index_account_reports_latest_per_account; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_reports_latest_per_account ON public.account_reports USING btree (account_id, report_type, updated_at DESC);


--
-- Name: index_account_reports_on_attachment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_reports_on_attachment_id ON public.account_reports USING btree (attachment_id);


--
-- Name: index_account_users_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_users_on_account_id ON public.account_users USING btree (account_id);


--
-- Name: index_account_users_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_users_on_user_id ON public.account_users USING btree (user_id);


--
-- Name: index_account_users_on_workflow_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_users_on_workflow_state ON public.account_users USING btree (workflow_state);


--
-- Name: index_accounts_on_brand_config_md5; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_brand_config_md5 ON public.accounts USING btree (brand_config_md5) WHERE (brand_config_md5 IS NOT NULL);


--
-- Name: index_accounts_on_integration_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_accounts_on_integration_id ON public.accounts USING btree (integration_id, root_account_id) WHERE (integration_id IS NOT NULL);


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
-- Name: index_accounts_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_root_account_id ON public.accounts USING btree (root_account_id);


--
-- Name: index_accounts_on_sis_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_sis_batch_id ON public.accounts USING btree (sis_batch_id) WHERE (sis_batch_id IS NOT NULL);


--
-- Name: index_accounts_on_sis_source_id_and_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_accounts_on_sis_source_id_and_root_account_id ON public.accounts USING btree (sis_source_id, root_account_id) WHERE (sis_source_id IS NOT NULL);


--
-- Name: index_appointment_group_contexts_on_appointment_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_appointment_group_contexts_on_appointment_group_id ON public.appointment_group_contexts USING btree (appointment_group_id);


--
-- Name: index_appointment_group_sub_contexts_on_appointment_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_appointment_group_sub_contexts_on_appointment_group_id ON public.appointment_group_sub_contexts USING btree (appointment_group_id);


--
-- Name: index_appointment_groups_on_context_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_appointment_groups_on_context_id ON public.appointment_groups USING btree (context_id);


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
-- Name: index_assignment_configuration_tool_lookups_on_assignment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignment_configuration_tool_lookups_on_assignment_id ON public.assignment_configuration_tool_lookups USING btree (assignment_id);


--
-- Name: index_assignment_groups_on_context_id_and_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignment_groups_on_context_id_and_context_type ON public.assignment_groups USING btree (context_id, context_type);


--
-- Name: index_assignment_override_students_on_assignment_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_assignment_override_students_on_assignment_id_and_user_id ON public.assignment_override_students USING btree (assignment_id, user_id);


--
-- Name: index_assignment_override_students_on_assignment_override_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignment_override_students_on_assignment_override_id ON public.assignment_override_students USING btree (assignment_override_id);


--
-- Name: index_assignment_override_students_on_quiz_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignment_override_students_on_quiz_id ON public.assignment_override_students USING btree (quiz_id);


--
-- Name: index_assignment_override_students_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignment_override_students_on_user_id ON public.assignment_override_students USING btree (user_id);


--
-- Name: index_assignment_overrides_on_assignment_and_set; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_assignment_overrides_on_assignment_and_set ON public.assignment_overrides USING btree (assignment_id, set_type, set_id) WHERE (((workflow_state)::text = 'active'::text) AND (set_id IS NOT NULL));


--
-- Name: index_assignment_overrides_on_assignment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignment_overrides_on_assignment_id ON public.assignment_overrides USING btree (assignment_id);


--
-- Name: index_assignment_overrides_on_quiz_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignment_overrides_on_quiz_id ON public.assignment_overrides USING btree (quiz_id);


--
-- Name: index_assignment_overrides_on_set_type_and_set_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignment_overrides_on_set_type_and_set_id ON public.assignment_overrides USING btree (set_type, set_id);


--
-- Name: index_assignments_on_assignment_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignments_on_assignment_group_id ON public.assignments USING btree (assignment_group_id);


--
-- Name: index_assignments_on_context_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignments_on_context_code ON public.assignments USING btree (context_code);


--
-- Name: index_assignments_on_context_id_and_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignments_on_context_id_and_context_type ON public.assignments USING btree (context_id, context_type);


--
-- Name: index_assignments_on_due_at_and_context_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignments_on_due_at_and_context_code ON public.assignments USING btree (due_at, context_code);


--
-- Name: index_assignments_on_grading_standard_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assignments_on_grading_standard_id ON public.assignments USING btree (grading_standard_id);


--
-- Name: index_assignments_on_lti_context_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_assignments_on_lti_context_id ON public.assignments USING btree (lti_context_id);


--
-- Name: index_assignments_on_turnitin_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_assignments_on_turnitin_id ON public.assignments USING btree (turnitin_id) WHERE (turnitin_id IS NOT NULL);


--
-- Name: index_attachment_associations_on_attachment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachment_associations_on_attachment_id ON public.attachment_associations USING btree (attachment_id);


--
-- Name: index_attachments_on_cloned_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_cloned_item_id ON public.attachments USING btree (cloned_item_id);


--
-- Name: index_attachments_on_context_and_migration_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_context_and_migration_id ON public.attachments USING btree (context_id, context_type, migration_id) WHERE (migration_id IS NOT NULL);


--
-- Name: index_attachments_on_context_id_and_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_context_id_and_context_type ON public.attachments USING btree (context_id, context_type);


--
-- Name: index_attachments_on_folder_id_and_file_state_and_display_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_folder_id_and_file_state_and_display_name ON public.attachments USING btree (folder_id, file_state, ((lower(replace(display_name, '\'::text, '\\'::text)))::bytea)) WHERE (folder_id IS NOT NULL);


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
-- Name: index_attachments_on_root_attachment_id_not_null; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_root_attachment_id_not_null ON public.attachments USING btree (root_attachment_id) WHERE (root_attachment_id IS NOT NULL);


--
-- Name: index_attachments_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_user_id ON public.attachments USING btree (user_id);


--
-- Name: index_attachments_on_workflow_state_and_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_workflow_state_and_updated_at ON public.attachments USING btree (workflow_state, updated_at);


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
-- Name: index_calendar_events_on_parent_calendar_event_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_calendar_events_on_parent_calendar_event_id ON public.calendar_events USING btree (parent_calendar_event_id);


--
-- Name: index_calendar_events_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_calendar_events_on_user_id ON public.calendar_events USING btree (user_id);


--
-- Name: index_canvadocs_on_attachment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_canvadocs_on_attachment_id ON public.canvadocs USING btree (attachment_id);


--
-- Name: index_canvadocs_on_document_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_canvadocs_on_document_id ON public.canvadocs USING btree (document_id);


--
-- Name: index_canvadocs_submissions_on_crocodoc_document_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_canvadocs_submissions_on_crocodoc_document_id ON public.canvadocs_submissions USING btree (crocodoc_document_id) WHERE (crocodoc_document_id IS NOT NULL);


--
-- Name: index_canvadocs_submissions_on_submission_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_canvadocs_submissions_on_submission_id ON public.canvadocs_submissions USING btree (submission_id);


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
-- Name: index_content_exports_on_attachment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_exports_on_attachment_id ON public.content_exports USING btree (attachment_id);


--
-- Name: index_content_exports_on_content_migration_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_exports_on_content_migration_id ON public.content_exports USING btree (content_migration_id);


--
-- Name: index_content_migrations_on_attachment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_migrations_on_attachment_id ON public.content_migrations USING btree (attachment_id) WHERE (attachment_id IS NOT NULL);


--
-- Name: index_content_migrations_on_context_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_migrations_on_context_id ON public.content_migrations USING btree (context_id);


--
-- Name: index_content_migrations_on_exported_attachment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_migrations_on_exported_attachment_id ON public.content_migrations USING btree (exported_attachment_id) WHERE (exported_attachment_id IS NOT NULL);


--
-- Name: index_content_migrations_on_overview_attachment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_migrations_on_overview_attachment_id ON public.content_migrations USING btree (overview_attachment_id) WHERE (overview_attachment_id IS NOT NULL);


--
-- Name: index_content_migrations_on_source_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_migrations_on_source_course_id ON public.content_migrations USING btree (source_course_id) WHERE (source_course_id IS NOT NULL);


--
-- Name: index_content_participation_counts_uniquely; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_content_participation_counts_uniquely ON public.content_participation_counts USING btree (context_id, context_type, user_id, content_type);


--
-- Name: index_content_participations_uniquely; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_content_participations_uniquely ON public.content_participations USING btree (content_id, content_type, user_id);


--
-- Name: index_content_tags_on_associated_asset; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_tags_on_associated_asset ON public.content_tags USING btree (associated_asset_id, associated_asset_type);


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
-- Name: index_content_tags_on_learning_outcome_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_tags_on_learning_outcome_id ON public.content_tags USING btree (learning_outcome_id) WHERE (learning_outcome_id IS NOT NULL);


--
-- Name: index_context_external_tool_assignment_lookups_on_assignment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_context_external_tool_assignment_lookups_on_assignment_id ON public.context_external_tool_assignment_lookups USING btree (assignment_id);


--
-- Name: index_context_external_tools_on_context_id_and_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_context_external_tools_on_context_id_and_context_type ON public.context_external_tools USING btree (context_id, context_type);


--
-- Name: index_context_external_tools_on_tool_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_context_external_tools_on_tool_id ON public.context_external_tools USING btree (tool_id);


--
-- Name: index_context_module_progressions_on_context_module_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_context_module_progressions_on_context_module_id ON public.context_module_progressions USING btree (context_module_id);


--
-- Name: index_context_modules_on_context_id_and_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_context_modules_on_context_id_and_context_type ON public.context_modules USING btree (context_id, context_type);


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
-- Name: index_course_sections_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_course_sections_on_root_account_id ON public.course_sections USING btree (root_account_id);


--
-- Name: index_course_sections_on_sis_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_course_sections_on_sis_batch_id ON public.course_sections USING btree (sis_batch_id) WHERE (sis_batch_id IS NOT NULL);


--
-- Name: index_course_sections_on_sis_source_id_and_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_course_sections_on_sis_source_id_and_root_account_id ON public.course_sections USING btree (sis_source_id, root_account_id) WHERE (sis_source_id IS NOT NULL);


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
-- Name: index_courses_on_integration_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_courses_on_integration_id ON public.courses USING btree (integration_id, root_account_id) WHERE (integration_id IS NOT NULL);


--
-- Name: index_courses_on_lti_context_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_courses_on_lti_context_id ON public.courses USING btree (lti_context_id);


--
-- Name: index_courses_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_courses_on_root_account_id ON public.courses USING btree (root_account_id);


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
-- Name: index_custom_data_on_user_id_and_namespace; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_custom_data_on_user_id_and_namespace ON public.custom_data USING btree (user_id, namespace);


--
-- Name: index_custom_gradebook_column_data_unique_column_and_user; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_custom_gradebook_column_data_unique_column_and_user ON public.custom_gradebook_column_data USING btree (custom_gradebook_column_id, user_id);


--
-- Name: index_custom_gradebook_columns_on_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_custom_gradebook_columns_on_course_id ON public.custom_gradebook_columns USING btree (course_id);


--
-- Name: index_delayed_jobs_on_locked_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delayed_jobs_on_locked_by ON public.delayed_jobs USING btree (locked_by) WHERE (locked_by IS NOT NULL);


--
-- Name: index_delayed_jobs_on_run_at_and_tag; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delayed_jobs_on_run_at_and_tag ON public.delayed_jobs USING btree (run_at, tag);


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
-- Name: index_developer_keys_on_vendor_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_developer_keys_on_vendor_code ON public.developer_keys USING btree (vendor_code);


--
-- Name: index_discussion_entries_for_topic; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_entries_for_topic ON public.discussion_entries USING btree (discussion_topic_id, updated_at, created_at);


--
-- Name: index_discussion_entries_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_entries_on_parent_id ON public.discussion_entries USING btree (parent_id);


--
-- Name: index_discussion_entries_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_entries_on_user_id ON public.discussion_entries USING btree (user_id);


--
-- Name: index_discussion_entries_root_entry; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_entries_root_entry ON public.discussion_entries USING btree (root_entry_id, workflow_state, created_at);


--
-- Name: index_discussion_topics_on_assignment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_topics_on_assignment_id ON public.discussion_topics USING btree (assignment_id);


--
-- Name: index_discussion_topics_on_attachment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_topics_on_attachment_id ON public.discussion_topics USING btree (attachment_id) WHERE (attachment_id IS NOT NULL);


--
-- Name: index_discussion_topics_on_context_and_last_reply_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_topics_on_context_and_last_reply_at ON public.discussion_topics USING btree (context_id, last_reply_at);


--
-- Name: index_discussion_topics_on_context_id_and_position; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_topics_on_context_id_and_position ON public.discussion_topics USING btree (context_id, "position");


--
-- Name: index_discussion_topics_on_external_feed_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_topics_on_external_feed_id ON public.discussion_topics USING btree (external_feed_id) WHERE (external_feed_id IS NOT NULL);


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
-- Name: index_discussion_topics_unique_subtopic_per_context; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_discussion_topics_unique_subtopic_per_context ON public.discussion_topics USING btree (context_id, context_type, root_topic_id);


--
-- Name: index_enrollment_dates_overrides_on_enrollment_term_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_enrollment_dates_overrides_on_enrollment_term_id ON public.enrollment_dates_overrides USING btree (enrollment_term_id);


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
-- Name: index_enrollment_terms_on_grading_period_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_enrollment_terms_on_grading_period_group_id ON public.enrollment_terms USING btree (grading_period_group_id);


--
-- Name: index_enrollment_terms_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_enrollment_terms_on_root_account_id ON public.enrollment_terms USING btree (root_account_id);


--
-- Name: index_enrollment_terms_on_sis_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_enrollment_terms_on_sis_batch_id ON public.enrollment_terms USING btree (sis_batch_id) WHERE (sis_batch_id IS NOT NULL);


--
-- Name: index_enrollment_terms_on_sis_source_id_and_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_enrollment_terms_on_sis_source_id_and_root_account_id ON public.enrollment_terms USING btree (sis_source_id, root_account_id) WHERE (sis_source_id IS NOT NULL);


--
-- Name: index_enrollments_on_associated_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_enrollments_on_associated_user_id ON public.enrollments USING btree (associated_user_id) WHERE (associated_user_id IS NOT NULL);


--
-- Name: index_enrollments_on_course_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_enrollments_on_course_id_and_user_id ON public.enrollments USING btree (course_id, user_id);


--
-- Name: index_enrollments_on_course_id_and_workflow_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_enrollments_on_course_id_and_workflow_state ON public.enrollments USING btree (course_id, workflow_state);


--
-- Name: index_enrollments_on_course_section_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_enrollments_on_course_section_id ON public.enrollments USING btree (course_section_id);


--
-- Name: index_enrollments_on_root_account_id_and_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_enrollments_on_root_account_id_and_course_id ON public.enrollments USING btree (root_account_id, course_id);


--
-- Name: index_enrollments_on_sis_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_enrollments_on_sis_batch_id ON public.enrollments USING btree (sis_batch_id) WHERE (sis_batch_id IS NOT NULL);


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
-- Name: index_external_feed_entries_on_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_external_feed_entries_on_uuid ON public.external_feed_entries USING btree (uuid);


--
-- Name: index_external_feeds_on_context_id_and_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_external_feeds_on_context_id_and_context_type ON public.external_feeds USING btree (context_id, context_type);


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
-- Name: index_favorites_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_favorites_on_user_id ON public.favorites USING btree (user_id);


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
-- Name: index_generated_quiz_questions; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_generated_quiz_questions ON public.quiz_questions USING btree (assessment_question_id, quiz_group_id, duplicate_index) WHERE ((assessment_question_id IS NOT NULL) AND (quiz_group_id IS NOT NULL) AND ((workflow_state)::text = 'generated'::text));


--
-- Name: index_gradebook_csvs_on_user_id_and_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gradebook_csvs_on_user_id_and_course_id ON public.gradebook_csvs USING btree (user_id, course_id);


--
-- Name: index_gradebook_uploads_on_course_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_gradebook_uploads_on_course_id_and_user_id ON public.gradebook_uploads USING btree (course_id, user_id);


--
-- Name: index_gradebook_uploads_on_progress_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gradebook_uploads_on_progress_id ON public.gradebook_uploads USING btree (progress_id);


--
-- Name: index_grading_period_groups_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_grading_period_groups_on_account_id ON public.grading_period_groups USING btree (account_id);


--
-- Name: index_grading_period_groups_on_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_grading_period_groups_on_course_id ON public.grading_period_groups USING btree (course_id);


--
-- Name: index_grading_period_groups_on_workflow_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_grading_period_groups_on_workflow_state ON public.grading_period_groups USING btree (workflow_state);


--
-- Name: index_grading_periods_on_grading_period_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_grading_periods_on_grading_period_group_id ON public.grading_periods USING btree (grading_period_group_id);


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
-- Name: index_group_categories_on_context; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_group_categories_on_context ON public.group_categories USING btree (context_id, context_type);


--
-- Name: index_group_categories_on_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_group_categories_on_role ON public.group_categories USING btree (role);


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
-- Name: index_ignores_on_asset_and_user_id_and_purpose; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ignores_on_asset_and_user_id_and_purpose ON public.ignores USING btree (asset_id, asset_type, user_id, purpose);


--
-- Name: index_late_policies_on_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_late_policies_on_course_id ON public.late_policies USING btree (course_id);


--
-- Name: index_learning_outcome_groups_on_context_id_and_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_learning_outcome_groups_on_context_id_and_context_type ON public.learning_outcome_groups USING btree (context_id, context_type);


--
-- Name: index_learning_outcome_groups_on_learning_outcome_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_learning_outcome_groups_on_learning_outcome_group_id ON public.learning_outcome_groups USING btree (learning_outcome_group_id) WHERE (learning_outcome_group_id IS NOT NULL);


--
-- Name: index_learning_outcome_groups_on_root_learning_outcome_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_learning_outcome_groups_on_root_learning_outcome_group_id ON public.learning_outcome_groups USING btree (root_learning_outcome_group_id) WHERE (root_learning_outcome_group_id IS NOT NULL);


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
-- Name: index_learning_outcomes_on_context_id_and_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_learning_outcomes_on_context_id_and_context_type ON public.learning_outcomes USING btree (context_id, context_type);


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
-- Name: index_live_assessments_submissions_on_assessment_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_live_assessments_submissions_on_assessment_id_and_user_id ON public.live_assessments_submissions USING btree (assessment_id, user_id);


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
-- Name: index_lti_resource_handlers_on_tool_proxy_and_type_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_lti_resource_handlers_on_tool_proxy_and_type_code ON public.lti_resource_handlers USING btree (tool_proxy_id, resource_type_code);


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
-- Name: index_lti_tool_proxy_bindings_on_context_and_tool_proxy; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_lti_tool_proxy_bindings_on_context_and_tool_proxy ON public.lti_tool_proxy_bindings USING btree (context_id, context_type, tool_proxy_id);


--
-- Name: index_lti_tool_settings_on_link_context_and_tool_proxy; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_lti_tool_settings_on_link_context_and_tool_proxy ON public.lti_tool_settings USING btree (resource_link_id, context_type, context_id, tool_proxy_id);


--
-- Name: index_master_content_tags_on_migration_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_master_content_tags_on_migration_id ON public.master_courses_master_content_tags USING btree (migration_id);


--
-- Name: index_master_content_tags_on_template_id_and_content; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_master_content_tags_on_template_id_and_content ON public.master_courses_master_content_tags USING btree (master_template_id, content_type, content_id);


--
-- Name: index_master_courses_child_subscriptions_on_master_template_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_master_courses_child_subscriptions_on_master_template_id ON public.master_courses_child_subscriptions USING btree (master_template_id);


--
-- Name: index_master_courses_master_content_tags_on_master_template_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_master_courses_master_content_tags_on_master_template_id ON public.master_courses_master_content_tags USING btree (master_template_id);


--
-- Name: index_master_courses_master_migrations_on_master_template_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_master_courses_master_migrations_on_master_template_id ON public.master_courses_master_migrations USING btree (master_template_id);


--
-- Name: index_master_courses_master_templates_on_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_master_courses_master_templates_on_course_id ON public.master_courses_master_templates USING btree (course_id);


--
-- Name: index_master_templates_unique_on_course_and_full; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_master_templates_unique_on_course_and_full ON public.master_courses_master_templates USING btree (course_id) WHERE (full_course AND ((workflow_state)::text <> 'deleted'::text));


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
-- Name: index_messages_on_communication_channel_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_communication_channel_id ON public.messages USING btree (communication_channel_id);


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
-- Name: index_migration_issues_on_content_migration_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_migration_issues_on_content_migration_id ON public.migration_issues USING btree (content_migration_id);


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
-- Name: index_notification_endpoints_on_access_token_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notification_endpoints_on_access_token_id ON public.notification_endpoints USING btree (access_token_id);


--
-- Name: index_notification_policies_on_cc_and_notification_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_notification_policies_on_cc_and_notification_id ON public.notification_policies USING btree (communication_channel_id, notification_id);


--
-- Name: index_notification_policies_on_notification_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notification_policies_on_notification_id ON public.notification_policies USING btree (notification_id);


--
-- Name: index_notifications_unique_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_notifications_unique_on_name ON public.notifications USING btree (name);


--
-- Name: index_on_aqb_on_context_id_and_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_on_aqb_on_context_id_and_context_type ON public.assessment_question_banks USING btree (context_id, context_type);


--
-- Name: index_on_report_snapshots; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_on_report_snapshots ON public.report_snapshots USING btree (report_type, account_id, created_at);


--
-- Name: index_one_time_passwords_on_user_id_and_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_one_time_passwords_on_user_id_and_code ON public.one_time_passwords USING btree (user_id, code);


--
-- Name: index_originality_reports_on_attachment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_originality_reports_on_attachment_id ON public.originality_reports USING btree (attachment_id);


--
-- Name: index_originality_reports_on_originality_report_attachment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_originality_reports_on_originality_report_attachment_id ON public.originality_reports USING btree (originality_report_attachment_id);


--
-- Name: index_originality_reports_on_submission_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_originality_reports_on_submission_id ON public.originality_reports USING btree (submission_id);


--
-- Name: index_originality_reports_on_workflow_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_originality_reports_on_workflow_state ON public.originality_reports USING btree (workflow_state);


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
-- Name: index_page_views_on_user_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_page_views_on_user_id_and_created_at ON public.page_views USING btree (user_id, created_at);


--
-- Name: index_page_views_rollups_on_course_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_page_views_rollups_on_course_id ON public.page_views_rollups USING btree (course_id);


--
-- Name: index_page_views_rollups_on_course_id_and_date_and_category; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_page_views_rollups_on_course_id_and_date_and_category ON public.page_views_rollups USING btree (course_id, date, category);


--
-- Name: index_page_views_summarized_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_page_views_summarized_created_at ON public.page_views USING btree (summarized, created_at);


--
-- Name: index_planner_notes_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_planner_notes_on_user_id ON public.planner_notes USING btree (user_id);


--
-- Name: index_planner_overrides_on_plannable_and_user; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_planner_overrides_on_plannable_and_user ON public.planner_overrides USING btree (plannable_type, plannable_id, user_id);


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
-- Name: index_pseudonyms_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pseudonyms_on_account_id ON public.pseudonyms USING btree (account_id);


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
-- Name: index_pseudonyms_on_unique_id_and_account_id_and_authentication; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_pseudonyms_on_unique_id_and_account_id_and_authentication ON public.pseudonyms USING btree (lower((unique_id)::text), account_id, authentication_provider_id) WHERE ((workflow_state)::text = 'active'::text);


--
-- Name: index_pseudonyms_on_unique_id_and_account_id_no_authentication_; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_pseudonyms_on_unique_id_and_account_id_no_authentication_ ON public.pseudonyms USING btree (lower((unique_id)::text), account_id) WHERE (((workflow_state)::text = 'active'::text) AND (authentication_provider_id IS NULL));


--
-- Name: index_pseudonyms_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pseudonyms_on_user_id ON public.pseudonyms USING btree (user_id);


--
-- Name: index_purgatories_on_attachment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_purgatories_on_attachment_id ON public.purgatories USING btree (attachment_id);


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
-- Name: index_quiz_questions_on_assessment_question_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_quiz_questions_on_assessment_question_id ON public.quiz_questions USING btree (assessment_question_id) WHERE (assessment_question_id IS NOT NULL);


--
-- Name: index_quiz_regrades_on_quiz_id_and_quiz_version; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_quiz_regrades_on_quiz_id_and_quiz_version ON public.quiz_regrades USING btree (quiz_id, quiz_version);


--
-- Name: index_quiz_statistics_on_quiz_id_and_report_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_quiz_statistics_on_quiz_id_and_report_type ON public.quiz_statistics USING btree (quiz_id, report_type);


--
-- Name: index_quiz_submission_events_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_quiz_submission_events_on_created_at ON public.quiz_submission_events USING btree (created_at);


--
-- Name: index_quiz_submission_snapshots_on_quiz_submission_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_quiz_submission_snapshots_on_quiz_submission_id ON public.quiz_submission_snapshots USING btree (quiz_submission_id);


--
-- Name: index_quiz_submissions_on_quiz_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_quiz_submissions_on_quiz_id_and_user_id ON public.quiz_submissions USING btree (quiz_id, user_id);


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
-- Name: index_quizzes_on_context_id_and_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_quizzes_on_context_id_and_context_type ON public.quizzes USING btree (context_id, context_type);


--
-- Name: index_resource_codes_on_assignment_configuration_tool_lookups; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_resource_codes_on_assignment_configuration_tool_lookups ON public.assignment_configuration_tool_lookups USING btree (tool_product_code, tool_vendor_code, tool_resource_type_code);


--
-- Name: index_resource_placements_on_placement_and_message_handler; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_resource_placements_on_placement_and_message_handler ON public.lti_resource_placements USING btree (placement, message_handler_id) WHERE (message_handler_id IS NOT NULL);


--
-- Name: index_role_overrides_on_context_id_and_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_role_overrides_on_context_id_and_context_type ON public.role_overrides USING btree (context_id, context_type);


--
-- Name: index_roles_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roles_on_account_id ON public.roles USING btree (account_id);


--
-- Name: index_roles_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roles_on_name ON public.roles USING btree (name);


--
-- Name: index_roles_on_root_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roles_on_root_account_id ON public.roles USING btree (root_account_id);


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
-- Name: index_rubric_associations_on_rubric_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rubric_associations_on_rubric_id ON public.rubric_associations USING btree (rubric_id);


--
-- Name: index_rubrics_on_context_id_and_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rubrics_on_context_id_and_context_type ON public.rubrics USING btree (context_id, context_type);


--
-- Name: index_rubrics_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rubrics_on_user_id ON public.rubrics USING btree (user_id);


--
-- Name: index_scores_on_enrollment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_scores_on_enrollment_id ON public.scores USING btree (enrollment_id) WHERE (grading_period_id IS NULL);


--
-- Name: index_scores_on_enrollment_id_and_grading_period_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_scores_on_enrollment_id_and_grading_period_id ON public.scores USING btree (enrollment_id, grading_period_id);


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
-- Name: index_sis_batch_error_files_on_sis_batch_id_and_attachment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_sis_batch_error_files_on_sis_batch_id_and_attachment_id ON public.sis_batch_error_files USING btree (sis_batch_id, attachment_id);


--
-- Name: index_sis_batches_account_id_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sis_batches_account_id_created_at ON public.sis_batches USING btree (account_id, created_at);


--
-- Name: index_sis_batches_diffing; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sis_batches_diffing ON public.sis_batches USING btree (account_id, diffing_data_set_identifier, created_at);


--
-- Name: index_sis_batches_on_batch_mode_term_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sis_batches_on_batch_mode_term_id ON public.sis_batches USING btree (batch_mode_term_id) WHERE (batch_mode_term_id IS NOT NULL);


--
-- Name: index_sis_batches_on_errors_attachment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sis_batches_on_errors_attachment_id ON public.sis_batches USING btree (errors_attachment_id);


--
-- Name: index_sis_batches_pending_for_accounts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sis_batches_pending_for_accounts ON public.sis_batches USING btree (account_id, created_at) WHERE ((workflow_state)::text = 'created'::text);


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
-- Name: index_submission_comments_on_submission_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submission_comments_on_submission_id ON public.submission_comments USING btree (submission_id);


--
-- Name: index_submission_versions; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_submission_versions ON public.submission_versions USING btree (context_id, version_id, user_id, assignment_id) WHERE ((context_type)::text = 'Course'::text);


--
-- Name: index_submissions_needs_grading; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submissions_needs_grading ON public.submissions USING btree (assignment_id) WHERE ((submission_type IS NOT NULL) AND ((excused = false) OR (excused IS NULL)) AND (((workflow_state)::text = 'pending_review'::text) OR (((workflow_state)::text = ANY (ARRAY[('submitted'::character varying)::text, ('graded'::character varying)::text])) AND ((score IS NULL) OR (NOT grade_matches_current_submission)))));


--
-- Name: index_submissions_on_assignment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submissions_on_assignment_id ON public.submissions USING btree (assignment_id) WHERE ((submission_type IS NOT NULL) AND (((workflow_state)::text = 'pending_review'::text) OR (((workflow_state)::text = 'submitted'::text) AND ((score IS NULL) OR (NOT grade_matches_current_submission)))));


--
-- Name: index_submissions_on_assignment_id_and_submission_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submissions_on_assignment_id_and_submission_type ON public.submissions USING btree (assignment_id, submission_type);


--
-- Name: index_submissions_on_assignment_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submissions_on_assignment_id_and_user_id ON public.submissions USING btree (assignment_id, user_id);


--
-- Name: index_submissions_on_grading_period_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submissions_on_grading_period_id ON public.submissions USING btree (grading_period_id) WHERE (grading_period_id IS NOT NULL);


--
-- Name: index_submissions_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submissions_on_group_id ON public.submissions USING btree (group_id) WHERE (group_id IS NOT NULL);


--
-- Name: index_submissions_on_quiz_submission_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submissions_on_quiz_submission_id ON public.submissions USING btree (quiz_submission_id) WHERE (quiz_submission_id IS NOT NULL);


--
-- Name: index_submissions_on_submitted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_submissions_on_submitted_at ON public.submissions USING btree (submitted_at);


--
-- Name: index_submissions_on_user_id_and_assignment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_submissions_on_user_id_and_assignment_id ON public.submissions USING btree (user_id, assignment_id);


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
-- Name: index_user_account_associations_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_account_associations_on_account_id ON public.user_account_associations USING btree (account_id);


--
-- Name: index_user_account_associations_on_user_id_and_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_account_associations_on_user_id_and_account_id ON public.user_account_associations USING btree (user_id, account_id);


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

CREATE UNIQUE INDEX index_user_merge_data_records_on_context_id_and_context_type ON public.user_merge_data_records USING btree (context_id, context_type, user_merge_data_id, previous_user_id);


--
-- Name: index_user_merge_data_records_on_user_merge_data_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_merge_data_records_on_user_merge_data_id ON public.user_merge_data_records USING btree (user_merge_data_id);


--
-- Name: index_user_notes_on_user_id_and_workflow_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_notes_on_user_id_and_workflow_state ON public.user_notes USING btree (user_id, workflow_state);


--
-- Name: index_user_observers_on_observer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_observers_on_observer_id ON public.user_observers USING btree (observer_id);


--
-- Name: index_user_observers_on_sis_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_observers_on_sis_batch_id ON public.user_observers USING btree (sis_batch_id) WHERE (sis_batch_id IS NOT NULL);


--
-- Name: index_user_observers_on_user_id_and_observer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_observers_on_user_id_and_observer_id ON public.user_observers USING btree (user_id, observer_id);


--
-- Name: index_user_observers_on_workflow_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_observers_on_workflow_state ON public.user_observers USING btree (workflow_state);


--
-- Name: index_user_services_on_id_and_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_services_on_id_and_type ON public.user_services USING btree (id, type);


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
-- Name: index_users_on_sortable_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_sortable_name ON public.users USING btree (((lower(replace((sortable_name)::text, '\'::text, '\\'::text)))::bytea));


--
-- Name: index_users_on_turnitin_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_turnitin_id ON public.users USING btree (turnitin_id) WHERE (turnitin_id IS NOT NULL);


--
-- Name: index_users_on_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_uuid ON public.users USING btree (uuid);


--
-- Name: index_versions_on_versionable_object_and_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_versions_on_versionable_object_and_number ON public.versions USING btree (versionable_id, versionable_type, number);


--
-- Name: index_web_conference_participants_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_web_conference_participants_on_user_id ON public.web_conference_participants USING btree (user_id);


--
-- Name: index_web_conference_participants_on_web_conference_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_web_conference_participants_on_web_conference_id ON public.web_conference_participants USING btree (web_conference_id);


--
-- Name: index_web_conferences_on_context_id_and_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_web_conferences_on_context_id_and_context_type ON public.web_conferences USING btree (context_id, context_type);


--
-- Name: index_web_conferences_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_web_conferences_on_user_id ON public.web_conferences USING btree (user_id);


--
-- Name: index_wiki_pages_on_assignment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wiki_pages_on_assignment_id ON public.wiki_pages USING btree (assignment_id);


--
-- Name: index_wiki_pages_on_context_id_and_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wiki_pages_on_context_id_and_context_type ON public.wiki_pages USING btree (context_id, context_type);


--
-- Name: index_wiki_pages_on_old_assignment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wiki_pages_on_old_assignment_id ON public.wiki_pages USING btree (old_assignment_id);


--
-- Name: index_wiki_pages_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wiki_pages_on_user_id ON public.wiki_pages USING btree (user_id);


--
-- Name: index_wiki_pages_on_wiki_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wiki_pages_on_wiki_id ON public.wiki_pages USING btree (wiki_id);


--
-- Name: media_object_id_locale; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX media_object_id_locale ON public.media_tracks USING btree (media_object_id, locale);


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
-- Name: quiz_submission_events_2018_12_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX quiz_submission_events_2018_12_created_at_idx ON public.quiz_submission_events_2018_12 USING btree (created_at);


--
-- Name: quiz_submission_events_2018_1_quiz_submission_id_attempt_cr_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX quiz_submission_events_2018_1_quiz_submission_id_attempt_cr_idx ON public.quiz_submission_events_2018_12 USING btree (quiz_submission_id, attempt, created_at);


--
-- Name: quiz_submission_events_2019_1_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX quiz_submission_events_2019_1_created_at_idx ON public.quiz_submission_events_2019_1 USING btree (created_at);


--
-- Name: quiz_submission_events_2019_1_quiz_submission_id_attempt_cr_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX quiz_submission_events_2019_1_quiz_submission_id_attempt_cr_idx ON public.quiz_submission_events_2019_1 USING btree (quiz_submission_id, attempt, created_at);


--
-- Name: quiz_submission_events_2019_2_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX quiz_submission_events_2019_2_created_at_idx ON public.quiz_submission_events_2019_2 USING btree (created_at);


--
-- Name: quiz_submission_events_2019_2_quiz_submission_id_attempt_cr_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX quiz_submission_events_2019_2_quiz_submission_id_attempt_cr_idx ON public.quiz_submission_events_2019_2 USING btree (quiz_submission_id, attempt, created_at);


--
-- Name: quiz_submission_events_2019_3_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX quiz_submission_events_2019_3_created_at_idx ON public.quiz_submission_events_2019_3 USING btree (created_at);


--
-- Name: quiz_submission_events_2019_3_quiz_submission_id_attempt_cr_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX quiz_submission_events_2019_3_quiz_submission_id_attempt_cr_idx ON public.quiz_submission_events_2019_3 USING btree (quiz_submission_id, attempt, created_at);


--
-- Name: quiz_submission_events_2019_4_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX quiz_submission_events_2019_4_created_at_idx ON public.quiz_submission_events_2019_4 USING btree (created_at);


--
-- Name: quiz_submission_events_2019_4_quiz_submission_id_attempt_cr_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX quiz_submission_events_2019_4_quiz_submission_id_attempt_cr_idx ON public.quiz_submission_events_2019_4 USING btree (quiz_submission_id, attempt, created_at);


--
-- Name: quiz_submission_events_2019_5_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX quiz_submission_events_2019_5_created_at_idx ON public.quiz_submission_events_2019_5 USING btree (created_at);


--
-- Name: quiz_submission_events_2019_5_quiz_submission_id_attempt_cr_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX quiz_submission_events_2019_5_quiz_submission_id_attempt_cr_idx ON public.quiz_submission_events_2019_5 USING btree (quiz_submission_id, attempt, created_at);


--
-- Name: quiz_submission_events_2019_6_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX quiz_submission_events_2019_6_created_at_idx ON public.quiz_submission_events_2019_6 USING btree (created_at);


--
-- Name: quiz_submission_events_2019_6_quiz_submission_id_attempt_cr_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX quiz_submission_events_2019_6_quiz_submission_id_attempt_cr_idx ON public.quiz_submission_events_2019_6 USING btree (quiz_submission_id, attempt, created_at);


--
-- Name: tool_to_assign; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX tool_to_assign ON public.context_external_tool_assignment_lookups USING btree (context_external_tool_id, assignment_id);


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
-- Name: versions_0_versionable_id_versionable_type_number_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX versions_0_versionable_id_versionable_type_number_idx ON public.versions_0 USING btree (versionable_id, versionable_type, number);


--
-- Name: versions_1_versionable_id_versionable_type_number_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX versions_1_versionable_id_versionable_type_number_idx ON public.versions_1 USING btree (versionable_id, versionable_type, number);


--
-- Name: versions_2_versionable_id_versionable_type_number_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX versions_2_versionable_id_versionable_type_number_idx ON public.versions_2 USING btree (versionable_id, versionable_type, number);


--
-- Name: ws_sa; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ws_sa ON public.delayed_messages USING btree (workflow_state, send_at);


--
-- Name: delayed_jobs delayed_jobs_after_delete_row_tr; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER delayed_jobs_after_delete_row_tr AFTER DELETE ON public.delayed_jobs FOR EACH ROW WHEN (((old.strand IS NOT NULL) AND (old.next_in_strand = true))) EXECUTE PROCEDURE delayed_jobs_after_delete_row_tr_fn();


--
-- Name: delayed_jobs delayed_jobs_before_insert_row_tr; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER delayed_jobs_before_insert_row_tr BEFORE INSERT ON public.delayed_jobs FOR EACH ROW WHEN ((new.strand IS NOT NULL)) EXECUTE PROCEDURE delayed_jobs_before_insert_row_tr_fn();


--
-- Name: master_courses_master_templates fk_rails_01b5db190c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY master_courses_master_templates
    ADD CONSTRAINT fk_rails_01b5db190c FOREIGN KEY (course_id) REFERENCES courses(id);


--
-- Name: polling_poll_submissions fk_rails_01fa2ef709; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY polling_poll_submissions
    ADD CONSTRAINT fk_rails_01fa2ef709 FOREIGN KEY (poll_session_id) REFERENCES polling_poll_sessions(id);


--
-- Name: sis_post_grades_statuses fk_rails_0221897d5f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sis_post_grades_statuses
    ADD CONSTRAINT fk_rails_0221897d5f FOREIGN KEY (course_id) REFERENCES courses(id);


--
-- Name: sis_batches fk_rails_0235dd4ff6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sis_batches
    ADD CONSTRAINT fk_rails_0235dd4ff6 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: collaborators fk_rails_02c23caf02; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY collaborators
    ADD CONSTRAINT fk_rails_02c23caf02 FOREIGN KEY (collaboration_id) REFERENCES collaborations(id);


--
-- Name: context_modules fk_rails_03f6fc5c38; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY context_modules
    ADD CONSTRAINT fk_rails_03f6fc5c38 FOREIGN KEY (cloned_item_id) REFERENCES cloned_items(id);


--
-- Name: lti_message_handlers fk_rails_0446c78346; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY lti_message_handlers
    ADD CONSTRAINT fk_rails_0446c78346 FOREIGN KEY (resource_handler_id) REFERENCES lti_resource_handlers(id);


--
-- Name: quiz_submissions fk_rails_04850db4b4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY quiz_submissions
    ADD CONSTRAINT fk_rails_04850db4b4 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: content_migrations fk_rails_04f446621a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY content_migrations
    ADD CONSTRAINT fk_rails_04f446621a FOREIGN KEY (child_subscription_id) REFERENCES master_courses_child_subscriptions(id);


--
-- Name: moderated_grading_selections fk_rails_05e761621e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY moderated_grading_selections
    ADD CONSTRAINT fk_rails_05e761621e FOREIGN KEY (student_id) REFERENCES users(id);


--
-- Name: notification_policies fk_rails_065136b4a1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY notification_policies
    ADD CONSTRAINT fk_rails_065136b4a1 FOREIGN KEY (communication_channel_id) REFERENCES communication_channels(id);


--
-- Name: media_objects fk_rails_06a85e3af6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY media_objects
    ADD CONSTRAINT fk_rails_06a85e3af6 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: sis_post_grades_statuses fk_rails_07ef291b5d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sis_post_grades_statuses
    ADD CONSTRAINT fk_rails_07ef291b5d FOREIGN KEY (course_section_id) REFERENCES course_sections(id);


--
-- Name: content_exports fk_rails_08b467f95d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY content_exports
    ADD CONSTRAINT fk_rails_08b467f95d FOREIGN KEY (attachment_id) REFERENCES attachments(id);


--
-- Name: content_tags fk_rails_0ad9c826f2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY content_tags
    ADD CONSTRAINT fk_rails_0ad9c826f2 FOREIGN KEY (context_module_id) REFERENCES context_modules(id);


--
-- Name: discussion_topics fk_rails_0b0ccee25f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY discussion_topics
    ADD CONSTRAINT fk_rails_0b0ccee25f FOREIGN KEY (group_category_id) REFERENCES group_categories(id);


--
-- Name: calendar_events fk_rails_0e82f26e3c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY calendar_events
    ADD CONSTRAINT fk_rails_0e82f26e3c FOREIGN KEY (parent_calendar_event_id) REFERENCES calendar_events(id);


--
-- Name: canvadocs fk_rails_0e9b385b60; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY canvadocs
    ADD CONSTRAINT fk_rails_0e9b385b60 FOREIGN KEY (attachment_id) REFERENCES attachments(id);


--
-- Name: pseudonyms fk_rails_0f9b2ab873; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY pseudonyms
    ADD CONSTRAINT fk_rails_0f9b2ab873 FOREIGN KEY (account_id) REFERENCES accounts(id);


--
-- Name: page_views_rollups fk_rails_0ff7f19312; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY page_views_rollups
    ADD CONSTRAINT fk_rails_0ff7f19312 FOREIGN KEY (course_id) REFERENCES courses(id);


--
-- Name: submissions fk_rails_11ec1c51e8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY submissions
    ADD CONSTRAINT fk_rails_11ec1c51e8 FOREIGN KEY (group_id) REFERENCES groups(id);


--
-- Name: group_memberships fk_rails_1208c3cc2d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY group_memberships
    ADD CONSTRAINT fk_rails_1208c3cc2d FOREIGN KEY (sis_batch_id) REFERENCES sis_batches(id);


--
-- Name: page_views fk_rails_13a4e75c00; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY page_views
    ADD CONSTRAINT fk_rails_13a4e75c00 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: polling_poll_sessions fk_rails_13d9535afd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY polling_poll_sessions
    ADD CONSTRAINT fk_rails_13d9535afd FOREIGN KEY (course_section_id) REFERENCES course_sections(id);


--
-- Name: master_courses_child_content_tags fk_rails_1421b96805; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY master_courses_child_content_tags
    ADD CONSTRAINT fk_rails_1421b96805 FOREIGN KEY (child_subscription_id) REFERENCES master_courses_child_subscriptions(id);


--
-- Name: group_memberships fk_rails_14271168a1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY group_memberships
    ADD CONSTRAINT fk_rails_14271168a1 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: wiki_pages fk_rails_154906ae4a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY wiki_pages
    ADD CONSTRAINT fk_rails_154906ae4a FOREIGN KEY (cloned_item_id) REFERENCES cloned_items(id);


--
-- Name: courses fk_rails_187ebba5f6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY courses
    ADD CONSTRAINT fk_rails_187ebba5f6 FOREIGN KEY (sis_batch_id) REFERENCES sis_batches(id);


--
-- Name: profiles fk_rails_1c415318fc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY profiles
    ADD CONSTRAINT fk_rails_1c415318fc FOREIGN KEY (root_account_id) REFERENCES accounts(id);


--
-- Name: bookmarks_bookmarks fk_rails_1c845e4204; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bookmarks_bookmarks
    ADD CONSTRAINT fk_rails_1c845e4204 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: discussion_topics fk_rails_1d19e2eea5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY discussion_topics
    ADD CONSTRAINT fk_rails_1d19e2eea5 FOREIGN KEY (external_feed_id) REFERENCES external_feeds(id);


--
-- Name: migration_issues fk_rails_1d79ad9705; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY migration_issues
    ADD CONSTRAINT fk_rails_1d79ad9705 FOREIGN KEY (content_migration_id) REFERENCES content_migrations(id);


--
-- Name: account_reports fk_rails_1ee483dd34; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY account_reports
    ADD CONSTRAINT fk_rails_1ee483dd34 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: polling_poll_submissions fk_rails_21612c7e9a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY polling_poll_submissions
    ADD CONSTRAINT fk_rails_21612c7e9a FOREIGN KEY (poll_choice_id) REFERENCES polling_poll_choices(id);


--
-- Name: learning_outcome_groups fk_rails_2359cb17b0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY learning_outcome_groups
    ADD CONSTRAINT fk_rails_2359cb17b0 FOREIGN KEY (root_learning_outcome_group_id) REFERENCES learning_outcome_groups(id);


--
-- Name: quiz_submission_events_2019_4 fk_rails_23bbda5091; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY quiz_submission_events_2019_4
    ADD CONSTRAINT fk_rails_23bbda5091 FOREIGN KEY (quiz_submission_id) REFERENCES quiz_submissions(id);


--
-- Name: enrollment_states fk_rails_2583b53a28; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY enrollment_states
    ADD CONSTRAINT fk_rails_2583b53a28 FOREIGN KEY (enrollment_id) REFERENCES enrollments(id);


--
-- Name: media_objects fk_rails_25b24c5e66; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY media_objects
    ADD CONSTRAINT fk_rails_25b24c5e66 FOREIGN KEY (root_account_id) REFERENCES accounts(id);


--
-- Name: polling_polls fk_rails_2742c5bc84; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY polling_polls
    ADD CONSTRAINT fk_rails_2742c5bc84 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: context_external_tools fk_rails_27d8c7c29b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY context_external_tools
    ADD CONSTRAINT fk_rails_27d8c7c29b FOREIGN KEY (cloned_item_id) REFERENCES cloned_items(id);


--
-- Name: sis_batches fk_rails_289263ccc7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sis_batches
    ADD CONSTRAINT fk_rails_289263ccc7 FOREIGN KEY (errors_attachment_id) REFERENCES attachments(id);


--
-- Name: assignments fk_rails_289e40e18c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY assignments
    ADD CONSTRAINT fk_rails_289e40e18c FOREIGN KEY (cloned_item_id) REFERENCES cloned_items(id);


--
-- Name: discussion_entries fk_rails_2a02569030; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY discussion_entries
    ADD CONSTRAINT fk_rails_2a02569030 FOREIGN KEY (root_entry_id) REFERENCES discussion_entries(id);


--
-- Name: quiz_submission_events fk_rails_2d873134e2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY quiz_submission_events
    ADD CONSTRAINT fk_rails_2d873134e2 FOREIGN KEY (quiz_submission_id) REFERENCES quiz_submissions(id);


--
-- Name: assignment_groups fk_rails_2d906abe72; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY assignment_groups
    ADD CONSTRAINT fk_rails_2d906abe72 FOREIGN KEY (cloned_item_id) REFERENCES cloned_items(id);


--
-- Name: enrollments fk_rails_2e119501f4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY enrollments
    ADD CONSTRAINT fk_rails_2e119501f4 FOREIGN KEY (course_id) REFERENCES courses(id);


--
-- Name: abstract_courses fk_rails_3077d9a014; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY abstract_courses
    ADD CONSTRAINT fk_rails_3077d9a014 FOREIGN KEY (root_account_id) REFERENCES accounts(id);


--
-- Name: planner_notes fk_rails_3255427de8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY planner_notes
    ADD CONSTRAINT fk_rails_3255427de8 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: assessment_requests fk_rails_33d90b7c30; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY assessment_requests
    ADD CONSTRAINT fk_rails_33d90b7c30 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: discussion_topic_materialized_views fk_rails_34dd2d679a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY discussion_topic_materialized_views
    ADD CONSTRAINT fk_rails_34dd2d679a FOREIGN KEY (discussion_topic_id) REFERENCES discussion_topics(id);


--
-- Name: learning_outcome_groups fk_rails_34f901d115; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY learning_outcome_groups
    ADD CONSTRAINT fk_rails_34f901d115 FOREIGN KEY (learning_outcome_group_id) REFERENCES learning_outcome_groups(id);


--
-- Name: enrollment_dates_overrides fk_rails_356b7d0ddc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY enrollment_dates_overrides
    ADD CONSTRAINT fk_rails_356b7d0ddc FOREIGN KEY (enrollment_term_id) REFERENCES enrollment_terms(id);


--
-- Name: originality_reports fk_rails_36c981e3e7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY originality_reports
    ADD CONSTRAINT fk_rails_36c981e3e7 FOREIGN KEY (submission_id) REFERENCES submissions(id);


--
-- Name: grading_standards fk_rails_38b90db7a8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY grading_standards
    ADD CONSTRAINT fk_rails_38b90db7a8 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: discussion_topic_participants fk_rails_3b8c3c44d8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY discussion_topic_participants
    ADD CONSTRAINT fk_rails_3b8c3c44d8 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: groups fk_rails_3c368b24c7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY groups
    ADD CONSTRAINT fk_rails_3c368b24c7 FOREIGN KEY (leader_id) REFERENCES users(id);


--
-- Name: epub_exports fk_rails_3c608dd796; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY epub_exports
    ADD CONSTRAINT fk_rails_3c608dd796 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: delayed_messages fk_rails_3d428ac9f1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY delayed_messages
    ADD CONSTRAINT fk_rails_3d428ac9f1 FOREIGN KEY (communication_channel_id) REFERENCES communication_channels(id);


--
-- Name: collaborators fk_rails_3d4aaacbb1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY collaborators
    ADD CONSTRAINT fk_rails_3d4aaacbb1 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: collaborations fk_rails_3e8ae0af8a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY collaborations
    ADD CONSTRAINT fk_rails_3e8ae0af8a FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: shared_brand_configs fk_rails_3f25f5e6fa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY shared_brand_configs
    ADD CONSTRAINT fk_rails_3f25f5e6fa FOREIGN KEY (account_id) REFERENCES accounts(id);


--
-- Name: assessment_requests fk_rails_400dc27246; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY assessment_requests
    ADD CONSTRAINT fk_rails_400dc27246 FOREIGN KEY (asset_id) REFERENCES submissions(id);


--
-- Name: courses fk_rails_4309898d02; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY courses
    ADD CONSTRAINT fk_rails_4309898d02 FOREIGN KEY (wiki_id) REFERENCES wikis(id);


--
-- Name: role_overrides fk_rails_4412996802; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY role_overrides
    ADD CONSTRAINT fk_rails_4412996802 FOREIGN KEY (role_id) REFERENCES roles(id);


--
-- Name: context_external_tool_assignment_lookups fk_rails_445c77bd4c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY context_external_tool_assignment_lookups
    ADD CONSTRAINT fk_rails_445c77bd4c FOREIGN KEY (assignment_id) REFERENCES assignments(id);


--
-- Name: learning_outcome_results fk_rails_453d9421c4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY learning_outcome_results
    ADD CONSTRAINT fk_rails_453d9421c4 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: user_merge_data_records fk_rails_4579cd8750; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_merge_data_records
    ADD CONSTRAINT fk_rails_4579cd8750 FOREIGN KEY (user_merge_data_id) REFERENCES user_merge_data(id);


--
-- Name: moderated_grading_provisional_grades fk_rails_46d61d78e3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY moderated_grading_provisional_grades
    ADD CONSTRAINT fk_rails_46d61d78e3 FOREIGN KEY (scorer_id) REFERENCES users(id);


--
-- Name: content_migrations fk_rails_471c20026b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY content_migrations
    ADD CONSTRAINT fk_rails_471c20026b FOREIGN KEY (overview_attachment_id) REFERENCES attachments(id);


--
-- Name: quiz_submissions fk_rails_473863d022; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY quiz_submissions
    ADD CONSTRAINT fk_rails_473863d022 FOREIGN KEY (quiz_id) REFERENCES quizzes(id);


--
-- Name: eportfolio_entries fk_rails_482dbada33; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY eportfolio_entries
    ADD CONSTRAINT fk_rails_482dbada33 FOREIGN KEY (eportfolio_category_id) REFERENCES eportfolio_categories(id);


--
-- Name: master_courses_master_migrations fk_rails_48befa8db6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY master_courses_master_migrations
    ADD CONSTRAINT fk_rails_48befa8db6 FOREIGN KEY (master_template_id) REFERENCES master_courses_master_templates(id);


--
-- Name: user_merge_data fk_rails_4993c3792e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_merge_data
    ADD CONSTRAINT fk_rails_4993c3792e FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: course_sections fk_rails_4a0eb6ebbb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY course_sections
    ADD CONSTRAINT fk_rails_4a0eb6ebbb FOREIGN KEY (root_account_id) REFERENCES accounts(id);


--
-- Name: discussion_topics fk_rails_4aac5d137c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY discussion_topics
    ADD CONSTRAINT fk_rails_4aac5d137c FOREIGN KEY (root_topic_id) REFERENCES discussion_topics(id);


--
-- Name: eportfolios fk_rails_4c2dbd440f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY eportfolios
    ADD CONSTRAINT fk_rails_4c2dbd440f FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: quiz_regrades fk_rails_4cf8b252f4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY quiz_regrades
    ADD CONSTRAINT fk_rails_4cf8b252f4 FOREIGN KEY (quiz_id) REFERENCES quizzes(id);


--
-- Name: gradebook_csvs fk_rails_4d8cd84eb3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gradebook_csvs
    ADD CONSTRAINT fk_rails_4d8cd84eb3 FOREIGN KEY (progress_id) REFERENCES progresses(id);


--
-- Name: course_account_associations fk_rails_4e21d15465; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY course_account_associations
    ADD CONSTRAINT fk_rails_4e21d15465 FOREIGN KEY (course_id) REFERENCES courses(id);


--
-- Name: gradebook_uploads fk_rails_4e38efab60; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gradebook_uploads
    ADD CONSTRAINT fk_rails_4e38efab60 FOREIGN KEY (progress_id) REFERENCES progresses(id);


--
-- Name: quiz_statistics fk_rails_4e39b123dd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY quiz_statistics
    ADD CONSTRAINT fk_rails_4e39b123dd FOREIGN KEY (quiz_id) REFERENCES quizzes(id);


--
-- Name: user_observers fk_rails_506aea5479; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_observers
    ADD CONSTRAINT fk_rails_506aea5479 FOREIGN KEY (observer_id) REFERENCES users(id);


--
-- Name: enrollment_terms fk_rails_51e8498073; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY enrollment_terms
    ADD CONSTRAINT fk_rails_51e8498073 FOREIGN KEY (grading_period_group_id) REFERENCES grading_period_groups(id);


--
-- Name: assignment_override_students fk_rails_5215564217; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY assignment_override_students
    ADD CONSTRAINT fk_rails_5215564217 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: polling_poll_sessions fk_rails_52ebcb3ce8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY polling_poll_sessions
    ADD CONSTRAINT fk_rails_52ebcb3ce8 FOREIGN KEY (course_id) REFERENCES courses(id);


--
-- Name: enrollments fk_rails_56c4ec50d6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY enrollments
    ADD CONSTRAINT fk_rails_56c4ec50d6 FOREIGN KEY (sis_batch_id) REFERENCES sis_batches(id);


--
-- Name: custom_gradebook_columns fk_rails_571a48e40d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY custom_gradebook_columns
    ADD CONSTRAINT fk_rails_571a48e40d FOREIGN KEY (course_id) REFERENCES courses(id);


--
-- Name: lti_tool_proxies fk_rails_57f8b9857d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY lti_tool_proxies
    ADD CONSTRAINT fk_rails_57f8b9857d FOREIGN KEY (product_family_id) REFERENCES lti_product_families(id);


--
-- Name: pseudonyms fk_rails_587e86bf60; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY pseudonyms
    ADD CONSTRAINT fk_rails_587e86bf60 FOREIGN KEY (authentication_provider_id) REFERENCES account_authorization_configs(id);


--
-- Name: quiz_submission_events_2019_3 fk_rails_5889aa933d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY quiz_submission_events_2019_3
    ADD CONSTRAINT fk_rails_5889aa933d FOREIGN KEY (quiz_submission_id) REFERENCES quiz_submissions(id);


--
-- Name: account_reports fk_rails_58e7f750a2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY account_reports
    ADD CONSTRAINT fk_rails_58e7f750a2 FOREIGN KEY (attachment_id) REFERENCES attachments(id);


--
-- Name: assignment_overrides fk_rails_58f8ee369b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY assignment_overrides
    ADD CONSTRAINT fk_rails_58f8ee369b FOREIGN KEY (assignment_id) REFERENCES assignments(id);


--
-- Name: account_notification_roles fk_rails_5948b12a95; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY account_notification_roles
    ADD CONSTRAINT fk_rails_5948b12a95 FOREIGN KEY (account_notification_id) REFERENCES account_notifications(id);


--
-- Name: sis_batches fk_rails_5cc4e38775; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sis_batches
    ADD CONSTRAINT fk_rails_5cc4e38775 FOREIGN KEY (batch_mode_term_id) REFERENCES enrollment_terms(id);


--
-- Name: submissions fk_rails_5d48b8a034; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY submissions
    ADD CONSTRAINT fk_rails_5d48b8a034 FOREIGN KEY (media_object_id) REFERENCES media_objects(id);


--
-- Name: accounts fk_rails_5de7ad5dec; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY accounts
    ADD CONSTRAINT fk_rails_5de7ad5dec FOREIGN KEY (root_account_id) REFERENCES accounts(id);


--
-- Name: web_conference_participants fk_rails_5e4063e908; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY web_conference_participants
    ADD CONSTRAINT fk_rails_5e4063e908 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: planner_overrides fk_rails_5fa99aedd0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY planner_overrides
    ADD CONSTRAINT fk_rails_5fa99aedd0 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: gradebook_csvs fk_rails_60f1713674; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gradebook_csvs
    ADD CONSTRAINT fk_rails_60f1713674 FOREIGN KEY (course_id) REFERENCES courses(id);


--
-- Name: course_sections fk_rails_616bd9cbd0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY course_sections
    ADD CONSTRAINT fk_rails_616bd9cbd0 FOREIGN KEY (course_id) REFERENCES courses(id);


--
-- Name: submissions fk_rails_61cac0823d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY submissions
    ADD CONSTRAINT fk_rails_61cac0823d FOREIGN KEY (assignment_id) REFERENCES assignments(id);


--
-- Name: groups fk_rails_61d69a1dcf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY groups
    ADD CONSTRAINT fk_rails_61d69a1dcf FOREIGN KEY (sis_batch_id) REFERENCES sis_batches(id);


--
-- Name: live_assessments_results fk_rails_61dcfeb426; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY live_assessments_results
    ADD CONSTRAINT fk_rails_61dcfeb426 FOREIGN KEY (assessment_id) REFERENCES live_assessments_assessments(id);


--
-- Name: accounts fk_rails_630eca7263; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY accounts
    ADD CONSTRAINT fk_rails_630eca7263 FOREIGN KEY (sis_batch_id) REFERENCES sis_batches(id);


--
-- Name: enrollments fk_rails_6359366b63; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY enrollments
    ADD CONSTRAINT fk_rails_6359366b63 FOREIGN KEY (associated_user_id) REFERENCES users(id);


--
-- Name: content_exports fk_rails_6364a4a05e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY content_exports
    ADD CONSTRAINT fk_rails_6364a4a05e FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: oauth_requests fk_rails_6471c0c593; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY oauth_requests
    ADD CONSTRAINT fk_rails_6471c0c593 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: quiz_submission_events_2018_12 fk_rails_64a1536925; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY quiz_submission_events_2018_12
    ADD CONSTRAINT fk_rails_64a1536925 FOREIGN KEY (quiz_submission_id) REFERENCES quiz_submissions(id);


--
-- Name: web_conference_participants fk_rails_652989382e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY web_conference_participants
    ADD CONSTRAINT fk_rails_652989382e FOREIGN KEY (web_conference_id) REFERENCES web_conferences(id);


--
-- Name: shared_brand_configs fk_rails_669597e153; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY shared_brand_configs
    ADD CONSTRAINT fk_rails_669597e153 FOREIGN KEY (brand_config_md5) REFERENCES brand_configs(md5);


--
-- Name: discussion_topics fk_rails_6791d1877c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY discussion_topics
    ADD CONSTRAINT fk_rails_6791d1877c FOREIGN KEY (old_assignment_id) REFERENCES assignments(id);


--
-- Name: account_users fk_rails_685e030c15; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY account_users
    ADD CONSTRAINT fk_rails_685e030c15 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: master_courses_master_templates fk_rails_69a6430b11; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY master_courses_master_templates
    ADD CONSTRAINT fk_rails_69a6430b11 FOREIGN KEY (active_migration_id) REFERENCES master_courses_master_migrations(id);


--
-- Name: submission_comments fk_rails_6a44347cb4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY submission_comments
    ADD CONSTRAINT fk_rails_6a44347cb4 FOREIGN KEY (provisional_grade_id) REFERENCES moderated_grading_provisional_grades(id);


--
-- Name: user_observers fk_rails_6e626831b8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_observers
    ADD CONSTRAINT fk_rails_6e626831b8 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: cached_grade_distributions fk_rails_6f9ee01cc7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cached_grade_distributions
    ADD CONSTRAINT fk_rails_6f9ee01cc7 FOREIGN KEY (course_id) REFERENCES courses(id);


--
-- Name: grading_period_groups fk_rails_712c487e43; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY grading_period_groups
    ADD CONSTRAINT fk_rails_712c487e43 FOREIGN KEY (account_id) REFERENCES accounts(id);


--
-- Name: course_account_associations fk_rails_7225a78aa5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY course_account_associations
    ADD CONSTRAINT fk_rails_7225a78aa5 FOREIGN KEY (course_section_id) REFERENCES course_sections(id);


--
-- Name: originality_reports fk_rails_72d6122dfb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY originality_reports
    ADD CONSTRAINT fk_rails_72d6122dfb FOREIGN KEY (originality_report_attachment_id) REFERENCES attachments(id);


--
-- Name: context_module_progressions fk_rails_736970326a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY context_module_progressions
    ADD CONSTRAINT fk_rails_736970326a FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: content_tags fk_rails_7376a606b8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY content_tags
    ADD CONSTRAINT fk_rails_7376a606b8 FOREIGN KEY (cloned_item_id) REFERENCES cloned_items(id);


--
-- Name: assignment_configuration_tool_lookups fk_rails_73f7ea9f92; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY assignment_configuration_tool_lookups
    ADD CONSTRAINT fk_rails_73f7ea9f92 FOREIGN KEY (assignment_id) REFERENCES assignments(id);


--
-- Name: wiki_pages fk_rails_74a0fa180b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY wiki_pages
    ADD CONSTRAINT fk_rails_74a0fa180b FOREIGN KEY (assignment_id) REFERENCES assignments(id);


--
-- Name: stream_item_instances fk_rails_75522c5fd3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY stream_item_instances
    ADD CONSTRAINT fk_rails_75522c5fd3 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: calendar_events fk_rails_75957d2da8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY calendar_events
    ADD CONSTRAINT fk_rails_75957d2da8 FOREIGN KEY (cloned_item_id) REFERENCES cloned_items(id);


--
-- Name: live_assessments_results fk_rails_768405ee04; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY live_assessments_results
    ADD CONSTRAINT fk_rails_768405ee04 FOREIGN KEY (assessor_id) REFERENCES users(id);


--
-- Name: external_feeds fk_rails_7727e39b38; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY external_feeds
    ADD CONSTRAINT fk_rails_7727e39b38 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: user_account_associations fk_rails_77e6070def; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_account_associations
    ADD CONSTRAINT fk_rails_77e6070def FOREIGN KEY (account_id) REFERENCES accounts(id);


--
-- Name: page_comments fk_rails_78ced27005; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY page_comments
    ADD CONSTRAINT fk_rails_78ced27005 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: account_notification_roles fk_rails_794b06ff0e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY account_notification_roles
    ADD CONSTRAINT fk_rails_794b06ff0e FOREIGN KEY (role_id) REFERENCES roles(id);


--
-- Name: epub_exports fk_rails_7b64484d53; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY epub_exports
    ADD CONSTRAINT fk_rails_7b64484d53 FOREIGN KEY (content_export_id) REFERENCES content_exports(id);


--
-- Name: roles fk_rails_7c71253d78; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY roles
    ADD CONSTRAINT fk_rails_7c71253d78 FOREIGN KEY (account_id) REFERENCES accounts(id);


--
-- Name: lti_resource_handlers fk_rails_7cca6549c4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY lti_resource_handlers
    ADD CONSTRAINT fk_rails_7cca6549c4 FOREIGN KEY (tool_proxy_id) REFERENCES lti_tool_proxies(id);


--
-- Name: roles fk_rails_7d4ded04e1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY roles
    ADD CONSTRAINT fk_rails_7d4ded04e1 FOREIGN KEY (root_account_id) REFERENCES accounts(id);


--
-- Name: course_account_associations fk_rails_7d50d15200; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY course_account_associations
    ADD CONSTRAINT fk_rails_7d50d15200 FOREIGN KEY (account_id) REFERENCES accounts(id);


--
-- Name: groups fk_rails_7d60528287; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY groups
    ADD CONSTRAINT fk_rails_7d60528287 FOREIGN KEY (root_account_id) REFERENCES accounts(id);


--
-- Name: quiz_regrades fk_rails_8116556edd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY quiz_regrades
    ADD CONSTRAINT fk_rails_8116556edd FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: delayed_messages fk_rails_81d84c7a3d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY delayed_messages
    ADD CONSTRAINT fk_rails_81d84c7a3d FOREIGN KEY (notification_policy_id) REFERENCES notification_policies(id);


--
-- Name: epub_exports fk_rails_8229c54d0d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY epub_exports
    ADD CONSTRAINT fk_rails_8229c54d0d FOREIGN KEY (course_id) REFERENCES courses(id);


--
-- Name: master_courses_child_subscriptions fk_rails_831debb6b9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY master_courses_child_subscriptions
    ADD CONSTRAINT fk_rails_831debb6b9 FOREIGN KEY (master_template_id) REFERENCES master_courses_master_templates(id);


--
-- Name: discussion_entries fk_rails_846fecac98; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY discussion_entries
    ADD CONSTRAINT fk_rails_846fecac98 FOREIGN KEY (editor_id) REFERENCES users(id);


--
-- Name: role_overrides fk_rails_8571d0f354; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY role_overrides
    ADD CONSTRAINT fk_rails_8571d0f354 FOREIGN KEY (context_id) REFERENCES accounts(id);


--
-- Name: account_reports fk_rails_865683f386; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY account_reports
    ADD CONSTRAINT fk_rails_865683f386 FOREIGN KEY (account_id) REFERENCES accounts(id);


--
-- Name: discussion_entry_participants fk_rails_86a01cf993; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY discussion_entry_participants
    ADD CONSTRAINT fk_rails_86a01cf993 FOREIGN KEY (discussion_entry_id) REFERENCES discussion_entries(id);


--
-- Name: sis_post_grades_statuses fk_rails_870e38a0e6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sis_post_grades_statuses
    ADD CONSTRAINT fk_rails_870e38a0e6 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: user_profiles fk_rails_87a6352e58; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_profiles
    ADD CONSTRAINT fk_rails_87a6352e58 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: abstract_courses fk_rails_87ef57da5a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY abstract_courses
    ADD CONSTRAINT fk_rails_87ef57da5a FOREIGN KEY (enrollment_term_id) REFERENCES enrollment_terms(id);


--
-- Name: course_sections fk_rails_88559b4f6d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY course_sections
    ADD CONSTRAINT fk_rails_88559b4f6d FOREIGN KEY (enrollment_term_id) REFERENCES enrollment_terms(id);


--
-- Name: polling_poll_submissions fk_rails_8993f10747; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY polling_poll_submissions
    ADD CONSTRAINT fk_rails_8993f10747 FOREIGN KEY (poll_id) REFERENCES polling_polls(id);


--
-- Name: discussion_entries fk_rails_8a7187368b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY discussion_entries
    ADD CONSTRAINT fk_rails_8a7187368b FOREIGN KEY (parent_id) REFERENCES discussion_entries(id);


--
-- Name: master_courses_migration_results fk_rails_8a84ef8416; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY master_courses_migration_results
    ADD CONSTRAINT fk_rails_8a84ef8416 FOREIGN KEY (master_migration_id) REFERENCES master_courses_master_migrations(id);


--
-- Name: submissions fk_rails_8d85741475; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY submissions
    ADD CONSTRAINT fk_rails_8d85741475 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: user_account_associations fk_rails_8ec6f29c88; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_account_associations
    ADD CONSTRAINT fk_rails_8ec6f29c88 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: courses fk_rails_8f8adab10c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY courses
    ADD CONSTRAINT fk_rails_8f8adab10c FOREIGN KEY (root_account_id) REFERENCES accounts(id);


--
-- Name: ignores fk_rails_9089e0c809; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ignores
    ADD CONSTRAINT fk_rails_9089e0c809 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: live_assessments_submissions fk_rails_924ff0872d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY live_assessments_submissions
    ADD CONSTRAINT fk_rails_924ff0872d FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: master_courses_master_content_tags fk_rails_925590350a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY master_courses_master_content_tags
    ADD CONSTRAINT fk_rails_925590350a FOREIGN KEY (master_template_id) REFERENCES master_courses_master_templates(id);


--
-- Name: calendar_events fk_rails_930e3c0bf4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY calendar_events
    ADD CONSTRAINT fk_rails_930e3c0bf4 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: account_authorization_configs fk_rails_94e00def24; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY account_authorization_configs
    ADD CONSTRAINT fk_rails_94e00def24 FOREIGN KEY (account_id) REFERENCES accounts(id);


--
-- Name: master_courses_child_subscriptions fk_rails_95aad9cf8d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY master_courses_child_subscriptions
    ADD CONSTRAINT fk_rails_95aad9cf8d FOREIGN KEY (child_course_id) REFERENCES courses(id);


--
-- Name: access_tokens fk_rails_96fc070778; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY access_tokens
    ADD CONSTRAINT fk_rails_96fc070778 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: report_snapshots fk_rails_983ad88e61; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY report_snapshots
    ADD CONSTRAINT fk_rails_983ad88e61 FOREIGN KEY (account_id) REFERENCES accounts(id);


--
-- Name: discussion_topics fk_rails_98edc2f77e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY discussion_topics
    ADD CONSTRAINT fk_rails_98edc2f77e FOREIGN KEY (assignment_id) REFERENCES assignments(id);


--
-- Name: conversation_message_participants fk_rails_992a8b9e13; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY conversation_message_participants
    ADD CONSTRAINT fk_rails_992a8b9e13 FOREIGN KEY (conversation_message_id) REFERENCES conversation_messages(id);


--
-- Name: discussion_topics fk_rails_99a031cbb1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY discussion_topics
    ADD CONSTRAINT fk_rails_99a031cbb1 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: wiki_pages fk_rails_9a0e88e669; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY wiki_pages
    ADD CONSTRAINT fk_rails_9a0e88e669 FOREIGN KEY (old_assignment_id) REFERENCES assignments(id);


--
-- Name: account_notifications fk_rails_9a3f0df4a1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY account_notifications
    ADD CONSTRAINT fk_rails_9a3f0df4a1 FOREIGN KEY (account_id) REFERENCES accounts(id);


--
-- Name: discussion_entries fk_rails_9b275b5da7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY discussion_entries
    ADD CONSTRAINT fk_rails_9b275b5da7 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: discussion_topics fk_rails_9b3acbc3f8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY discussion_topics
    ADD CONSTRAINT fk_rails_9b3acbc3f8 FOREIGN KEY (attachment_id) REFERENCES attachments(id);


--
-- Name: lti_tool_proxy_bindings fk_rails_9b5d93b5c3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY lti_tool_proxy_bindings
    ADD CONSTRAINT fk_rails_9b5d93b5c3 FOREIGN KEY (tool_proxy_id) REFERENCES lti_tool_proxies(id);


--
-- Name: pseudonyms fk_rails_9b98a5d814; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY pseudonyms
    ADD CONSTRAINT fk_rails_9b98a5d814 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: user_notes fk_rails_9bcd528c60; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_notes
    ADD CONSTRAINT fk_rails_9bcd528c60 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: content_migrations fk_rails_9bdc9d1482; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY content_migrations
    ADD CONSTRAINT fk_rails_9bdc9d1482 FOREIGN KEY (attachment_id) REFERENCES attachments(id);


--
-- Name: abstract_courses fk_rails_9c92877701; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY abstract_courses
    ADD CONSTRAINT fk_rails_9c92877701 FOREIGN KEY (sis_batch_id) REFERENCES sis_batches(id);


--
-- Name: sis_batch_error_files fk_rails_9cbb444c5f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sis_batch_error_files
    ADD CONSTRAINT fk_rails_9cbb444c5f FOREIGN KEY (sis_batch_id) REFERENCES sis_batches(id);


--
-- Name: context_module_progressions fk_rails_9cc1157b30; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY context_module_progressions
    ADD CONSTRAINT fk_rails_9cc1157b30 FOREIGN KEY (context_module_id) REFERENCES context_modules(id);


--
-- Name: grading_periods fk_rails_9cc118401a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY grading_periods
    ADD CONSTRAINT fk_rails_9cc118401a FOREIGN KEY (grading_period_group_id) REFERENCES grading_period_groups(id);


--
-- Name: submissions fk_rails_9e3ddda320; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY submissions
    ADD CONSTRAINT fk_rails_9e3ddda320 FOREIGN KEY (grading_period_id) REFERENCES grading_periods(id);


--
-- Name: rubric_associations fk_rails_9e5239a751; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY rubric_associations
    ADD CONSTRAINT fk_rails_9e5239a751 FOREIGN KEY (rubric_id) REFERENCES rubrics(id);


--
-- Name: folders fk_rails_9f43470a04; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY folders
    ADD CONSTRAINT fk_rails_9f43470a04 FOREIGN KEY (parent_folder_id) REFERENCES folders(id);


--
-- Name: quizzes fk_rails_9f9beaf05c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY quizzes
    ADD CONSTRAINT fk_rails_9f9beaf05c FOREIGN KEY (assignment_id) REFERENCES assignments(id);


--
-- Name: assignment_override_students fk_rails_9ffe0aa305; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY assignment_override_students
    ADD CONSTRAINT fk_rails_9ffe0aa305 FOREIGN KEY (assignment_id) REFERENCES assignments(id);


--
-- Name: learning_outcome_results fk_rails_a093f5ae6a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY learning_outcome_results
    ADD CONSTRAINT fk_rails_a093f5ae6a FOREIGN KEY (learning_outcome_id) REFERENCES learning_outcomes(id);


--
-- Name: content_participations fk_rails_a223bf6cde; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY content_participations
    ADD CONSTRAINT fk_rails_a223bf6cde FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: polling_poll_submissions fk_rails_a327cfe658; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY polling_poll_submissions
    ADD CONSTRAINT fk_rails_a327cfe658 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: eportfolio_entries fk_rails_a3aa9184de; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY eportfolio_entries
    ADD CONSTRAINT fk_rails_a3aa9184de FOREIGN KEY (eportfolio_id) REFERENCES eportfolios(id);


--
-- Name: moderated_grading_selections fk_rails_a4904a6da8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY moderated_grading_selections
    ADD CONSTRAINT fk_rails_a4904a6da8 FOREIGN KEY (selected_provisional_grade_id) REFERENCES moderated_grading_provisional_grades(id);


--
-- Name: rubric_assessments fk_rails_a502a63cbe; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY rubric_assessments
    ADD CONSTRAINT fk_rails_a502a63cbe FOREIGN KEY (assessor_id) REFERENCES users(id);


--
-- Name: submission_comments fk_rails_a62b09d198; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY submission_comments
    ADD CONSTRAINT fk_rails_a62b09d198 FOREIGN KEY (author_id) REFERENCES users(id);


--
-- Name: scores fk_rails_a8b66a0a6e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY scores
    ADD CONSTRAINT fk_rails_a8b66a0a6e FOREIGN KEY (enrollment_id) REFERENCES enrollments(id);


--
-- Name: rubrics fk_rails_aa80454086; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY rubrics
    ADD CONSTRAINT fk_rails_aa80454086 FOREIGN KEY (rubric_id) REFERENCES rubrics(id);


--
-- Name: pseudonyms fk_rails_aabcbf9874; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY pseudonyms
    ADD CONSTRAINT fk_rails_aabcbf9874 FOREIGN KEY (sis_batch_id) REFERENCES sis_batches(id);


--
-- Name: page_views fk_rails_ab13cc7e9a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY page_views
    ADD CONSTRAINT fk_rails_ab13cc7e9a FOREIGN KEY (real_user_id) REFERENCES users(id);


--
-- Name: eportfolio_categories fk_rails_ab14eddd76; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY eportfolio_categories
    ADD CONSTRAINT fk_rails_ab14eddd76 FOREIGN KEY (eportfolio_id) REFERENCES eportfolios(id);


--
-- Name: lti_tool_consumer_profiles fk_rails_acb13d57c3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY lti_tool_consumer_profiles
    ADD CONSTRAINT fk_rails_acb13d57c3 FOREIGN KEY (developer_key_id) REFERENCES developer_keys(id);


--
-- Name: sis_batch_error_files fk_rails_acbeaca29c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sis_batch_error_files
    ADD CONSTRAINT fk_rails_acbeaca29c FOREIGN KEY (attachment_id) REFERENCES attachments(id);


--
-- Name: wiki_pages fk_rails_adcd926cb8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY wiki_pages
    ADD CONSTRAINT fk_rails_adcd926cb8 FOREIGN KEY (wiki_id) REFERENCES wikis(id);


--
-- Name: accounts fk_rails_add3a59cd7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY accounts
    ADD CONSTRAINT fk_rails_add3a59cd7 FOREIGN KEY (parent_account_id) REFERENCES accounts(id);


--
-- Name: master_courses_master_content_tags fk_rails_af398d5991; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY master_courses_master_content_tags
    ADD CONSTRAINT fk_rails_af398d5991 FOREIGN KEY (current_migration_id) REFERENCES master_courses_master_migrations(id);


--
-- Name: moderated_grading_provisional_grades fk_rails_afa87e4ebc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY moderated_grading_provisional_grades
    ADD CONSTRAINT fk_rails_afa87e4ebc FOREIGN KEY (submission_id) REFERENCES submissions(id);


--
-- Name: one_time_passwords fk_rails_afd10ae0cb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY one_time_passwords
    ADD CONSTRAINT fk_rails_afd10ae0cb FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: custom_gradebook_column_data fk_rails_b2d446b0b0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY custom_gradebook_column_data
    ADD CONSTRAINT fk_rails_b2d446b0b0 FOREIGN KEY (custom_gradebook_column_id) REFERENCES custom_gradebook_columns(id);


--
-- Name: gradebook_csvs fk_rails_b4531da5e9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gradebook_csvs
    ADD CONSTRAINT fk_rails_b4531da5e9 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: grading_period_groups fk_rails_b4ea3168bc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY grading_period_groups
    ADD CONSTRAINT fk_rails_b4ea3168bc FOREIGN KEY (course_id) REFERENCES courses(id);


--
-- Name: user_notes fk_rails_b5a898af1b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_notes
    ADD CONSTRAINT fk_rails_b5a898af1b FOREIGN KEY (created_by_id) REFERENCES users(id);


--
-- Name: rubrics fk_rails_b5b6f45923; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY rubrics
    ADD CONSTRAINT fk_rails_b5b6f45923 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: attachments fk_rails_b6a31db404; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY attachments
    ADD CONSTRAINT fk_rails_b6a31db404 FOREIGN KEY (root_attachment_id) REFERENCES attachments(id);


--
-- Name: attachments fk_rails_b7c6788fce; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY attachments
    ADD CONSTRAINT fk_rails_b7c6788fce FOREIGN KEY (replacement_attachment_id) REFERENCES attachments(id);


--
-- Name: master_courses_migration_results fk_rails_ba9413706c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY master_courses_migration_results
    ADD CONSTRAINT fk_rails_ba9413706c FOREIGN KEY (child_subscription_id) REFERENCES master_courses_child_subscriptions(id);


--
-- Name: collaborators fk_rails_baeba1010a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY collaborators
    ADD CONSTRAINT fk_rails_baeba1010a FOREIGN KEY (group_id) REFERENCES groups(id);


--
-- Name: scores fk_rails_baf45f32a0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY scores
    ADD CONSTRAINT fk_rails_baf45f32a0 FOREIGN KEY (grading_period_id) REFERENCES grading_periods(id);


--
-- Name: enrollments fk_rails_bbf3738e95; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY enrollments
    ADD CONSTRAINT fk_rails_bbf3738e95 FOREIGN KEY (course_section_id) REFERENCES course_sections(id);


--
-- Name: custom_gradebook_column_data fk_rails_bc039f962e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY custom_gradebook_column_data
    ADD CONSTRAINT fk_rails_bc039f962e FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: moderated_grading_selections fk_rails_bc609b6673; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY moderated_grading_selections
    ADD CONSTRAINT fk_rails_bc609b6673 FOREIGN KEY (assignment_id) REFERENCES assignments(id);


--
-- Name: assignment_overrides fk_rails_bc94d484ff; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY assignment_overrides
    ADD CONSTRAINT fk_rails_bc94d484ff FOREIGN KEY (quiz_id) REFERENCES quizzes(id);


--
-- Name: assignments fk_rails_be38f24036; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY assignments
    ADD CONSTRAINT fk_rails_be38f24036 FOREIGN KEY (group_category_id) REFERENCES group_categories(id);


--
-- Name: content_exports fk_rails_be83a37440; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY content_exports
    ADD CONSTRAINT fk_rails_be83a37440 FOREIGN KEY (content_migration_id) REFERENCES content_migrations(id);


--
-- Name: content_migrations fk_rails_c1bf6cc5e9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY content_migrations
    ADD CONSTRAINT fk_rails_c1bf6cc5e9 FOREIGN KEY (exported_attachment_id) REFERENCES attachments(id);


--
-- Name: content_migrations fk_rails_c345a5b6d1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY content_migrations
    ADD CONSTRAINT fk_rails_c345a5b6d1 FOREIGN KEY (source_course_id) REFERENCES courses(id);


--
-- Name: discussion_entry_participants fk_rails_c376b0a4c9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY discussion_entry_participants
    ADD CONSTRAINT fk_rails_c376b0a4c9 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: abstract_courses fk_rails_c38b94c5bc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY abstract_courses
    ADD CONSTRAINT fk_rails_c38b94c5bc FOREIGN KEY (account_id) REFERENCES accounts(id);


--
-- Name: conversation_messages fk_rails_c3c322d882; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY conversation_messages
    ADD CONSTRAINT fk_rails_c3c322d882 FOREIGN KEY (conversation_id) REFERENCES conversations(id);


--
-- Name: courses fk_rails_c47c5058d9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY courses
    ADD CONSTRAINT fk_rails_c47c5058d9 FOREIGN KEY (abstract_course_id) REFERENCES abstract_courses(id);


--
-- Name: polling_poll_choices fk_rails_c6c7f35cfc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY polling_poll_choices
    ADD CONSTRAINT fk_rails_c6c7f35cfc FOREIGN KEY (poll_id) REFERENCES polling_polls(id);


--
-- Name: learning_outcome_results fk_rails_c7ade34f0a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY learning_outcome_results
    ADD CONSTRAINT fk_rails_c7ade34f0a FOREIGN KEY (content_tag_id) REFERENCES content_tags(id);


--
-- Name: external_feed_entries fk_rails_c8030518e8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY external_feed_entries
    ADD CONSTRAINT fk_rails_c8030518e8 FOREIGN KEY (external_feed_id) REFERENCES external_feeds(id);


--
-- Name: assessment_requests fk_rails_c86f7bbc12; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY assessment_requests
    ADD CONSTRAINT fk_rails_c86f7bbc12 FOREIGN KEY (assessor_id) REFERENCES users(id);


--
-- Name: quizzes fk_rails_c8bbad8938; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY quizzes
    ADD CONSTRAINT fk_rails_c8bbad8938 FOREIGN KEY (cloned_item_id) REFERENCES cloned_items(id);


--
-- Name: content_migrations fk_rails_c8d17d44ae; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY content_migrations
    ADD CONSTRAINT fk_rails_c8d17d44ae FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: purgatories fk_rails_c906487417; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY purgatories
    ADD CONSTRAINT fk_rails_c906487417 FOREIGN KEY (attachment_id) REFERENCES attachments(id);


--
-- Name: account_users fk_rails_c96445f213; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY account_users
    ADD CONSTRAINT fk_rails_c96445f213 FOREIGN KEY (account_id) REFERENCES accounts(id);


--
-- Name: enrollment_terms fk_rails_cb0782c2d2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY enrollment_terms
    ADD CONSTRAINT fk_rails_cb0782c2d2 FOREIGN KEY (sis_batch_id) REFERENCES sis_batches(id);


--
-- Name: content_tags fk_rails_cbe0e9b21a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY content_tags
    ADD CONSTRAINT fk_rails_cbe0e9b21a FOREIGN KEY (learning_outcome_id) REFERENCES learning_outcomes(id);


--
-- Name: rubric_assessments fk_rails_cbe6352121; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY rubric_assessments
    ADD CONSTRAINT fk_rails_cbe6352121 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: communication_channels fk_rails_cd70d006a2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY communication_channels
    ADD CONSTRAINT fk_rails_cd70d006a2 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: assessment_requests fk_rails_cef87e7126; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY assessment_requests
    ADD CONSTRAINT fk_rails_cef87e7126 FOREIGN KEY (rubric_association_id) REFERENCES rubric_associations(id);


--
-- Name: quiz_submission_events_2019_5 fk_rails_cf44cf4263; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY quiz_submission_events_2019_5
    ADD CONSTRAINT fk_rails_cf44cf4263 FOREIGN KEY (quiz_submission_id) REFERENCES quiz_submissions(id);


--
-- Name: originality_reports fk_rails_cf97449410; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY originality_reports
    ADD CONSTRAINT fk_rails_cf97449410 FOREIGN KEY (attachment_id) REFERENCES attachments(id);


--
-- Name: group_memberships fk_rails_d05778f88b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY group_memberships
    ADD CONSTRAINT fk_rails_d05778f88b FOREIGN KEY (group_id) REFERENCES groups(id);


--
-- Name: conversation_batches fk_rails_d068cb6c53; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY conversation_batches
    ADD CONSTRAINT fk_rails_d068cb6c53 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: favorites fk_rails_d15744e438; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY favorites
    ADD CONSTRAINT fk_rails_d15744e438 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: enrollments fk_rails_d1e7d10c0a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY enrollments
    ADD CONSTRAINT fk_rails_d1e7d10c0a FOREIGN KEY (role_id) REFERENCES roles(id);


--
-- Name: purgatories fk_rails_d1f5462acf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY purgatories
    ADD CONSTRAINT fk_rails_d1f5462acf FOREIGN KEY (deleted_by_user_id) REFERENCES users(id);


--
-- Name: attachments fk_rails_d24085bab5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY attachments
    ADD CONSTRAINT fk_rails_d24085bab5 FOREIGN KEY (usage_rights_id) REFERENCES usage_rights(id);


--
-- Name: groups fk_rails_d2e3c28a2f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY groups
    ADD CONSTRAINT fk_rails_d2e3c28a2f FOREIGN KEY (group_category_id) REFERENCES group_categories(id);


--
-- Name: rubric_assessments fk_rails_d38b350cb8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY rubric_assessments
    ADD CONSTRAINT fk_rails_d38b350cb8 FOREIGN KEY (rubric_association_id) REFERENCES rubric_associations(id);


--
-- Name: conversation_batches fk_rails_d421fc74f4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY conversation_batches
    ADD CONSTRAINT fk_rails_d421fc74f4 FOREIGN KEY (root_conversation_message_id) REFERENCES conversation_messages(id);


--
-- Name: quiz_submission_events_2019_2 fk_rails_d691281c4b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY quiz_submission_events_2019_2
    ADD CONSTRAINT fk_rails_d691281c4b FOREIGN KEY (quiz_submission_id) REFERENCES quiz_submissions(id);


--
-- Name: gradebook_uploads fk_rails_d6c567f720; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gradebook_uploads
    ADD CONSTRAINT fk_rails_d6c567f720 FOREIGN KEY (course_id) REFERENCES courses(id);


--
-- Name: folders fk_rails_da2ad09897; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY folders
    ADD CONSTRAINT fk_rails_da2ad09897 FOREIGN KEY (cloned_item_id) REFERENCES cloned_items(id);


--
-- Name: discussion_topics fk_rails_da3248778d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY discussion_topics
    ADD CONSTRAINT fk_rails_da3248778d FOREIGN KEY (cloned_item_id) REFERENCES cloned_items(id);


--
-- Name: quiz_submission_events_2019_1 fk_rails_dba8402ced; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY quiz_submission_events_2019_1
    ADD CONSTRAINT fk_rails_dba8402ced FOREIGN KEY (quiz_submission_id) REFERENCES quiz_submissions(id);


--
-- Name: context_external_tool_placements fk_rails_dbbdbf40e7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY context_external_tool_placements
    ADD CONSTRAINT fk_rails_dbbdbf40e7 FOREIGN KEY (context_external_tool_id) REFERENCES context_external_tools(id);


--
-- Name: notification_endpoints fk_rails_de537fc04f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY notification_endpoints
    ADD CONSTRAINT fk_rails_de537fc04f FOREIGN KEY (access_token_id) REFERENCES access_tokens(id);


--
-- Name: enrollments fk_rails_df257dd853; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY enrollments
    ADD CONSTRAINT fk_rails_df257dd853 FOREIGN KEY (root_account_id) REFERENCES accounts(id);


--
-- Name: wiki_pages fk_rails_df5fec60ce; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY wiki_pages
    ADD CONSTRAINT fk_rails_df5fec60ce FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: external_feed_entries fk_rails_e0397e1d17; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY external_feed_entries
    ADD CONSTRAINT fk_rails_e0397e1d17 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: course_sections fk_rails_e050b590bb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY course_sections
    ADD CONSTRAINT fk_rails_e050b590bb FOREIGN KEY (sis_batch_id) REFERENCES sis_batches(id);


--
-- Name: course_sections fk_rails_e0676f34c7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY course_sections
    ADD CONSTRAINT fk_rails_e0676f34c7 FOREIGN KEY (nonxlist_course_id) REFERENCES courses(id);


--
-- Name: enrollment_terms fk_rails_e182f18b93; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY enrollment_terms
    ADD CONSTRAINT fk_rails_e182f18b93 FOREIGN KEY (root_account_id) REFERENCES accounts(id);


--
-- Name: discussion_entries fk_rails_e329dc15c5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY discussion_entries
    ADD CONSTRAINT fk_rails_e329dc15c5 FOREIGN KEY (discussion_topic_id) REFERENCES discussion_topics(id);


--
-- Name: assignment_override_students fk_rails_e35e8eee60; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY assignment_override_students
    ADD CONSTRAINT fk_rails_e35e8eee60 FOREIGN KEY (quiz_id) REFERENCES quizzes(id);


--
-- Name: submission_comments fk_rails_e4ff9f0115; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY submission_comments
    ADD CONSTRAINT fk_rails_e4ff9f0115 FOREIGN KEY (submission_id) REFERENCES submissions(id);


--
-- Name: groups fk_rails_e5b00ef0e2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY groups
    ADD CONSTRAINT fk_rails_e5b00ef0e2 FOREIGN KEY (wiki_id) REFERENCES wikis(id);


--
-- Name: lti_product_families fk_rails_e64cbae7bd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY lti_product_families
    ADD CONSTRAINT fk_rails_e64cbae7bd FOREIGN KEY (root_account_id) REFERENCES accounts(id);


--
-- Name: quiz_question_regrades fk_rails_e6cc08d5f1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY quiz_question_regrades
    ADD CONSTRAINT fk_rails_e6cc08d5f1 FOREIGN KEY (quiz_question_id) REFERENCES quiz_questions(id);


--
-- Name: quiz_regrade_runs fk_rails_e7282f482b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY quiz_regrade_runs
    ADD CONSTRAINT fk_rails_e7282f482b FOREIGN KEY (quiz_regrade_id) REFERENCES quiz_regrades(id);


--
-- Name: web_conferences fk_rails_e776d94dd2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY web_conferences
    ADD CONSTRAINT fk_rails_e776d94dd2 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: user_profile_links fk_rails_e7feec0134; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_profile_links
    ADD CONSTRAINT fk_rails_e7feec0134 FOREIGN KEY (user_profile_id) REFERENCES user_profiles(id);


--
-- Name: gradebook_uploads fk_rails_e845504309; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gradebook_uploads
    ADD CONSTRAINT fk_rails_e845504309 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: enrollments fk_rails_e860e0e46b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY enrollments
    ADD CONSTRAINT fk_rails_e860e0e46b FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: quiz_submission_events_2019_6 fk_rails_e89cf60eab; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY quiz_submission_events_2019_6
    ADD CONSTRAINT fk_rails_e89cf60eab FOREIGN KEY (quiz_submission_id) REFERENCES quiz_submissions(id);


--
-- Name: live_assessments_submissions fk_rails_e9f0498f2a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY live_assessments_submissions
    ADD CONSTRAINT fk_rails_e9f0498f2a FOREIGN KEY (assessment_id) REFERENCES live_assessments_assessments(id);


--
-- Name: assignment_override_students fk_rails_ea26ada45d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY assignment_override_students
    ADD CONSTRAINT fk_rails_ea26ada45d FOREIGN KEY (assignment_override_id) REFERENCES assignment_overrides(id);


--
-- Name: rubric_assessments fk_rails_eadf99bbb0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY rubric_assessments
    ADD CONSTRAINT fk_rails_eadf99bbb0 FOREIGN KEY (rubric_id) REFERENCES rubrics(id);


--
-- Name: late_policies fk_rails_eb4f0c93ce; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY late_policies
    ADD CONSTRAINT fk_rails_eb4f0c93ce FOREIGN KEY (course_id) REFERENCES courses(id);


--
-- Name: lti_message_handlers fk_rails_ec356d0f96; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY lti_message_handlers
    ADD CONSTRAINT fk_rails_ec356d0f96 FOREIGN KEY (tool_proxy_id) REFERENCES lti_tool_proxies(id);


--
-- Name: groups fk_rails_ed4ff9a299; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY groups
    ADD CONSTRAINT fk_rails_ed4ff9a299 FOREIGN KEY (account_id) REFERENCES accounts(id);


--
-- Name: submissions fk_rails_ee2f0735cd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY submissions
    ADD CONSTRAINT fk_rails_ee2f0735cd FOREIGN KEY (quiz_submission_id) REFERENCES quiz_submissions(id);


--
-- Name: discussion_topics fk_rails_ef64949942; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY discussion_topics
    ADD CONSTRAINT fk_rails_ef64949942 FOREIGN KEY (editor_id) REFERENCES users(id);


--
-- Name: courses fk_rails_f4449a81f6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY courses
    ADD CONSTRAINT fk_rails_f4449a81f6 FOREIGN KEY (enrollment_term_id) REFERENCES enrollment_terms(id);


--
-- Name: account_users fk_rails_f685686f18; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY account_users
    ADD CONSTRAINT fk_rails_f685686f18 FOREIGN KEY (role_id) REFERENCES roles(id);


--
-- Name: accounts fk_rails_f7353907b2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY accounts
    ADD CONSTRAINT fk_rails_f7353907b2 FOREIGN KEY (brand_config_md5) REFERENCES brand_configs(md5);


--
-- Name: quiz_question_regrades fk_rails_f7834fb23d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY quiz_question_regrades
    ADD CONSTRAINT fk_rails_f7834fb23d FOREIGN KEY (quiz_regrade_id) REFERENCES quiz_regrades(id);


--
-- Name: account_notifications fk_rails_f83172407d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY account_notifications
    ADD CONSTRAINT fk_rails_f83172407d FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: context_external_tool_assignment_lookups fk_rails_f904968ac0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY context_external_tool_assignment_lookups
    ADD CONSTRAINT fk_rails_f904968ac0 FOREIGN KEY (context_external_tool_id) REFERENCES context_external_tools(id);


--
-- Name: master_courses_migration_results fk_rails_f94a4e9f5d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY master_courses_migration_results
    ADD CONSTRAINT fk_rails_f94a4e9f5d FOREIGN KEY (content_migration_id) REFERENCES content_migrations(id);


--
-- Name: alert_criteria fk_rails_f95d56943d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY alert_criteria
    ADD CONSTRAINT fk_rails_f95d56943d FOREIGN KEY (alert_id) REFERENCES alerts(id);


--
-- Name: courses fk_rails_f9bb591b41; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY courses
    ADD CONSTRAINT fk_rails_f9bb591b41 FOREIGN KEY (account_id) REFERENCES accounts(id);


--
-- Name: courses fk_rails_fa9ac2c08c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY courses
    ADD CONSTRAINT fk_rails_fa9ac2c08c FOREIGN KEY (template_course_id) REFERENCES courses(id);


--
-- Name: discussion_topic_participants fk_rails_fb902be971; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY discussion_topic_participants
    ADD CONSTRAINT fk_rails_fb902be971 FOREIGN KEY (discussion_topic_id) REFERENCES discussion_topics(id);


--
-- Name: session_persistence_tokens fk_rails_fc3a4b8b9e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY session_persistence_tokens
    ADD CONSTRAINT fk_rails_fc3a4b8b9e FOREIGN KEY (pseudonym_id) REFERENCES pseudonyms(id);


--
-- Name: lti_resource_placements fk_rails_fc443660f6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY lti_resource_placements
    ADD CONSTRAINT fk_rails_fc443660f6 FOREIGN KEY (message_handler_id) REFERENCES lti_message_handlers(id);


--
-- Name: user_services fk_rails_fea9a826f7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_services
    ADD CONSTRAINT fk_rails_fea9a826f7 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: moderated_grading_provisional_grades provisional_grades_source_provisional_grade_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY moderated_grading_provisional_grades
    ADD CONSTRAINT provisional_grades_source_provisional_grade_fk FOREIGN KEY (source_provisional_grade_id) REFERENCES moderated_grading_provisional_grades(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO public;

INSERT INTO "public"."schema_migrations" (version) VALUES
('20101210192618'),
('20101216224513'),
('20110102070652'),
('20110118001335'),
('20110203205300'),
('20110208031356'),
('20110214180525'),
('20110217231741'),
('20110220031603'),
('20110223175857'),
('20110302054028'),
('20110303133300'),
('20110307163027'),
('20110308223938'),
('20110311052615'),
('20110315144328'),
('20110321151227'),
('20110321204131'),
('20110321234519'),
('20110322164900'),
('20110325162810'),
('20110325200936'),
('20110329223720'),
('20110330192602'),
('20110330204732'),
('20110331145021'),
('20110401163322'),
('20110401214033'),
('20110405210006'),
('20110409232339'),
('20110411214502'),
('20110412154600'),
('20110414160750'),
('20110415103900'),
('20110416052050'),
('20110420162000'),
('20110426161613'),
('20110503231936'),
('20110505055435'),
('20110505141533'),
('20110510155237'),
('20110510171100'),
('20110510180611'),
('20110511194408'),
('20110513162300'),
('20110516222325'),
('20110516225834'),
('20110516233821'),
('20110520164623'),
('20110522035309'),
('20110525175614'),
('20110526154853'),
('20110527155754'),
('20110531144916'),
('20110601222447'),
('20110602202130'),
('20110602202133'),
('20110606160200'),
('20110609212540'),
('20110610163600'),
('20110610213249'),
('20110617200149'),
('20110708151915'),
('20110708231141'),
('20110720185610'),
('20110801034931'),
('20110801080015'),
('20110803192001'),
('20110804195852'),
('20110805003024'),
('20110809193507'),
('20110809221718'),
('20110810194057'),
('20110816152405'),
('20110816203511'),
('20110817173455'),
('20110817193126'),
('20110817210423'),
('20110819205044'),
('20110820021607'),
('20110822151806'),
('20110824191941'),
('20110825131747'),
('20110826153155'),
('20110830152834'),
('20110830154202'),
('20110830213208'),
('20110831210257'),
('20110901153920'),
('20110901202140'),
('20110902032958'),
('20110902033742'),
('20110906215826'),
('20110908150019'),
('20110913171819'),
('20110914215543'),
('20110920163900'),
('20110920163901'),
('20110920165939'),
('20110925050308'),
('20110927163700'),
('20110928191843'),
('20110930041946'),
('20110930122100'),
('20110930235857'),
('20111005201509'),
('20111007115900'),
('20111007115901'),
('20111007143900'),
('20111007172800'),
('20111010173231'),
('20111010205553'),
('20111010214049'),
('20111010223224'),
('20111017124400'),
('20111017165221'),
('20111018221343'),
('20111019152833'),
('20111020191436'),
('20111021161157'),
('20111021210121'),
('20111024163214'),
('20111026055002'),
('20111026193530'),
('20111026193841'),
('20111026201231'),
('20111031145929'),
('20111108150000'),
('20111109005013'),
('20111111165300'),
('20111111225824'),
('20111114164345'),
('20111117202549'),
('20111118221746'),
('20111121175219'),
('20111122162413'),
('20111122162607'),
('20111122172335'),
('20111123022449'),
('20111128172716'),
('20111128205419'),
('20111128212056'),
('20111209000047'),
('20111209054726'),
('20111209171640'),
('20111212152629'),
('20111221230443'),
('20111223215543'),
('20111228210808'),
('20111230165936'),
('20111230172131'),
('20120101163452'),
('20120103235126'),
('20120104170646'),
('20120104183918'),
('20120105201643'),
('20120105205517'),
('20120105210857'),
('20120105221640'),
('20120111202225'),
('20120111205512'),
('20120115222635'),
('20120116151831'),
('20120118163059'),
('20120120161346'),
('20120120190358'),
('20120124171424'),
('20120125012723'),
('20120125210130'),
('20120126200026'),
('20120127035651'),
('20120131001222'),
('20120131001505'),
('20120201044246'),
('20120206224055'),
('20120207210631'),
('20120207222938'),
('20120208180341'),
('20120208213400'),
('20120209223909'),
('20120210173646'),
('20120210200324'),
('20120215193327'),
('20120216163427'),
('20120216214454'),
('20120217214153'),
('20120220193121'),
('20120221204244'),
('20120221220828'),
('20120224194847'),
('20120224194848'),
('20120227192729'),
('20120227194305'),
('20120228203647'),
('20120229203255'),
('20120301210107'),
('20120301231339'),
('20120301231546'),
('20120302175325'),
('20120305234941'),
('20120307154947'),
('20120307190206'),
('20120307222744'),
('20120309165333'),
('20120316233922'),
('20120319184846'),
('20120320171426'),
('20120322170426'),
('20120322184742'),
('20120324000220'),
('20120326021418'),
('20120326023214'),
('20120328162105'),
('20120330151054'),
('20120330163358'),
('20120402054554'),
('20120402054921'),
('20120404151043'),
('20120404230916'),
('20120417133444'),
('20120422213535'),
('20120425161928'),
('20120425180934'),
('20120425201730'),
('20120427162634'),
('20120430164933'),
('20120501160019'),
('20120501213908'),
('20120502144730'),
('20120502190901'),
('20120502212620'),
('20120505003400'),
('20120510004759'),
('20120511173314'),
('20120514210003'),
('20120514215405'),
('20120515055355'),
('20120516152445'),
('20120516185217'),
('20120517150920'),
('20120517222224'),
('20120518154752'),
('20120518160716'),
('20120518205324'),
('20120518212446'),
('20120518214904'),
('20120522145514'),
('20120522163145'),
('20120523145010'),
('20120523153500'),
('20120525174337'),
('20120530201701'),
('20120530213835'),
('20120531150712'),
('20120531183543'),
('20120531221324'),
('20120601195648'),
('20120603222842'),
('20120604223644'),
('20120607164022'),
('20120607181141'),
('20120607195540'),
('20120608165313'),
('20120608191051'),
('20120613214030'),
('20120615012036'),
('20120619203203'),
('20120619203536'),
('20120620171523'),
('20120620184804'),
('20120620185247'),
('20120620190441'),
('20120621214317'),
('20120626174816'),
('20120629215700'),
('20120630213457'),
('20120702185313'),
('20120702212634'),
('20120705144244'),
('20120709180215'),
('20120710190752'),
('20120711214917'),
('20120711215013'),
('20120716204625'),
('20120717140514'),
('20120717140515'),
('20120717202155'),
('20120718161934'),
('20120723201110'),
('20120723201410'),
('20120723201957'),
('20120724172904'),
('20120727145852'),
('20120802163230'),
('20120802204119'),
('20120810212309'),
('20120813165554'),
('20120814205244'),
('20120817191623'),
('20120820141609'),
('20120820215005'),
('20120917230202'),
('20120918220940'),
('20120920154904'),
('20120921155127'),
('20120921203351'),
('20120924171046'),
('20120924181235'),
('20120924205209'),
('20120927184213'),
('20121001190034'),
('20121003200645'),
('20121010191027'),
('20121016150454'),
('20121016230032'),
('20121017124430'),
('20121017165813'),
('20121017165823'),
('20121018205505'),
('20121019185800'),
('20121029182508'),
('20121029214423'),
('20121107163612'),
('20121112230145'),
('20121113002813'),
('20121115205740'),
('20121115210333'),
('20121115220718'),
('20121115220719'),
('20121119172516'),
('20121119201743'),
('20121120180117'),
('20121126224708'),
('20121127174920'),
('20121127212421'),
('20121129175438'),
('20121129230914'),
('20121206040918'),
('20121206201052'),
('20121207193355'),
('20121210154140'),
('20121212050526'),
('20121218215625'),
('20121228182649'),
('20130103191206'),
('20130110212740'),
('20130114214157'),
('20130114214749'),
('20130114215024'),
('20130115163556'),
('20130118000423'),
('20130118162201'),
('20130121212107'),
('20130121212340'),
('20130122193536'),
('20130123035558'),
('20130124203149'),
('20130125234216'),
('20130128192930'),
('20130128220410'),
('20130128221236'),
('20130128221237'),
('20130130195248'),
('20130130202130'),
('20130130203358'),
('20130215164701'),
('20130220000433'),
('20130221052614'),
('20130226233029'),
('20130227205659'),
('20130307214055'),
('20130310212252'),
('20130310213118'),
('20130312024749'),
('20130312231026'),
('20130313141722'),
('20130313162706'),
('20130319120204'),
('20130320130305'),
('20130320190243'),
('20130325204913'),
('20130326210659'),
('20130401031740'),
('20130401032003'),
('20130405213030'),
('20130411031858'),
('20130416170936'),
('20130416190214'),
('20130417153307'),
('20130419193229'),
('20130422191502'),
('20130422205650'),
('20130423162205'),
('20130425230856'),
('20130429190927'),
('20130429201937'),
('20130430215057'),
('20130502200753'),
('20130506191104'),
('20130506222834'),
('20130508214241'),
('20130509173346'),
('20130511131825'),
('20130516174336'),
('20130516204101'),
('20130516205837'),
('20130520205654'),
('20130521161315'),
('20130521163706'),
('20130521181413'),
('20130521223335'),
('20130523162832'),
('20130524164516'),
('20130528204902'),
('20130529183448'),
('20130531124900'),
('20130531135600'),
('20130531140200'),
('20130603181545'),
('20130603211207'),
('20130603213307'),
('20130604174602'),
('20130605211012'),
('20130606170923'),
('20130606170924'),
('20130610174505'),
('20130610204053'),
('20130611194212'),
('20130612201431'),
('20130613174529'),
('20130617152008'),
('20130620041526'),
('20130624174549'),
('20130624174615'),
('20130626220656'),
('20130628215434'),
('20130701160407'),
('20130701160408'),
('20130701193624'),
('20130701210202'),
('20130702104734'),
('20130703165456'),
('20130708201319'),
('20130712230314'),
('20130719192808'),
('20130723162245'),
('20130724222101'),
('20130726205640'),
('20130726230550'),
('20130730162545'),
('20130730163939'),
('20130730164252'),
('20130802164854'),
('20130807165221'),
('20130807194322'),
('20130813195331'),
('20130813195454'),
('20130816182601'),
('20130820202205'),
('20130820210303'),
('20130820210746'),
('20130822214514'),
('20130823204503'),
('20130826215926'),
('20130828191910'),
('20130905190311'),
('20130911191937'),
('20130916174630'),
('20130916192409'),
('20130917194106'),
('20130917194107'),
('20130918193333'),
('20130924153118'),
('20130924163929'),
('20131001193111'),
('20131001193112'),
('20131003195758'),
('20131003202023'),
('20131003221953'),
('20131003222037'),
('20131014185902'),
('20131022192816'),
('20131023154151'),
('20131023205614'),
('20131023221034'),
('20131025153323'),
('20131105175802'),
('20131105230615'),
('20131105232029'),
('20131105234428'),
('20131106161158'),
('20131106171153'),
('20131111221538'),
('20131111224434'),
('20131112184904'),
('20131115165908'),
('20131115221720'),
('20131120173358'),
('20131202173569'),
('20131205162354'),
('20131206221858'),
('20131216190859'),
('20131224010801'),
('20131230182437'),
('20131230213011'),
('20131231182558'),
('20131231182559'),
('20131231194442'),
('20140110201409'),
('20140115230951'),
('20140116220413'),
('20140117195133'),
('20140120201847'),
('20140124163739'),
('20140124173117'),
('20140127203558'),
('20140127204017'),
('20140128205246'),
('20140131163737'),
('20140131164925'),
('20140131231659'),
('20140204180348'),
('20140204235601'),
('20140205171002'),
('20140206203334'),
('20140224212704'),
('20140224212705'),
('20140227171812'),
('20140228201739'),
('20140303160957'),
('20140311223045'),
('20140312232054'),
('20140314220629'),
('20140318150809'),
('20140319223606'),
('20140322132112'),
('20140401224701'),
('20140402204820'),
('20140403213959'),
('20140404162351'),
('20140410164417'),
('20140414230423'),
('20140417143325'),
('20140417220141'),
('20140418210000'),
('20140418211204'),
('20140423003242'),
('20140423034044'),
('20140428182624'),
('20140505211339'),
('20140505215131'),
('20140505215510'),
('20140505223637'),
('20140506200812'),
('20140507204231'),
('20140509161648'),
('20140512180015'),
('20140512213941'),
('20140515163333'),
('20140516160845'),
('20140516215613'),
('20140519163623'),
('20140519221522'),
('20140519221523'),
('20140520152745'),
('20140521183128'),
('20140522190519'),
('20140522231727'),
('20140523142858'),
('20140523164418'),
('20140523175853'),
('20140527170951'),
('20140529220933'),
('20140530195058'),
('20140530195059'),
('20140603193939'),
('20140604180158'),
('20140606184901'),
('20140606220920'),
('20140609195358'),
('20140613194434'),
('20140616202420'),
('20140617211933'),
('20140628015850'),
('20140707221306'),
('20140710153035'),
('20140710211240'),
('20140717183855'),
('20140722150150'),
('20140722151057'),
('20140723220226'),
('20140728202458'),
('20140805194100'),
('20140806161233'),
('20140806162559'),
('20140809142615'),
('20140815192313'),
('20140818134232'),
('20140818144041'),
('20140819210933'),
('20140821130508'),
('20140821171612'),
('20140822192941'),
('20140825163916'),
('20140825200057'),
('20140903152155'),
('20140903164913'),
('20140903191721'),
('20140904193057'),
('20140904214619'),
('20140905171322'),
('20140915174918'),
('20140916195352'),
('20140917205347'),
('20140919170019'),
('20140925153437'),
('20140930123844'),
('20141001211428'),
('20141008142620'),
('20141008201112'),
('20141010172524'),
('20141015083228'),
('20141015132218'),
('20141022192431'),
('20141023050715'),
('20141023120911'),
('20141023164759'),
('20141023171507'),
('20141024045542'),
('20141024155909'),
('20141029163245'),
('20141104213722'),
('20141106211024'),
('20141106213431'),
('20141109202906'),
('20141110133207'),
('20141112204534'),
('20141113211810'),
('20141114205319'),
('20141119233751'),
('20141125133305'),
('20141125212000'),
('20141202202750'),
('20141204222243'),
('20141205172247'),
('20141209081016'),
('20141210062449'),
('20141210112542'),
('20141212134557'),
('20141216202750'),
('20141217222534'),
('20141226194222'),
('20150105210803'),
('20150113222309'),
('20150113222342'),
('20150119204052'),
('20150203174534'),
('20150204033531'),
('20150204210125'),
('20150206165423'),
('20150207205406'),
('20150209173933'),
('20150210172230'),
('20150213193129'),
('20150213195207'),
('20150213200336'),
('20150223211234'),
('20150225205638'),
('20150303073748'),
('20150305223647'),
('20150305225732'),
('20150305234725'),
('20150306193021'),
('20150306193257'),
('20150306193436'),
('20150306204948'),
('20150306215054'),
('20150306223518'),
('20150312155754'),
('20150402170409'),
('20150402190950'),
('20150403145930'),
('20150408191716'),
('20150409141430'),
('20150415152143'),
('20150415191548'),
('20150416203853'),
('20150416231745'),
('20150417193318'),
('20150423192500'),
('20150429143151'),
('20150505173732'),
('20150506164227'),
('20150507024232'),
('20150507024319'),
('20150507151545'),
('20150513155145'),
('20150514193537'),
('20150514194536'),
('20150518165116'),
('20150518201834'),
('20150518202838'),
('20150519205506'),
('20150519205726'),
('20150520141519'),
('20150520143503'),
('20150526214834'),
('20150528180152'),
('20150603165824'),
('20150603171347'),
('20150604155956'),
('20150608173758'),
('20150610163001'),
('20150618143738'),
('20150618183919'),
('20150623192542'),
('20150623232112'),
('20150702221117'),
('20150707202413'),
('20150708170103'),
('20150708170104'),
('20150713165815'),
('20150713214318'),
('20150714162127'),
('20150715215932'),
('20150716154914'),
('20150728222354'),
('20150730170646'),
('20150730222557'),
('20150806172319'),
('20150807133223'),
('20150810175815'),
('20150811155403'),
('20150811162518'),
('20150815071039'),
('20150817134210'),
('20150818031808'),
('20150818172939'),
('20150819165426'),
('20150819165427'),
('20150825233217'),
('20150826200628'),
('20150828114628'),
('20150828171113'),
('20150828210853'),
('20150828215400'),
('20150831164121'),
('20150902140556'),
('20150902191222'),
('20150902192436'),
('20150903204436'),
('20150910191348'),
('20150910205710'),
('20150910215720'),
('20150914171551'),
('20150914201058'),
('20150914201159'),
('20150915185129'),
('20150922142651'),
('20150925063254'),
('20150926232040'),
('20151006220031'),
('20151006222126'),
('20151007154224'),
('20151008204341'),
('20151012151746'),
('20151012222050'),
('20151022203907'),
('20151103222602'),
('20151123210429'),
('20151202171705'),
('20151203144731'),
('20151204224305'),
('20151210162949'),
('20151214203145'),
('20151216161426'),
('20151216170559'),
('20151221185407'),
('20160104220433'),
('20160105202518'),
('20160108163429'),
('20160115234310'),
('20160119170221'),
('20160119183554'),
('20160120201216'),
('20160122192633'),
('20160127184059'),
('20160129144155'),
('20160208133729'),
('20160209163458'),
('20160210153643'),
('20160212204337'),
('20160216135203'),
('20160216165757'),
('20160218011039'),
('20160222035553'),
('20160301180730'),
('20160303173627'),
('20160304205401'),
('20160308200031'),
('20160308215715'),
('20160309135747'),
('20160310141551'),
('20160310205719'),
('20160310225521'),
('20160314171341'),
('20160317134930'),
('20160317193020'),
('20160322204834'),
('20160323121515'),
('20160406170547'),
('20160411201107'),
('20160411222238'),
('20160412154238'),
('20160413183434'),
('20160413190732'),
('20160419155551'),
('20160419220532'),
('20160420152338'),
('20160426183801'),
('20160426211019'),
('20160428140746'),
('20160504154220'),
('20160504164017'),
('20160509131527'),
('20160509164754'),
('20160510152226'),
('20160510211116'),
('20160517153405'),
('20160518175241'),
('20160519221937'),
('20160520035902'),
('20160520172057'),
('20160520172354'),
('20160523163311'),
('20160601141539'),
('20160601192206'),
('20160601195833'),
('20160607214646'),
('20160609195031'),
('20160616151853'),
('20160617221055'),
('20160623201104'),
('20160627183800'),
('20160705191447'),
('20160707203448'),
('20160708195849'),
('20160713185410'),
('20160715170252'),
('20160730111234'),
('20160803022917'),
('20160803212417'),
('20160805163609'),
('20160810134616'),
('20160811164248'),
('20160811164532'),
('20160811172850'),
('20160816165844'),
('20160817170539'),
('20160818202512'),
('20160819193534'),
('20160822163004'),
('20160823152519'),
('20160824211046'),
('20160902165823'),
('20160907164226'),
('20160907201702'),
('20160908200742'),
('20160919175208'),
('20160919180229'),
('20160926190558'),
('20160927165358'),
('20160929151753'),
('20160930163249'),
('20161003132504'),
('20161003171404'),
('20161021180838'),
('20161021195906'),
('20161026192632'),
('20161028181120'),
('20161102152118'),
('20161102160847'),
('20161103144325'),
('20161104170317'),
('20161104180752'),
('20161107192540'),
('20161108204808'),
('20161116173824'),
('20161116211024'),
('20161117194401'),
('20161117205800'),
('20161118195821'),
('20161122174824'),
('20161123165140'),
('20161128200025'),
('20161128205000'),
('20161128205705'),
('20161130223353'),
('20161206165139'),
('20161206165140'),
('20161206165141'),
('20161206191552'),
('20161206230329'),
('20161206230608'),
('20161206234219'),
('20161206323555'),
('20161212012659'),
('20161212200216'),
('20161216183242'),
('20161220003113'),
('20161220193846'),
('20161229165819'),
('20170103170627'),
('20170104171600'),
('20170110145429'),
('20170112160146'),
('20170116190327'),
('20170119203540'),
('20170202143540'),
('20170207200626'),
('20170207211201'),
('20170207211526'),
('20170207231408'),
('20170208195519'),
('20170209175843'),
('20170215234310'),
('20170216144923'),
('20170217081027'),
('20170224175329'),
('20170302210529'),
('20170307135135'),
('20170307144035'),
('20170314143945'),
('20170314165832'),
('20170315185944'),
('20170320212242'),
('20170322213721'),
('20170323171226'),
('20170323183550'),
('20170323205406'),
('20170323212756'),
('20170324212128'),
('20170327150955'),
('20170327170143'),
('20170330061014'),
('20170405195849'),
('20170406193540'),
('20170406221124'),
('20170407190715'),
('20170407194724'),
('20170407231137'),
('20170413154928'),
('20170413202957'),
('20170413202958'),
('20170414134610'),
('20170421160506'),
('20170421162831'),
('20170425160326'),
('20170425160758'),
('20170425165327'),
('20170426164234'),
('20170505142033'),
('20170505142836'),
('20170508170608'),
('20170508170918'),
('20170508171328'),
('20170508214002'),
('20170509022829'),
('20170511215654'),
('20170512013055'),
('20170512013422'),
('20170512184911'),
('20170516023721'),
('20170516154345'),
('20170517162828'),
('20170517182830'),
('20170522211608'),
('20170524215805'),
('20170526160229'),
('20170530142129'),
('20170530170614'),
('20170530215425'),
('20170609221544'),
('20170612163744'),
('20170612221227'),
('20170613174429'),
('20170614020503'),
('20170619191157'),
('20170621223249'),
('20170622150127'),
('20170624070039'),
('20170627124143'),
('20170628141007'),
('20170628144045'),
('20170705191526'),
('20170705191531'),
('20170707210332'),
('20170707212935'),
('20170711212839'),
('20170714191148'),
('20170714192323'),
('20170716050447'),
('20170719210808'),
('20170725164505'),
('20170726210632'),
('20170807165803'),
('20170815152603'),
('20170818154348'),
('20170828143250'),
('20170830204122'),
('20170919065515');


