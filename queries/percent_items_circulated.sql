--metadb:function percent_items_circulated
DROP FUNCTION IF EXISTS percent_items_circulated;

CREATE FUNCTION percent_items_circulated()

returns table
(
  loan_percentage TEXT
)
as
$$
SELECT
  to_char(
    (
      (SELECT count(DISTINCT item_id)::float FROM folio_circulation.loan__t) /
      (SELECT count(*)::float FROM folio_inventory.item__t)
    ) * 100,
    'FM999990.00"%"'
  ) AS loan_percentage;
$$
language sql stable;
