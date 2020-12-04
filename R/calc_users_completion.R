##' Calculate completion status for each user
##'
##' School information is joined into it, too.
##'
##' @title
##' @param users
##' @param school_info
##' @param scores
##' @return
##' @author Liang Zhang
##' @export
calc_users_completion <- function(users, scores, school_info) {
  users %>%
    mutate(is_completed = user_id %in% scores$user_id) %>%
    left_join(school_info, by = "school") %>%
    # let school ordered by education stage
    arrange(edu_stage, school) %>%
    mutate(school = as_factor(school))
}
