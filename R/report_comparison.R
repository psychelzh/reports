##' Join raw scores
##'
##' @param scores_pre
##' @param scores
##' @author Liang Zhang
##' @export
merge_scores <- function(scores_pre, scores) {
  bind_rows(
    第一次 = remove_duplicate_scores(scores_pre),
    第二次 = remove_duplicate_scores(scores),
    .id = "session"
  ) %>%
    select(user_id, game_id, game_name, session, game_score_raw)
}

##' Prepare data for comparison plotting
##'
##' @title
##' @param scores_joined
##' @param users_joined
##' @param report_params
##' @return
##' @author Liang Zhang
##' @export
prepare_data_comparison <- function(scores_joined, users_joined, report_params) {
  scores_joined %>%
    # keep games with both pre and post test scores
    group_by(user_id, game_id) %>%
    filter(n() == 2) %>%
    ungroup() %>%
    # card sort and firefly games updated versions
    filter(!game_name %in% c("卡片分类", "萤火虫")) %>%
    inner_join(users_joined, by = "user_id") %>%
    group_by(game_id, game_name, grade, user_sex) %>%
    group_modify(
      ~ lmer(game_score_raw ~ session + (1 | user_id), .x) %>%
        emmeans(~ session) %>%
        broom::tidy()
    ) %>%
    ungroup() %>%
    mutate(
      session = factor(session, c("第一次", "第二次")),
      user_sex = factor(user_sex, c("男", "女")),
      grade = factor(grade, report_params$grade_order),
      ymax = estimate + std.error,
      ymin = estimate - std.error
    )
}

##' Plot comparison figures based on different sex and grade
##'
##' @param data
##' @param game_index
##' @param color
##' @return The file name stored the figure
##' @author Liang Zhang
##' @export
plot_comparison <- function(data, game_index, color = user_sex) {
  game_name <- unique(data$game_name)
  save_filename <- fs::path("image", str_glue("两次对比-{game_name}.png"))
  p <- ggplot(
    data,
    aes(session, estimate, ymax = ymax, ymin = ymin, color = {{ color }})
  ) +
    geom_point(position = position_dodge(width = 0.1)) +
    geom_errorbar(position = position_dodge(width = 0.1), width = 0) +
    geom_line(aes(group = user_sex), position = position_dodge(width = 0.1)) +
    scale_color_grey() +
    labs(x = "", y = game_index[[game_name]], color = "", title = game_name) +
    facet_wrap(~ grade, ncol = 1) +
    theme_pubclean() +
    theme(
      legend.key = element_rect(fill = "transparent"),
      plot.title = element_text(hjust = 0.5)
    )
  ggsave(
    save_filename, p,
    width = 6, height = 4 * n_distinct(data$grade),
    type = "cairo"
  )
  save_filename
}
