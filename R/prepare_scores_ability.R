##' Calculate scores of abilities to report
##'
##' This will try to calculate several ability scores for each user. Each game
##' has scores of two hierarchies, the lower level are aggregated before the
##' second level. And after aggregation, each user will only has a single
##' participation date (taking the median of all the `game_time`s, stored as
##' `assess_time` in data).
##'
##' @title
##' @param scores
##' @param abilities
##' @return
##' @author Liang Zhang
##' @export
prepare_scores_ability <- function(scores, abilities) {
  scores %>%
    left_join(abilities, by = "game_id") %>%
    group_by(user_id) %>%
    mutate(assess_time = median(game_time)) %>%
    group_by(user_id, assess_time, ab_name_first, ab_name_second) %>%
    summarise(score = mean(game_score_std), .groups = "drop") %>%
    group_by(user_id, assess_time, ab_name_first) %>%
    summarise(score = round(mean(score)), .groups = "drop") %>%
    rename(ab_name = ab_name_first)
}
