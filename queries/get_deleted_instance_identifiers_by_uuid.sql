--metadb:function get_deleted_instance_identifiers_by_uuid

DROP FUNCTION IF EXISTS get_deleted_instance_identifiers_by_uuid;

CREATE FUNCTION get_deleted_instance_identifiers_by_uuid(
    uuids text DEFAULT NULL)
RETURNS TABLE(
    id text,
    hrid text,
    title text,
    identifiers text,
    deleted_date text)
AS $$
SELECT
    ai.jsonb->'record'->>'id' AS id,
    ai.jsonb->'record'->>'hrid' AS hrid,
    ai.jsonb->'record'->>'title' AS title,
    string_agg(i->>'value', '; ') AS identifiers,
    ai.jsonb->>'createdDate' AS deleted_date
FROM folio_inventory.audit_instance__ ai
CROSS JOIN LATERAL jsonb_array_elements(
    ai.jsonb->'record'->'identifiers'
) AS i
WHERE ai.jsonb->'record'->>'id' = ANY(
    string_to_array(regexp_replace(uuids, '\s', '', 'g'), ',')
)
  AND ai.jsonb->>'operation' = 'D'
GROUP BY
    ai.jsonb->'record'->>'id',
    ai.jsonb->'record'->>'hrid',
    ai.jsonb->'record'->>'title',
    ai.jsonb->>'createdDate'
ORDER BY
    ai.jsonb->'record'->>'id'
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
