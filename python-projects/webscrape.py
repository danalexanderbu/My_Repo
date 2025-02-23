from bs4 import BeautifulSoup
import requests

url = "https://www.atlassian.com/software/jira/download-archives"

page = requests.get(url)

soup = BeautifulSoup(page.content, "html.parser")
print(soup.prettify())