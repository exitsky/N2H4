#' Get Content
#'
#' Get naver news content from links.
#'
#' @param url is naver news link.
#' @param col is what you want to get from news. Defualt is all.
#' @param try_cnt is how many you want to try again if error. Default is 3.
#' @param sleep_time is wait time to try again. Default is rnorm(1).
#' @param async async crawling if it is TRUE. Default is FALSE.
#' @param ... you can use child function params like title_node_info.
#' @return Get data.frame(url,datetime,press,title,body).
#' @export
#' @import stats
#' @import httr
#' @import RCurl
#' @import xml2
#' @import selectr
#' @import rvest
#' @import stringi

getContent <-
  function(url,
           col = c("url", "datetime", "press", "title", "body"),
           try_cnt = 3,
           sleep_time = rnorm(1),
           async = FALSE,
           ...) {
    if (!identical(url, character(0))) {
      tryn <- 0
      ua <- user_agent("N2H4 by chanyub.park <mrchypark@gmail.com>")
      root <- try(httr::GET(url, ua), silent = T)
      while (tryn <= try_cnt && class(root) == "try-error") {
        root <- try(httr::GET(url, ua), silent = T)
        Sys.sleep(abs(rnorm(1)))
        tryn <- tryn + 1
        print(paste0("try again: ", url))
      }
      urlcheck <- root$url

      if (!identical(grep("^http://(news|finance).naver.com", urlcheck),
                     integer(0))) {
        chk <- read_html(root, encoding = "EUC-KR") %>%
          html_nodes("div#main_content div div") %>%
          html_attr("class")
        chk <-  chk[1]

        if (is.na(chk)) {
          chk <- "not error"
        }

        if (RCurl::url.exists(url) &
            "error_msg 404" != chk) {
          html_obj <- read_html(root, encoding = "EUC-KR")
          if (tryn > try_cnt) {
            newsInfo <- data.frame(
              url = url,
              datetime = "try out.",
              edittime = "try out.",
              press = "try out.",
              title = "try out.",
              body = "try out.",
              stringsAsFactors = F
            )
            return(newsInfo[, col])
          }
          title <- getContentTitle(html_obj)
          datetime <- getContentDatetime(html_obj)[1]
          edittime <- getContentDatetime(html_obj)[2]
          press <- getContentPress(html_obj)
          body <- getContentBody(html_obj)

          newsInfo <-
            data.frame(
              url = url,
              datetime = datetime,
              edittime = edittime,
              press = press,
              title = title,
              body = body,
              stringsAsFactors = F
            )

        } else {
          newsInfo <- data.frame(
            url = url,
            datetime = "page is moved.",
            edittime = "page is moved.",
            press = "page is moved.",
            title = "page is moved.",
            body = "page is moved.",
            stringsAsFactors = F
          )

        }
        return(newsInfo[, col])
      } else {
        newsInfo <-
          data.frame(
            url = url,
            datetime = "page is not news section.",
            edittime = "page is not news section.",
            press = "page is not news section.",
            title = "page is not news section.",
            body = "page is not news section.",
            stringsAsFactors = F
          )

      }
      return(newsInfo[, col])
    } else {
      print("no news links")

      newsInfo <- data.frame(
        url = "no news links",
        datetime = "no news links",
        edittime = "no news links",
        press = "no news links",
        title = "no news links",
        body = "no news links",
        stringsAsFactors = F
      )
      return(newsInfo[, col])
    }
  }



#' Get Content Title
#'
#' Get naver news Title from link.
#'
#' @param html_obj "xml_document" "xml_node" using read_html function.
#' @param title_node_info Information about node names like tag with class or id. Default is "div.article_info h3" for naver news title.
#' @param title_attr if you want to get attribution text, please write down here.
#' @return Get character title.
#' @export
#' @import xml2
#' @import rvest

getContentTitle <-
  function(html_obj,
           title_node_info = "div.article_info h3",
           title_attr = "") {
    if (title_attr != "") {
      title <-
        html_obj %>% html_nodes(title_node_info) %>% html_attr(title_attr)
    } else{
      title <- html_obj %>% html_nodes(title_node_info) %>% html_text()
    }
    Encoding(title) <- "UTF-8"
    return(title)
  }


