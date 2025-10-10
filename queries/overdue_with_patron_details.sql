SELECT cast(li.loan_due_date AS DATE) AS due_date,
	   cast(li.loan_date as DATE) as check_out_date,
        ihi.barcode AS item_barcode,
        ug.user_first_name as patron_first_name,
        ug.user_last_name AS patron_last_name,
        ug.barcode AS patron_barcode,
        li.patron_group_name AS patron_group_name,
        ug.user_email AS patron_email,
        ie.effective_call_number AS item_effective_call_number,
        ihi.title AS item_title,
        li.item_status AS item_status,
        ie.effective_location_name AS location_effective
FROM folio_derived.items_holdings_instances ihi
        JOIN folio_derived.item_ext ie ON ie.item_id = ihi.item_id
        JOIN folio_derived.loans_items li ON ihi.item_id = li.item_id
        JOIN folio_derived.locations_libraries ll ON ll.location_id = ie.effective_location_id
        JOIN folio_derived.users_groups ug ON li.user_id = ug.user_id
WHERE li.loan_status = 'Open'
        AND li.loan_due_date < CURRENT_DATE
        AND li.patron_group_name NOT IN ('ill')
        AND ie.discovery_suppress = 'False'
order by li.loan_due_date desc;
