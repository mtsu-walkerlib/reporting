--metadb:function tech_services_special_printing
DROP FUNCTION IF EXISTS tech_services_special_printing;

CREATE FUNCTION tech_services_special_printing()

returns table
(
    user_id TEXT,
    location TEXT,
    amount TEXT,
    remaining TEXT,
    fee_fine_type TEXT,
    fee_fine_owner TEXT,
    title TEXT,
    material_type TEXT,
    type_action TEXT,
    transaction_date DATE,
    comments TEXT,
    created_date DATE,
    payment_status TEXT
)
as
$$
WITH latest_faa AS (
    SELECT DISTINCT ON (fine_account_id)
        fine_account_id,
        type_action,
        fine_status,
        transaction_date
    FROM folio_derived.feesfines_accounts_actions
    ORDER BY fine_account_id, transaction_date DESC
),
latest_ft AS (
    SELECT DISTINCT ON (account_id)
        account_id,
        comments
    FROM folio_feesfines.feefineactions__t
    ORDER BY account_id DESC
)
SELECT
    acc.user_id,
    acc.location,
    acc.amount,
    acc.remaining,
    acc.fee_fine_type,
    acc.fee_fine_owner,
    acc.title,
    acc.material_type,
    faa.type_action,
    faa.fine_status,
    cast (faa.transaction_date as DATE),
    ft.comments,
    raw.jsonb -> 'metadata' ->> 'createdDate' AS created_date,
    raw.jsonb -> 'paymentStatus' ->> 'name' AS payment_status
FROM
    folio_feesfines.accounts__t AS acc
LEFT JOIN latest_faa AS faa
    ON faa.fine_account_id = acc.id
LEFT JOIN latest_ft AS ft
    ON ft.account_id = acc.id
LEFT JOIN folio_feesfines.accounts AS raw
    ON raw.id = acc.id
WHERE
    acc.fee_fine_owner = 'Tech&MakerSpace'
ORDER BY
    --acc.user_id;  --ordered by user_id so the fines are readable?
    created_date desc;
$$
language sql stable;
