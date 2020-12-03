-- !preview conn=DBI::dbConnect(odbc::odbc(), "iquizoo-v3", database = "iquizoo_datacenter_db")

SELECT DISTINCT
	`user`.Id user_id,
	`user`.RealName user_name,
	`user`.Gender user_sex,
	`user`.Birthday user_dob,
	base_organization.`Name` school,
	base_organization.Province province,
	base_organization.City city,
	base_grade_class.GradeName grade,
	base_grade_class.ClassName class
FROM
	iquizoo_user_db.`user`
	INNER JOIN iquizoo_user_db.user_organization ON user_organization.UserId = `user`.Id
	INNER JOIN iquizoo_user_db.base_organization ON base_organization.Id = user_organization.OrganizationId  -- `base_organization` might be used in "where_clause"
	INNER JOIN iquizoo_user_db.base_grade_class ON base_grade_class.Id = user_organization.ClassId
	INNER JOIN iquizoo_content_db.project_course_user ON project_course_user.UserId = user_organization.Id
	INNER JOIN iquizoo_content_db.course ON course.Id = project_course_user.CourseId -- `course` might be used in "where_clause"
	INNER JOIN iquizoo_content_db.course_child ON course_child.CourseId = course.Id
	INNER JOIN iquizoo_content_db.course_child_config ON course_child_config.ChildCourseId = course_child.Id
	INNER JOIN iquizoo_content_db.content ON content.Id = course_child_config.ContentId -- `content` might be used in "where_clause"
	INNER JOIN iquizoo_content_db.projects ON projects.Id = project_course_user.ProjectId -- -- `projects` might be used in "where_clause"
{ where_clause };
