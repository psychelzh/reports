library(targets)
library(tarchetypes)
library(dotenv)
if (file.exists(".env.local")) load_dot_env(".env.local")
tar_option_set(packages = c("tidyverse", "DBI", "odbc", "qs", "ggpubr", "lmerTest", "emmeans"))
import::here("R/fetch_from_v3.R", .all = TRUE)
import::here("R/munge_scores.R", .all = TRUE)
import::here("R/report_document.R", .all = TRUE)
import::here("R/report_comparison.R", .all = TRUE)
import::here("R/report_academic.R", .all = TRUE)
tar_pipeline(
  # configure required files
  tar_file(file_school_info, "assets/school_info.csv"),
  tar_fst_tbl(school_info, read_csv(file_school_info, col_types = cols())),
  tar_file(query_abilities, "sql/abilities.sql"),
  tar_fst_tbl(
    abilities,
    fetch_from_v3(query_abilities) %>%
      # abilities added after the course was built should be ignored
      filter(create_time < "2020-09-14")
  ),
  tar_file(query_tmpl_scores, "sql/scores.tmpl.sql"),
  tar_file(query_tmpl_users, "sql/users.tmpl.sql"),
  tar_file(file_config, "config.yml"),
  # prepare data
  tar_qs(
    config_where,
    config::get("where", file = file_config)
  ),
  tar_fst_tbl(
    scores,
    fetch_from_v3(query_tmpl_scores, config_where)
  ),
  tar_fst_tbl(
    users_raw,
    fetch_from_v3(query_tmpl_users, config_where)
  ),
  tar_fst_tbl(
    users,
    munge_users(users_raw, scores)
  ),
  tar_fst_tbl(
    scores_ability,
    prepare_scores_ability(scores, abilities)
  ),
  tar_fst_tbl(
    users_completion,
    calc_users_completion(users, scores, school_info)
  ),
  # render report
  tar_qs(
    report_params,
    config::get("report.params", file = file_config)
  ),
  tar_file(
    rmd_tmpl_body_main,
    "archetypes/report.body.Rmd"
  ),
  tar_file(
    rmd_tmpl_body_child,
    "archetypes/report.body.child.Rmd"
  ),
  tar_render(
    report,
    "docs/report.Rmd",
    params = report_params,
    output_dir = "results",
    output_file = str_c(report_params$customer_name, ".docx")
  ),
  # prepare data of pretest
  tar_qs(
    config_where_pre,
    config::get("where.pre", file = file_config)
  ),
  tar_fst_tbl(
    scores_pre,
    fetch_from_v3(query_tmpl_scores, config_where_pre)
  ),
  tar_fst_tbl(
    users_pre,
    fetch_from_v3(query_tmpl_users, config_where_pre)
  ),
  tar_fst_tbl(
    users_joined,
    distinct(bind_rows(users, users_pre))
  ),
  tar_fst_tbl(
    scores_joined,
    merge_scores(scores_pre, scores)
  ),
  # plot comparison figures
  tar_fst_tbl(
    data_comparison,
    prepare_data_comparison(scores_joined, users_joined, report_params) %>%
      group_by(game_name) %>%
      tar_group(),
    iteration = "group"
  ),
  tar_file(
    output_comparison,
    plot_comparison(
      data_comparison,
      config::get("game_index", file = file_config)
    ),
    pattern = map(data_comparison)
  ),
  # load academic scores
  tar_file(
    file_scores_academic,
    "assets/academic_jianyan.csv"
  ),
  tar_fst_tbl(
    scores_academic,
    load_academic(file_scores_academic, users_joined)
  ),
  tar_fst_tbl(
    scores_game_academic,
    inner_join(scores_joined, scores_academic, by = "user_id") %>%
      filter(session == "第二次", game_name != "图形归纳推理A") %>%
      group_by(game_name, session, subject, term) %>%
      # keep results with more than 50 samples
      filter(n_distinct(user_id) > 50) %>%
      group_by(game_name) %>%
      tar_group(),
    iteration = "group"
  ),
  tar_file(
    output_scatter,
    plot_academic(
      scores_game_academic,
      config::get("game_index", file = file_config)
    ),
    pattern = map(scores_game_academic)
  )
)
