--metadb:function courses_items_desc
DROP FUNCTION IF EXISTS courses_items_desc;

CREATE FUNCTION courses_items_desc()

returns table
(
  ItemUUID TEXT,
  Prefix_Number TEXT,
  Course_Title TEXT,
  Instructor TEXT,
  Registrar_ID TEXT,
  Book_Title TEXT,
  Edition TEXT,
  Primary_Contributor TEXT,
  Publisher TEXT,
  Date_of_Pulication DATE
)
as
$$
SELECT 
	crr.item_id AS item_uuid,
	crc.name AS prefix_number,
	crc.description as course_title,
	cri.name as instructor,
	crcl.registrar_id as registrar_id,
	ine.title as book_title,
	ed.edition as edition,
	ic.contributor_name as primary_contributor,
	ip.publisher,
	ip.date_of_publication
FROM folio_courses.coursereserves_reserves__t AS crr
LEFT JOIN folio_courses.coursereserves_courses__t AS crc ON crc.course_listing_id = crr.course_listing_id
left join folio_courses.coursereserves_instructors__t as cri on cri.course_listing_id = crc.course_listing_id
left join folio_courses.coursereserves_courselistings__t as crcl on crcl.id = cri.course_listing_id
left join folio_derived.item_ext as ite on ite.item_id = crr.item_id
left join folio_derived.holdings_ext as he on he.id = ite.holdings_record_id
left join folio_derived.instance_ext as ine on ine.instance_id = he.instance_id
left join folio_derived.instance_publication ip on ip.instance_id = ine.instance_id
left join folio_derived.instance_editions ed on ed.instance_id = ine.instance_id 
LEFT JOIN folio_derived.instance_contributors ic 
    ON ic.instance_id = ine.instance_id
    AND ic.contributor_is_primary = 'true'
where cri.name is not null 
order by crc.description;
$$
LANGUAGE SQL STABLE;
