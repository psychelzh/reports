library(targets)
library(tarchetypes)
library(dotenv)
if (file.exists(".env.local")) load_dot_env(".env.local")
tar_option_set(
  packages = c("tidyverse", "ggpubr", "lmerTest", "emmeans", "performance")
)
purrr::walk(fs::dir_ls("R"), source)
list(
  # configure required files
  tar_file(file_school_info, "assets/school_info.csv"),
  tar_fst_tbl(school_info, read_csv(file_school_info, col_types = cols())),
  tar_file(query_abilities, "sql/abilities.sql"),
  tar_fst_tbl(
    abilities,
    tarflow.iquizoo::fetch_from_v3(query_abilities) %>%
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
    tarflow.iquizoo::fetch_from_v3(query_tmpl_scores, config_where)
  ),
  tar_fst_tbl(
    users_raw,
    tarflow.iquizoo::fetch_from_v3(query_tmpl_users, config_where)
  ),
  tar_fst_tbl(
    users,
    munge_users(users_raw, scores)
  ),
  tar_fst_tbl(
    scores_ability,
    prepare_scores_ability(scores, abilities, extra)
  ),
  tar_fst_tbl(
    users_completion,
    calc_users_completion(users, scores, school_info)
  ),
  tar_qs(
    config_where_compared,
    tribble(
      ~table, ~field, ~values,
      "content", "Name", unique(scores$game_name),
      "base_organization", "Province", c("北京市", "浙江省", "黑龙江省", "浙江省")
    )
  ),
  tar_fst_tbl(
    scores_compared,
    tarflow.iquizoo::fetch_from_v3(query_tmpl_scores, config_where_compared)
  ),
  tar_fst_tbl(
    users_compared,
    tarflow.iquizoo::fetch_from_v3(query_tmpl_users, config_where_compared)
  ),
  tar_fst_tbl(
    scores_ability_compared,
    prepare_scores_ability(scores_compared, abilities, extra)
  ),
  tar_fst_tbl(
    users_compared_clean,
    users_compared %>%
      filter(!str_detect(user_name, "测评|体验")) %>%
      mutate(
        edu_stage = case_when(
          grade %in%
            c("一年级", "二年级", "三年级", "四年级", "五年级", "六年级") ~
            "小学",
          grade %in% c("初一", "初二", "初三") ~ "初中",
          TRUE ~ "其他"
        )
      )
  ),
  tar_qs(
    extra,
    config::get("extra", file = file_config)
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
    tarflow.iquizoo::fetch_from_v3(query_tmpl_scores, config_where_pre)
  ),
  tar_fst_tbl(
    users_pre,
    tarflow.iquizoo::fetch_from_v3(query_tmpl_users, config_where_pre)
  ),
  tar_fst_tbl(
    users_joined,
    distinct(bind_rows(users, users_pre))
  ),
  tar_fst_tbl(
    scores_joined,
    merge_scores(scores_pre, scores)
  ),
  tar_qs(game_index, config::get("game_index", file = file_config)),
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
    plot_comparison(data_comparison, game_index),
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
    plot_academic(scores_game_academic, game_index),
    pattern = map(scores_game_academic)
  )
)
