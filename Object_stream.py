# -*- coding: utf-8 -*-
# © 2012, Mark Stam digistam@gmail.com 
# Alle rechten voorbehouden.
# Niets uit dit script mag worden verveelvoudigd, opgeslagen in een geautomatiseerd gegevensbestand en/of openbaar gemaakt in enige vorm of op enige wijze, hetzij elektronisch, mechanisch, door fotokopieën, opnamen of op enige andere manier zonder voorafgaande schriftelijke toestemming van de auteur. 

# IMPORTS
import json
import urllib2
from urllib2 import HTTPError, URLError
# credentials
_access_token = "CAACEdEose0cBAGaAmZA9BCa0eb8WqgJspq4nzpkEy5UhiiVKKj8w2GmZCHkmi0FlKKcPJxQAhOuOuutmQFh4gnba7qLXpAwAvyvOJF5ZA7nZCHZB9R54az0aXIf9HVZB2MZACj7R34lbYrKikbZB4k9KxYpFckdz17m3gftAPh7IIc9hRePKa0CM3IXwRqttAeEZAPSl8ShAIVgEQbFVp4ZBXX"

import sqlite3
conn = sqlite3.connect('avifauna.db')
conn.text_factory = str
c = conn.cursor()

import time
from time import sleep

# import object list
import facebookobjects

# create table if not exists
table = "CREATE TABLE IF NOT EXISTS stream (id INTEGER PRIMARY KEY AUTOINCREMENT, object_id TEXT, type TEXT, object_name TEXT, post_id TEXT,actor TEXT,actor_id TEXT,actor_pic TEXT, date TEXT, message TEXT, story TEXT, link TEXT, description TEXT, comments TEXT, likes INTEGER, application TEXT)"  #% _event_id
c.execute(table)
likeTable = "CREATE TABLE IF NOT EXISTS likes (id INTEGER PRIMARY KEY AUTOINCREMENT, post_id TEXT, actor TEXT,actor_id TEXT, actor_pic TEXT)"
c.execute(likeTable)

# create the function
def parse_stream(object_id):
    try:
        print object_id
        # Query the Facebook database
        url = urllib2.Request('https://graph.facebook.com/%s?fields=name,feed.limit(100){from,created_time,likes.limit(100),comments,message,story,application,story_tags,link,description,type}&access_token=%s' % (_object_id,_access_token))
        parsed_json = json.load(urllib2.urlopen(url))
        #print parsed_json
        dict = []
        likedict = []
        for item in parsed_json['feed']['data']:
            #initialize the row
            row = []
            row.append(_object_id)
            if item.has_key("type"):
                row.append(item['type'])
            else:
                row.append(' ')
            row.append(parsed_json['name'].encode('utf-8'))
            row.append(item['id'])
            row.append(item['from']['name'].encode('utf-8'))
            row.append(item['from']['id'])
            row.append('<img src=http://graph.facebook.com/' + item['from']['id'] + '/picture>')
            row.append(item['created_time'])           
            if item.has_key("message"):
                row.append(item['message'].encode('utf-8'))
            else:
                row.append(' ')
            if item.has_key("story"):
                row.append(item['story'].encode('utf-8'))
            else:
                row.append(' ')
            if item.has_key("link"):
                row.append('<a target=_blank href=' + item['link'] + '>' + item['link'] + '</a>')
            else:
                row.append('')
            if item.has_key("description"):
                row.append(item['description'])
            else:
                row.append('')
            try:
                countComments = [] # aantal comments
                for i in range(len(item['comments']['data'])):
                    countRow = []
                    countRow.append(item['comments']['data'][i]['id'])
                    countComments.append(countRow)
                row.append(len(countComments))
            except KeyError, e:
                row.append(0)
            try:
                countLikes = []
                for i in range(len(item['likes']['data'])):
                    countRow = []
                    countRow.append(item['likes']['data'][i]['id'])
                    countLikes.append(countRow)
                row.append(len(countLikes))
                for i in range(len(item['likes']['data'])):
                    likeRow = []
                    likeRow.append(item['id'])
                    likeRow.append(item['likes']['data'][i]['name'])
                    likeRow.append(item['likes']['data'][i]['id'])
                    likeRow.append('<img src=http://graph.facebook.com/' + item['likes']['data'][i]['id'] + '/picture>')
                    print likeRow
                    likedict.append(likeRow)
            except KeyError, e:
                row.append(0)
            if item.has_key("application"):
                row.append(item['application']['name'].encode('utf-8'))
            else:
                row.append(' ')
            dict.append(row)
            try:
                for i in range(len(item['comments']['data'])):
                    row = []
                    row.append(_object_id)
                    row.append('comment')
                    row.append(parsed_json['name'].encode('utf-8'))
                    row.append(item['comments']['data'][i]['id'])
                    row.append(item['comments']['data'][i]['from']['name'].encode('utf-8'))
                    row.append(item['comments']['data'][i]['from']['id'])
                    row.append('<img src=http://graph.facebook.com/' + item['comments']['data'][i]['from']['id'] + '/picture>')
                    row.append(item['comments']['data'][i]['created_time'])
                    row.append(item['comments']['data'][i]['message'].encode('utf-8'))
                    row.append('')
                    row.append('')
                    row.append('')
                    row.append('')
                    row.append('')
                    row.append('')
                    dict.append(row)
            except KeyError, e:
                e

            #print row
            sql = "INSERT INTO stream (object_id, type, object_name, post_id, actor, actor_id, actor_pic, date, message, story, link, description, comments, likes, application) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"
            c.executemany(sql, dict)
            likeSql = "INSERT INTO likes (post_id, actor, actor_id, actor_pic) VALUES (?,?,?,?)"
            c.executemany(likeSql, likedict)
            conn.commit()
    except KeyError, e:
        print "KeyError: %s" % e
    except ValueError, e:
        print "ValueError: %s" % e
    except HTTPError, e:
        print "HTTPError: %s" % e
    except URLError, e:
        print "URLError: %s" % e
# do the magic job
for i in range(len(facebookobjects.objects)):
    _object_id = facebookobjects.objects[i]
    parse_stream(facebookobjects.objects[i])

# remove duplicate items from table
dups = "DELETE FROM stream WHERE id NOT IN (SELECT MAX(id) FROM stream GROUP BY post_id);"
c.execute(dups)
dups = "DELETE FROM likes WHERE id NOT IN (SELECT MAX(id) FROM likes GROUP BY post_id,actor_id);"
c.execute(dups)
# remove items from table which have been posted before 2013-01-01
dates = "DELETE FROM stream WHERE date LIKE '%2011%' OR date LIKE '%2012%'"
c.execute(dates)

conn.commit()

conn.close()

