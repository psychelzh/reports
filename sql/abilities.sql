-- !preview conn=DBI::dbConnect(odbc::odbc(), "iquizoo-v3", database = "iquizoo_datacenter_db")

SELECT
	content.Id game_id,
	content_ability.FirstAbilityName ab_name_first,
	content_ability.SecondAbilityName ab_name_second,
	content_ability.CreateTime create_time
FROM
	iquizoo_content_db.content
	INNER JOIN iquizoo_content_db.content_ability
		ON content_ability.ContentId = content.Id
WHERE
	content_ability.AbilityTypeName = '基础能力';
