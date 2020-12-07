##' Cleanse users based on arbitrary rules
##'
##' Users from some schools should only be partly included, but the rule is
##' arbitrary and dirty. These works are done here.
##'
##' @title
##' @param users_raw
##' @param scores
##' @return
##' @author Liang Zhang
##' @export
munge_users <- function(users_raw, scores) {
  users_raw %>%
    filter(
      # only include these classes for this school
      school != "成都市第五十二中学" |
        class %in% c("1班", "2班"),
      !grade %in% c("二年级", "六年级")
    ) %>%
    # only include those participated for these schools
    anti_join(
      users_raw %>%
        filter(str_detect(school, "成都教科院附属学校")) %>%
        anti_join(scores, by = "user_id"),
      by = "user_id"
    )
}
