library(targets)
library(tarchetypes)
library(dotenv)
if (file.exists(".env.local")) load_dot_env(".env.local")
tar_option_set(packages = c("tidyverse", "DBI", "odbc", "qs"))
import::here("R/fetch_from_v3.R", .all = TRUE)
import::here("R/prep_ability_scores.R", .all = TRUE)
tar_pipeline(
  tar_file(query_tmpl_scores, "sql/scores.tmpl.sql"),
  tar_file(query_tmpl_users, "sql/users.tmpl.sql"),
  tar_file(query_abilities, "sql/abilities.sql"),
  tar_file(file_config, "config.yml"),
  tar_change(
    config_where,
    config::get("where", file = file_config),
    change = Sys.getenv("R_CONFIG_ACTIVE", "default"),
    format = "qs"
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
  )
)
