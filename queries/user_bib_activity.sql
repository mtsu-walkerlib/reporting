--metadb:function user_bib_activity
DROP FUNCTION IF EXISTS user_bib_activity;

CREATE FUNCTION user_bib_activity()

RETURNS TABLE (
  month TEXT,
  instances_created INTEGER,
  instances_modified INTEGER,
  holdings_created INTEGER,
  holdings_modified INTEGER,
  items_created INTEGER,
  items_modified INTEGER
)
AS $$
DECLARE
  input_username TEXT := input_json ->> 'username';
BEGIN
  RETURN QUERY

  WITH su AS (
    SELECT id, username
    FROM folio_users.users__t
    WHERE username = input_username
  ),
  all_actions AS (

    -- Instances created
    SELECT
      su.username,
      date_trunc('month', i.record_created_date::timestamp)::date AS month,
      'instances_created' AS action
    FROM su
    JOIN instance_ext i ON i.created_by_user_id = su.id

    UNION ALL
    -- Instances modified (from folio_inventory.instance__)
    SELECT
      su.username,
      date_trunc('month', (ii.jsonb -> 'metadata' ->> 'updatedDate')::timestamp)::date AS month,
      'instances_modified' AS action
    FROM su
    JOIN folio_inventory.instance__ ii
      ON (ii.jsonb -> 'metadata' ->> 'updatedByUserId') = su.id::text

    UNION ALL
    -- Holdings created
    SELECT
      su.username,
      date_trunc('month', h.created_date::timestamp)::date AS month,
      'holdings_created' AS action
    FROM su
    JOIN holdings_ext h ON h.created_by_user_id = su.id

    UNION ALL
    -- Holdings modified
    SELECT
      su.username,
      date_trunc('month', (hh.jsonb -> 'metadata' ->> 'updatedDate')::timestamp)::date AS month,
      'holdings_modified' AS action
    FROM su
    JOIN folio_inventory.holdings_record__ hh
      ON (hh.jsonb -> 'metadata' ->> 'updatedByUserId') = su.id::text

    UNION ALL
    -- Items created
    SELECT
      su.username,
      date_trunc('month', it.created_date::timestamp)::date AS month,
      'items_created' AS action
    FROM su
    JOIN item_ext it ON it.created_by = su.id

    UNION ALL
    -- Items modified
    SELECT
      su.username,
      date_trunc('month', (itt.jsonb -> 'metadata' ->> 'updatedDate')::timestamp)::date AS month,
      'items_modified' AS action
    FROM su
    JOIN folio_inventory.item__ itt
      ON (itt.jsonb -> 'metadata' ->> 'updatedByUserId') = su.id::text
  )
  SELECT
    COALESCE(TO_CHAR(month, 'YYYY-MM'), 'TOTAL') AS month,
    SUM(CASE WHEN action = 'instances_created'  THEN 1 ELSE 0 END) AS instances_created,
    SUM(CASE WHEN action = 'instances_modified' THEN 1 ELSE 0 END) AS instances_modified,
    SUM(CASE WHEN action = 'holdings_created'  THEN 1 ELSE 0 END) AS holdings_created,
    SUM(CASE WHEN action = 'holdings_modified' THEN 1 ELSE 0 END) AS holdings_modified,
    SUM(CASE WHEN action = 'items_created'     THEN 1 ELSE 0 END) AS items_created,
    SUM(CASE WHEN action = 'items_modified'    THEN 1 ELSE 0 END) AS items_modified
  FROM all_actions
  GROUP BY ROLLUP(month)
  ORDER BY month;

END;
$$ 
LANGUAGE sql STABLE;
