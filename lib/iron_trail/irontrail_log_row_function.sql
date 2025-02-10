CREATE OR REPLACE FUNCTION irontrail_log_row()
RETURNS TRIGGER AS $$
DECLARE
  u_changes JSONB;
  key TEXT;
  it_meta TEXT;
  it_meta_obj JSONB;
  value_a JSONB;
  value_b JSONB;
  old_obj JSONB;
  new_obj JSONB;
  actor_type TEXT;
  actor_id TEXT;
  created_at TIMESTAMP;

  err_text TEXT; err_detail TEXT; err_hint TEXT; err_ctx TEXT;
BEGIN
    SELECT split_part(split_part(current_query(), '/*IronTrail ', 2), ' IronTrail*/', 1) INTO it_meta;

    IF (it_meta <> '') THEN
      it_meta_obj = it_meta::JSONB;

      IF (it_meta_obj ? '_actor_type') THEN
        actor_type = it_meta_obj->>'_actor_type';
        it_meta_obj = it_meta_obj - '_actor_type';
      END IF;
      IF (it_meta_obj ? '_actor_id') THEN
        actor_id = it_meta_obj->>'_actor_id';
        it_meta_obj = it_meta_obj - '_actor_id';
      END IF;
    END IF;

    old_obj = row_to_json(OLD);
    new_obj = row_to_json(NEW);

    IF (TG_OP = 'INSERT' AND new_obj ? 'created_at') THEN
      created_at = NEW.created_at;
    ELSIF (TG_OP = 'UPDATE' AND new_obj ? 'updated_at') THEN
      IF (NEW.updated_at <> OLD.updated_at) THEN
        created_at = NEW.updated_at;
      END IF;
    END IF;

    IF (created_at IS NULL) THEN
      created_at = STATEMENT_TIMESTAMP();
    ELSE
      it_meta_obj = jsonb_set(COALESCE(it_meta_obj, '{}'::jsonb), array['_db_created_at'], TO_JSONB(STATEMENT_TIMESTAMP()));
    END IF;

    IF (TG_OP = 'INSERT') THEN
        INSERT INTO "irontrail_changes" ("actor_id", "actor_type",
          "rec_table", "operation", "rec_id", "rec_new", "metadata", "created_at")
        VALUES (actor_id, actor_type,
          TG_TABLE_NAME, 'i', NEW.id, new_obj, it_meta_obj, created_at);

    ELSIF (TG_OP = 'UPDATE') THEN
        IF (OLD <> NEW) THEN
          u_changes = jsonb_build_object();

          FOR key IN (SELECT jsonb_object_keys(old_obj) UNION SELECT jsonb_object_keys(new_obj))
          LOOP
              value_a := old_obj->key;
              value_b := new_obj->key;
              IF value_a IS DISTINCT FROM value_b THEN
                  u_changes := u_changes || jsonb_build_object(key, jsonb_build_array(value_a, value_b));
              END IF;
          END LOOP;

          INSERT INTO "irontrail_changes" ("actor_id", "actor_type", "rec_table", "operation",
            "rec_id", "rec_old", "rec_new", "rec_delta", "metadata", "created_at")
          VALUES (actor_id, actor_type, TG_TABLE_NAME, 'u', NEW.id, old_obj, new_obj, u_changes, it_meta_obj, created_at);

        END IF;
    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO "irontrail_changes" ("actor_id", "actor_type", "rec_table", "operation",
          "rec_id", "rec_old", "metadata", "created_at")
        VALUES (actor_id, actor_type, TG_TABLE_NAME, 'd', OLD.id, old_obj, it_meta_obj, created_at);

    END IF;
    RETURN NULL;
EXCEPTION
  WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
      err_text = MESSAGE_TEXT,
      err_detail = PG_EXCEPTION_DETAIL,
      err_hint = PG_EXCEPTION_HINT,
      err_ctx = PG_EXCEPTION_CONTEXT;

    INSERT INTO "irontrail_trigger_errors" ("pg_errcode", "pg_message",
        "err_text", "ex_detail", "ex_hint", "ex_ctx", "op", "table_name",
        "old_data", "new_data", "query", "created_at")
      VALUES (SQLSTATE, SQLERRM, err_text, err_detail, err_hint, err_ctx,
        TG_OP, TG_TABLE_NAME, row_to_json(OLD), row_to_json(NEW), current_query(), STATEMENT_TIMESTAMP());
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;
