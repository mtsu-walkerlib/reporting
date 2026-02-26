WITH m AS (
  SELECT
      instance_hrid,
      field,
      string_agg(content, ' | ') AS val
  FROM folio_source_record.marc__t
  WHERE field IN ('245','260','264','510')
  GROUP BY instance_hrid, field
),
pivot AS (
  SELECT
      instance_hrid,
      MAX(CASE WHEN field = '245' THEN val END) AS f245,
      MAX(CASE WHEN field = '260' THEN val END) AS f260,
      MAX(CASE WHEN field = '264' THEN val END) AS f264,
      MAX(CASE WHEN field = '510' THEN val END) AS f510
  FROM m
  GROUP BY instance_hrid
)
SELECT
    p.instance_hrid AS hrid,
    p.f245,
    p.f260,
    p.f264,
    p.f510
FROM pivot p
JOIN folio_derived.instance_ext ie
  ON ie.instance_hrid = p.instance_hrid
JOIN folio_derived.holdings_ext he
  ON he.instance_id = ie.instance_id
JOIN folio_derived.item_ext ix
  ON ix.holdings_record_id = he.id
JOIN folio_derived.item_statistical_codes code
  ON code.item_id = ix.item_id
WHERE code.statistical_code_name = 'Tennessee Imprints'
GROUP BY p.instance_hrid, p.f245, p.f260, p.f264, p.f510
ORDER BY p.instance_hrid;
