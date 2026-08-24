--metadb:function techmakerspace_feesfines
DROP FUNCTION IF EXISTS tech_makerspace_feesfines;
CREATE FUNCTION tech_makerspace_feesfines(start_date DATE, end_date DATE)
returns table
(
  User_UUID TEXT,
  Fee_Fine_Type TEXT,
  Created_Date DATE,
  Due_Date DATE,
  Returned_Date DATE,
  Fine_Status TEXT,
  Payment_Status TEXT,
  Material_Type TEXT,
  Amount NUMERIC,
  Remaining NUMERIC,
  Title TEXT,
  Barcode TEXT,
  Location TEXT,
  Comments TEXT
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
    acc.user_id                                            AS "User_UUID",
    acc.fee_fine_type                                       AS "Fee_Fine_Type",
    CAST(raw.jsonb -> 'metadata' ->> 'createdDate' AS DATE) AS "Created_Date",
    CAST(acc.due_date AS DATE)                               AS "Due_Date",
    CAST(acc.returned_date AS DATE)                          AS "Returned_Date",
    faa.fine_status                                          AS "Fine_Status",
    raw.jsonb -> 'paymentStatus' ->> 'name'                  AS "Payment_Status",
    acc.material_type                                        AS "Material_Type",
    acc.amount                                               AS "Amount",
    acc.remaining                                            AS "Remaining",
    acc.title                                                AS "Title",
    acc.barcode                                              AS "Barcode",
    acc.location                                             AS "Location",
    ft.comments                                              AS "Comments"
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
    AND (raw.jsonb -> 'paymentStatus' ->> 'name') NOT LIKE '%Waived%'
    AND (raw.jsonb -> 'paymentStatus' ->> 'name') NOT LIKE '%Cancelled%'
    AND (raw.jsonb -> 'metadata' ->> 'createdDate')::DATE >= start_date
    AND (raw.jsonb -> 'metadata' ->> 'createdDate')::DATE <= end_date
ORDER BY
    "Payment_Status", "Created_Date";
$$
LANGUAGE SQL STABLE;
