--metadb:function get_deleted_instance_identifiers

DROP FUNCTION IF EXISTS get_deleted_instance_identifiers;

CREATE FUNCTION get_deleted_instance_identifiers(
    hrids text DEFAULT NULL)
RETURNS TABLE(
    hrid text,
    title text,
    identifiers text,
    deleted_date text)
AS $$
SELECT
    ai.jsonb->'record'->>'hrid' AS hrid,
    ai.jsonb->'record'->>'title' AS title,
    string_agg(i->>'value', '; ') AS identifiers,
    ai.jsonb->>'createdDate' AS deleted_date
FROM folio_inventory.audit_instance__ ai
CROSS JOIN LATERAL jsonb_array_elements(
    ai.jsonb->'record'->'identifiers'
) AS i
WHERE ai.jsonb->'record'->>'hrid' = ANY(
    string_to_array(regexp_replace(hrids, '\s', '', 'g'), ',')
)
  AND ai.jsonb->>'operation' = 'D'
GROUP BY
    ai.jsonb->'record'->>'hrid',
    ai.jsonb->'record'->>'title',
    ai.jsonb->>'createdDate'
ORDER BY
    ai.jsonb->'record'->>'hrid'
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