#' Get Content Datetime
#'
#' Get naver news published datetime from link.
#'
#' @param html_obj "xml_document" "xml_node" using read_html function.
#' @param datetime_node_info Information about node names like tag with class or id. Default is "div.article_info h3" for naver news title.
#' @param datetime_attr if you want to get attribution text, please write down here.
#' @param getEdittime if TRUE, can get POSIXlt type datetime length 2 means published time and final edited time. if FALSE, get Date length 1.
#' @return Get POSIXlt type datetime.
#' @export
#' @import xml2
#' @import rvest

getContentDatetime <-
  function(html_obj,
           datetime_node_info = "span.t11",
           datetime_attr = "",
           getEdittime = TRUE) {
    if (datetime_attr != "") {
      datetime <-
        html_obj %>% html_nodes(datetime_node_info) %>% html_attr(datetime_attr)
    } else{
      datetime <-
        html_obj %>% html_nodes(datetime_node_info) %>% html_text()
    }
    datetime <- as.POSIXlt(datetime)

    if (getEdittime) {
      if (length(datetime) == 1) {
        edittime <- datetime[1]
      }
      if (length(datetime) == 2) {
        edittime <- datetime[2]
        datetime <- datetime[1]
      }
      datetime <- c(datetime, edittime)
      return(datetime)
    }
    return(datetime)
  }


#' Get Content Press name.
#'
#' Get naver news press name from link.
#'
#' @param html_obj "xml_document" "xml_node" using read_html function.
#' @param press_node_info Information about node names like tag with class or id. Default is "div.article_info h3" for naver news title.
#' @param press_attr if you want to get attribution text, please write down here. Defalt is "title".
#' @return Get character press.
#' @export
#' @import xml2
#' @import rvest

getContentPress <-
  function(html_obj,
           press_node_info = "div.article_header div a img",
           press_attr = "title") {
    if (press_attr != "") {
      press <-
        html_obj %>% html_nodes(press_node_info) %>% html_attr(press_attr)
    } else{
      press <- html_obj %>% html_nodes(press_node_info) %>% html_text()
    }
    Encoding(press) <- "UTF-8"
    return(press)
  }

#' Get Content Body.
#'
#' Get naver news body from link.
#'
#' @param html_obj "xml_document" "xml_node" using read_html function.
#' @param body_node_info Information about node names like tag with class or id. Default is "div.article_info h3" for naver news title.
#' @param body_attr if you want to get attribution text, please write down here.
#' @return Get character body content.
#' @export
#' @import xml2
#' @import rvest
#' @import stringi

getContentBody <-
  function(html_obj,
           body_node_info = "div#articleBodyContents",
           body_attr = "") {
    if (body_attr != "") {
      body <-
        html_obj %>% html_nodes(body_node_info) %>% html_attr(body_attr)
    } else{
      body <- html_obj %>% html_nodes(body_node_info) %>% html_text()
    }
    Encoding(body) <- "UTF-8"

    body <- gsub("\r?\n|\r", " ", body)
    body <-
      gsub("// flash .* function _flash_removeCallback\\(\\) \\{\\} ",
           "",
           body)
    body <- stri_trim_both(body)

    return(body)
  }

#' Check Content Summary.
#'
#' Get naver news summary from link.
#'
#' @param html_obj "xml_document" "xml_node" using read_html function.
#' @param summary_node_info Information about node names like tag with class or id. Default is "div.article_info h3" for naver news title.
#' @param summary_attr if you want to get attribution text, please write down here.
#' @return Get character summary content.
#' @export
#' @import rvest
#' @import httr

checkContentSummary <-
  function(html_obj,
           summary_node_info = "div.media_end_head_autosummary",
           summary_attr = "") {
    if (summary_attr != "") {
      chk <-
        html_obj %>% html_nodes(summary_node_info) %>% html_attr(summary_attr)
    } else{
      chk <- html_obj %>% html_nodes(summary_node_info) %>% html_text()
    }
    if (identical(chk, character(0))) {
      chk <- F
    } else {
      chk <- T
    }

    return(chk)
  }



#' Get Content Summary.
#'
#' Get naver news summary from link.
#'
#' @param root is naver news link.
#' @return Get character summary content.
#' @export
#' @import rvest
#' @import httr

getContentSummary <- function(root) {
  params <- strsplit(root, "=|&")[[1]]
  oid <- params[grep("oid", params) + 1]
  aid <- params[grep("aid", params) + 1]
  tar <- paste0("http://tts.news.naver.com/article/",
                oid,
                "/",
                aid,
                "/summary")
  summ <-
    GET(tar) %>%
    content("parsed")
  summ<-gsub("<br/>", " ", summ$summary)
  summ<-gsub("  ", " ", summ$summary)

  return(summ)
}
