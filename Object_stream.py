# -*- coding: utf-8 -*-
# © 2012, Mark Stam digistam@gmail.com 
# Alle rechten voorbehouden.
# Niets uit dit script mag worden verveelvoudigd, opgeslagen in een geautomatiseerd gegevensbestand en/of openbaar gemaakt in enige vorm of op enige wijze, hetzij elektronisch, mechanisch, door fotokopieën, opnamen of op enige andere manier zonder voorafgaande schriftelijke toestemming van de auteur. 

# IMPORTS
import json
import urllib2
from urllib2 import HTTPError, URLError
# import credentials
import facebookcredentials
_access_token = facebookcredentials.ACCESS_TOKEN

import sqlite3
conn = sqlite3.connect('mh17.db')
conn.text_factory = str
c = conn.cursor()

#import texttable as tt

import time
from time import sleep

# import object list
import facebookobjects

# create table if not exists
table = "CREATE TABLE IF NOT EXISTS stream (id INTEGER PRIMARY KEY AUTOINCREMENT, object_id TEXT, object_name TEXT, post_id TEXT,actor TEXT,actor_id TEXT,date TEXT, message TEXT, story TEXT, comments TEXT, likes INTEGER, application TEXT)"  #% _event_id
c.execute(table)

# create the function
def parse_stream(object_id):
    try:
        print object_id
        # Query the Facebook database
        url = urllib2.Request('https://graph.facebook.com/%s?fields=name,feed.limit(100).fields(from,created_time,likes.limit(100),comments,message,story,application)&access_token=%s' % (_object_id,_access_token))
        parsed_json = json.load(urllib2.urlopen(url))
        #print parsed_json
        dict = []
        for item in parsed_json['feed']['data']:
            #initialize the row
            row = []
            row.append(_object_id)
            row.append(parsed_json['name'].encode('utf-8'))
            row.append(item['id'])
            row.append(item['from']['name'].encode('utf-8'))
            row.append(item['from']['id'])
            row.append(item['created_time'])
            
            if item.has_key("message"):
                row.append(item['message'].encode('utf-8'))
            else:
                row.append(' ')
            if item.has_key("story"):
                row.append(item['story'].encode('utf-8'))
            else:
                row.append(' ')
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
                    row.append(parsed_json['name'].encode('utf-8'))
                    row.append(item['comments']['data'][i]['id'])
                    row.append(item['comments']['data'][i]['from']['name'].encode('utf-8'))
                    row.append(item['comments']['data'][i]['from']['id'])
                    row.append(item['comments']['data'][i]['created_time'])
                    row.append(item['comments']['data'][i]['message'].encode('utf-8'))
                    #print item['comments']['data'][i]['like_count']
                    row.append('')
                    row.append('')
                    row.append('')
                    row.append('')
                    dict.append(row)
            except KeyError, e:
                e

            #print row
            sql = "INSERT INTO stream (object_id, object_name, post_id, actor, actor_id, date, message, story, comments, likes, application) VALUES (?,?,?,?,?,?,?,?,?,?,?)" #% _event_id
            c.executemany(sql, dict)
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
# remove items from table which have been posted before 2013-01-01
dates = "DELETE FROM stream WHERE date LIKE '%2011%' OR date LIKE '%2012%'"
c.execute(dates)

conn.commit()

conn.close()

