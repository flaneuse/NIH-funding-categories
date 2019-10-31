library(tidyverse)
library(readxl)
library(rvest)
library(data.table)


# functions ---------------------------------------------------------------
html2DF= function(filename) {
  html = read_html(filename) 
  # nested under <style>... pull out <style>, convert to text, then read back as html and pull out <table>
  # convoluted, eh?
  df = html %>% html_nodes("style") %>% 
    html_text() %>% 
    read_html() %>% 
    html_node("table") %>% 
    html_table() %>% 
    # clean up weird carriage returns
    mutate_each(function(x) x %>% str_replace_all("\\\r", "") %>% str_replace_all("\\\n", "") %>% str_squish()) %>% 
    mutate(amount = parse_number(Amount %>% str_replace_all("\\, ", ",")))
  return(df)
}

compile_NIH_funding = function(directory="GitHub/NIH-funding-categories/data"){
  files = list.files(directory, full.names = TRUE)
  
  files = files[files %like% ".xls"]
  
  counter = 0
  
  all_data = tibble()
  
  for(filename in files) {
    print(filename)
    df = html2DF(filename)
    # all_data = bind_rows(all_data, df)
    counter = counter + 1
    write_tsv(df, str_replace(filename, ".xls", ".tsv"))
    
    if(counter %% 10 == 0) {
      print(str_c(counter, " files read and compiled"))
      # write_tsv(all_data, "GitHub/NIH-funding-categories/data/NIH_categories.tsv")
      # write(jsonlite::toJSON(all_data), "GitHub/NIH-funding-categories/data/NIH_categories.json")
    }
  }
  # write_tsv(all_data, "GitHub/NIH-funding-categories/data/NIH_categories_all.tsv")
  # write(jsonlite::toJSON(all_data), "GitHub/NIH-funding-categories/data/NIH_categories_all.json")
  
  return(all_data)
}

compile_NIH_funding_files = function(directory="GitHub/NIH-funding-categories/data"){
  files = list.files(directory, full.names = TRUE)
  
  files = files[files %like% ".tsv"]
  
  counter = 0
  
  all_data = tibble()
  
  for(filename in files) {
    df = read_tsv(filename, col_types = cols())
    all_data = bind_rows(all_data, df)
    counter = counter + 1
    
    if(counter %% 10 == 0) {
      print(str_c(counter, " files read and compiled"))
    }    
    if(counter %% 100 == 0) {
      write_tsv(all_data, "GitHub/NIH-funding-categories/data/NIH_categories.tsv")
      write(jsonlite::toJSON(all_data), "GitHub/NIH-funding-categories/data/NIH_categories.json")
    }
  }
  write_tsv(all_data, "GitHub/NIH-funding-categories/data/NIH_categories_all.tsv")
  write(jsonlite::toJSON(all_data), "GitHub/NIH-funding-categories/data/NIH_categories_all.json")
  
  return(all_data)
}


df = compile_NIH_funding()
df = compile_NIH_funding_files()


# renaming for convenience ------------------------------------------------
df = df %>% rename(funder = `Funding IC`, id = `Project Number`,
                   title = `Project Title`, subprojectID = `Sub Project #`,
                   PI = `PI Name`, org = `Org Name`, location = `State / Country`, 
                   category = Category)

# checks / getting to know the data ---------------------------------------
df %>% select(`Project Number`, )


# summary stats -----------------------------------------------------------
cat_count = df %>% group_by(FY, category) %>% count(id) %>% ungroup() %>% count(n)

df %>% nrow()
df %>% dplyr::select(FY, id, category) %>% distinct() %>% count(FY, id) %>% arrange(desc(n))
hist = df %>% dplyr::select(FY, id, category) %>% distinct() %>% count(FY, id) %>% ungroup() %>% count(n)

df %>% filter(id == "4P30CA006516-51", FY =="2016") %>% select(category) %>% distinct()

ggplot(hist, aes(x = n, y = nn)) + geom_bar(stat="identity")

df %>% group_by(funder) %>% count(category) %>% filter(funder =="NIAID", n > 200) %>% arrange(desc(n)) %>% ggplot(aes(x=forcats::fct_reorder(category, n), y=n)) + geom_bar(stat="identity") + coord_flip()
