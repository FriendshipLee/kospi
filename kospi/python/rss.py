from bs4 import BeautifulSoup
import requests
import pandas as pd
import schedule
import time
from datetime import date
from datetime import datetime

df = pd.DataFrame()
df["이름"] = ["네이버경제", "연합뉴스", "SBS경제", "매일경제", "JTBC경제"]
df["주소"] = ["https://rss.etnews.com/Section902.xml", "https://www.yna.co.kr/rss/economy.xml", "https://news.sbs.co.kr/news/SectionRssFeed.do?sectionId=02&plink=RSSREADER", "https://www.mk.co.kr/rss/30100041/", "https://news-ex.jtbc.co.kr/v1/get/rss/section/20"]
names = df["이름"]
urls = df["주소"]
# print(date.today())

#스케줄러
def news():

    # 결과 저장할 리스트
    news_data = []
    for name, url in zip(names, urls):
        res = requests.get(url)
        text = res.text
        # print(text)

        soup = BeautifulSoup(text, 'lxml-xml') #xml 파서
        # print(soup)

        for item in soup.select('item'):

            title = item.title.text
            link = item.link.text
            content = item.description.text
            data = {
                "name" : name,
                "title" : title,
                "link" : link,
                "date" : date.today(),
                "content" : content
            }
            news_data.append(data)

    df2 = pd.DataFrame(news_data)
    df2.to_csv(f"./{date.today()}.csv", index=False)
    print("저장!")

    #sql 작성!

schedule.every(10).minutes.do(news) #10분마다

while True:
    if datetime.today().hour == 00 or datetime.today().hour == 0:
        break

    schedule.run_pending()
    time.sleep(2)
