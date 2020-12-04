library(targets)
library(tarchetypes)
library(dotenv)
if (file.exists(".env.local")) load_dot_env(".env.local")
tar_option_set(packages = c("tidyverse", "DBI", "odbc", "qs"))
import::here("R/fetch_from_v3.R", .all = TRUE)
import::here("R/prepare_ability_scores.R", .all = TRUE)
import::here("R/calc_users_completion.R", .all = TRUE)
tar_pipeline(
  tar_file(file_school_info, "assets/school_info.csv"),
  tar_fst_tbl(school_info, read_csv(file_school_info, col_types = cols())),
  tar_file(query_tmpl_scores, "sql/scores.tmpl.sql"),
  tar_file(query_tmpl_users, "sql/users.tmpl.sql"),
  tar_file(query_abilities, "sql/abilities.sql"),
  tar_file(config_file, "config.yml"),
  tar_qs(
    config_where,
    config::get("where", file = config_file)
  ),
  tar_fst_tbl(
    scores,
    fetch_from_v3(query_tmpl_scores, config_where)
  ),
  tar_fst_tbl(
    users,
    fetch_from_v3(query_tmpl_users, config_where)
  ),
  tar_fst_tbl(
    abilities,
    fetch_from_v3(query_abilities) %>%
      # abilities added after the course was built should be ignored
      filter(create_time < "2020-09-14")
  ),
  tar_fst_tbl(
    ability_scores,
    prepare_ability_scores(scores, abilities)
  ),
  tar_fst_tbl(
    users_completion,
    calc_users_completion(users, scores, school_info)
  ),
  tar_qs(
    report_params,
    config::get("report.params", file = config_file)
  ),
  tar_render(
    report,
    "docs/report.Rmd",
    params = report_params,
    output_dir = "results",
    output_file = str_c(report_params$customer_name, ".docx")
  )
)
