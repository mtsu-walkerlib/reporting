--metadb:function inhouse_check_in
DROP FUNCTION IF EXISTS inhouse_check_in;

CREATE FUNCTION inhouse_check_in()

returns table
(
  ItemUUID TEXT,
  Date DATE,
  Barcode TEXT,
  Location TEXT,
  Call_Number TEXT,
  Title TEXT,
  Checking_In_User TEXT
)
as
$$
SELECT
    cit.item_id                                AS "ItemUUID",
    cit.occurred_date_time::date               AS "Date",
    i.barcode                                  AS "Barcode",
    l.name                                     AS "Location",
    i.item_level_call_number                    AS "Call_Number",
    inst.title                                 AS "Title",
    u.username                                 AS "Checking_In_User"
FROM folio_circulation.check_in__t AS cit
LEFT JOIN folio_inventory.location__t       AS l   ON l.id  = cit.item_location_id
LEFT JOIN folio_inventory.item__t           AS i   ON i.id  = cit.item_id
LEFT JOIN folio_inventory.holdings_record__t AS h  ON h.id  = i.holdings_record_id
LEFT JOIN folio_inventory.instance__t       AS inst ON inst.id = h.instance_id
LEFT JOIN folio_users.users__t              AS u   ON u.id  = cit.performed_by_user_id
WHERE cit.item_status_prior_to_check_in = 'Available'
  AND cit.occurred_date_time >= TIMESTAMP '2025-01-01 00:00:00'
  AND cit.occurred_date_time <  TIMESTAMP '2026-01-01 00:00:00'
ORDER BY cit.occurred_date_time;
$$
LANGUAGE SQL STABLE;
