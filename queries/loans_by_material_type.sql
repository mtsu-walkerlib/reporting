--metadb:function loans_by_material_type

DROP FUNCTION IF EXISTS loans_by_material_type;

CREATE FUNCTION loans_by_material_type(
    start_date date DEFAULT '2000-01-01',
    end_date date DEFAULT '2050-01-01')
RETURNS TABLE(
    material_type text,
    loans bigint)
AS $$
WITH monthly_loans AS (
    SELECT
        id,
        item_id
    FROM
        folio_circulation.loan__t
    WHERE
        loan_date >= start_date AND loan_date < end_date
)
SELECT
    COALESCE(m.name, '(no material type / missing item)') AS material_type,
    COALESCE(count(l.id), 0) AS loans
FROM
    monthly_loans AS l
    LEFT JOIN folio_inventory.item__t AS i ON l.item_id = i.id
    LEFT JOIN folio_inventory.material_type__t AS m ON m.id = i.material_type_id
GROUP BY
    material_type
ORDER BY
    loans DESC
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
