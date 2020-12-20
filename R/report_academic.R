##' Load academic scores from given file
##'
##' @title
##' @param file_scores_academic
##' @param users_joined
##' @return
##' @author Liang Zhang
##' @export
load_academic <- function(file_scores_academic, users_joined) {
  read_csv(file_scores_academic, col_types = cols()) %>%
    pivot_longer(ends_with("学期"), values_to = "score") %>%
    separate(name, c("subject", "term"), sep = "\\.") %>%
    mutate(出生日期 = as.character(出生日期)) %>%
    inner_join(
      users_joined,
      by = c(
        "姓名" = "user_name",
        "性别" = "user_sex",
        "年级" = "grade",
        "出生日期" = "user_dob"
      )
    ) %>%
    select(user_id, term, subject, score)
}

##' Plot scatter plots
##'
##' @title
##' @param scores_game_academic
##' @param game_index
##' @return
##' @author Liang Zhang
##' @export
plot_academic <- function(scores_game_academic, game_index) {
  game_name <- unique(scores_game_academic$game_name)
  save_filename <- fs::path("image", str_glue("预测学业成绩-{game_name}.png"))
  p <- ggplot(scores_game_academic, aes(game_score_raw, score)) +
    geom_point() +
    stat_smooth(method = "lm", formula = y ~ x) +
    facet_grid(subject ~ term) +
    stat_cor(
      cor.coef.name = "r", r.accuracy = 0.01, p.accuracy = 0.001,
      label.y.npc = "bottom", show.legend = FALSE
    ) +
    labs(x = "认知测评得分", y = "考试成绩", title = game_name) +
    theme_light() +
    theme(
      legend.key = element_rect(fill = "transparent"),
      plot.title = element_text(hjust = 0.5)
    )
  ggsave(
    save_filename, p,
    width = 6, height = 6,
    type = "cairo"
  )
  save_filename
}

