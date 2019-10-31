from selenium import webdriver
import time
import pandas as pd
import requests


requests.get("https://report.nih.gov/categorical_spending.aspx")
from bs4 import BeautifulSoup

url = 'https://report.nih.gov/categorical_spending.aspx'
url_get = requests.get(url)
soup = BeautifulSoup(url_get.content, 'lxml')
links = soup.select("td a.hyperlink")


# should be 288*4 = 1152; 4 extra links that aren't easily removed
len(links)

driver = webdriver.Chrome('/Users/laurahughes/bin/chromedriver')  # Optional argument, if not specified will search path.
# Note: should be 36 + 4 (aka 40) links that are broken
# 36: + values in table; funding category didn't exist that fiscal year
# 4: rando hyperlinks at the
start_idx = 910
for idx, link in enumerate(links):
    if(idx % 10 == 0):
        print(f"{idx}/{len(links)}")
    if(idx >= start_idx):
        try:
            driver.get(f"https://report.nih.gov/{link['href']}");
        except:
            print(f"Uh oh. {link['href']} wasn't a valid link.")
        try:
            download_btn = driver.find_element_by_id('ctl00_ContentPlaceHolder1_ExportDiseasesToXLS')
            download_btn.click()
        except:
            print(f"Uh oh. {link['href']} didn't have a button to press.")
#####
time.sleep(1200) # Pause to make sure downloads complete, or only execute top lines and wait for the rest to finish before closing driver.
driver.quit()
