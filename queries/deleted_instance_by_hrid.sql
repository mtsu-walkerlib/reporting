--metadb:function overdue_with_patron_details
DROP FUNCTION IF EXISTS deleted_instance_by_hrid(text);

CREATE OR REPLACE FUNCTION deleted_instance_by_hrid(
    p_hrid text
)
RETURNS TABLE (
    hrid text,
    title text,
    identifiers text,
    operation text,
    deleted_date text
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        ai.jsonb->'record'->>'hrid' AS hrid,
        ai.jsonb->'record'->>'title' AS title,
        string_agg(i->>'value', '; ' ORDER BY i->>'value') AS identifiers,
        ai.jsonb->>'operation' AS operation,
        ai.jsonb->>'createdDate' AS deleted_date
    FROM folio_inventory.audit_instance__ ai
    CROSS JOIN LATERAL jsonb_array_elements(
        ai.jsonb->'record'->'identifiers'
    ) AS i
    WHERE ai.jsonb->'record'->>'hrid' = p_hrid
      AND ai.jsonb->>'operation' = 'D'
    GROUP BY
        ai.jsonb->'record'->>'hrid',
        ai.jsonb->'record'->>'title',
        ai.jsonb->>'operation',
        ai.jsonb->>'createdDate'
    ORDER BY
        ai.jsonb->>'createdDate' DESC;
$$;
