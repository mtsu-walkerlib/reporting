--metadb:function folio_inventory.deleted_instance_by_hrid
DROP FUNCTION IF EXISTS folio_inventory.deleted_instance_by_hrid(text);

CREATE OR REPLACE FUNCTION folio_inventory.deleted_instance_by_hrid(
    hrid text
)
RETURNS TABLE (
    instance_hrid text,
    title text,
    identifiers text,
    operation text,
    deleted_date text
)
LANGUAGE sql
STABLE
AS $func$

SELECT
    ai.jsonb->'record'->>'hrid' AS instance_hrid,
    ai.jsonb->'record'->>'title' AS title,
    string_agg(i->>'value', '; ' ORDER BY i->>'value') AS identifiers,
    ai.jsonb->>'operation' AS operation,
    ai.jsonb->>'createdDate' AS deleted_date
FROM folio_inventory.audit_instance__ ai
CROSS JOIN LATERAL jsonb_array_elements(
    ai.jsonb->'record'->'identifiers'
) AS i
WHERE ai.jsonb->'record'->>'hrid' = $1
  AND ai.jsonb->>'operation' = 'D'
GROUP BY
    ai.jsonb->'record'->>'hrid',
    ai.jsonb->'record'->>'title',
    ai.jsonb->>'operation',
    ai.jsonb->>'createdDate';

$func$;
