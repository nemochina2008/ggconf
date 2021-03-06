
#' return resulted strings of approximate string match
#'
#' @param fuzzy_input A character. Typically user input.
#' @param possibilities A character vector one of which
#'                      is assumed to be pointed by fuzzy_input.
#' @param n_top An integer specifying the number of returned strings.
#' @param case_sensitive Default is FALSE.
#' @param cost A named vector
#' @param threshold If costs are more than threshold,
#'                  remove them from the result
#'                  even if they are within top \code{n_top}.
#'                  Default is 6.
#' @param debug If true, it shows costs for top candidates.
#'
#' \code{get_analogue} is a key function
#' for returning useful compile error message.
#'
#' @examples
#'
#' get_analogue("axis.txt", c("axis.text", "axis.text.x", "axis.ticks"))
#' # returns "axis.text" "axis.text.x" "axis.ticks"
#' 
#' get_analogue("p.bg", c("plot.background", "panel.background"))
#' # returns "plot.background" as first, and then "panel.background"
#' 
#'
#' @importFrom utils adist
#' @importFrom stats na.omit
#' @export
get_analogue <- function(fuzzy_input = "axs.txt",
                         possibilities = c("axis.text", "axis.text.x"),
                         n_top = 5, case_sensitive = FALSE,
                         cost = c(
                             "insertions" = .25,
                             "deletions" = 3,
                             "substitutions" = 2
                         ),
                         threshold = 6,
                         debug = FALSE) {

    if (length(possibilities) == 0)
        return(NULL)

    edit_distance_matrix <- adist(fuzzy_input, possibilities,
                                  ignore.case = case_sensitive,
                                  costs = cost)
    sorted <- sort.int(edit_distance_matrix, index.return = TRUE)
    indices <- sorted$ix[1:n_top]
    with_NA <-
        data.frame(name = possibilities[indices],
                   cost = sorted$x[1:n_top],
                   nchar = nchar(possibilities[indices]),
                   index = indices,
                   stringsAsFactors = FALSE)
    # if tie, prefer longer string
    # (prefer "axis.text.x" than "axis.text")
    with_NA <- with(with_NA, with_NA[order(cost, -nchar), ])
    similar_string_df <- na.omit(with_NA)
    
    # customize edit distance
    # If the first char of fuzzy input and target are the same,
    # they tend to be much closer than the naive Levenshtein distance
    # e.g. "l.bg" -> not "plot.background" but "legend.background"
    first_char <- substr(fuzzy_input, 1, 1)
    tgt_first_charv <- substr(similar_string_df$name, 1, 1)
    similar_string_df[first_char == tgt_first_charv, "cost"] <-
        similar_string_df[first_char == tgt_first_charv, "cost"] - 1
    similar_string_df <- similar_string_df[with(similar_string_df, order(cost)), ]
    
    if (debug)
        print(similar_string_df)

    return(similar_string_df[similar_string_df$cost < threshold, ])
}
