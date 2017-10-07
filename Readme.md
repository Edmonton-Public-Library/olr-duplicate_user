Duplicate user project
----------------------
The duplicate user project is a service that tests if submitted information represents a user already registered in the ILS. To do this, a RESTful service is offered that can query user information and make descessions about the likelyhood of the customer already being registered.

Directory Structure
-------------------
- Readme.md
- service.sh - starts and stops the duplicate user database (elasticsearch).
- elasticsearch.pid - temporary file that contains the PID of the elasticsearch instance. Disappears when elasticsearch is not running.
-+ scripts - Python scripts for fetching, JSON-ifying, and loading user data.
-+ elasticsearch-5.2.0 - contains binaries, shards, and log files of the elasticsearch instance.
- .gitignore - list of items that should not go into the repo.
- .git - directory of git repo.
- elasticsearch-5.2.0.tar.gz - install tarball of elasticsearch.
+ delete/ - delete directory. By default duplicate_user.py looks for a users.lst here. the file should contain all the keys you wish to delete from the database, one-per-line (no trailing pipes '|'). Once created you can run ```make delete``` to delete these customers.
+ incoming/ - directory where all the customer data is to be loaded. The file is in the form of 'UKEY|FNAME|LNAME|EMAIL|DOB|' and can be readily made from Symphony API. Once SCP'ed over to this directory type ```make load``` in the project home directory and the script will load the customer data.

cURL requests
-------------
The service connects on HTTPS so if you are testing internally, use '-k' on cURL to avoid certificate smozzle.
To test the status:
curl -XGET -k 'https://localhost:8124/status'
{"status":"OK","details":{"service":"up","user_count":431373}}

To test if a customer is a duplicate:
curl -XGET -k 'https://epl-olr.epl.ca:8124/check_duplicate?lname=Balzac&fname=William&dob=1900-01-01&email=ilsadmins@epl.ca'
{"status":"OK","details":{"duplicate":true}}

'https://epl-olr.epl.ca:8124/check_duplicate?lname=Balzac&fname=William&dob=1900-01-01&email=ilsadminds@fpl.ca'
{"status":"OK","details":{"duplicate":true}}

'https://epl-olr.epl.ca:8124/check_duplicate?lname=Balzac&fname=William&dob=1900-01-02&email=ilsadmins@epl.ca'
{"status":"OK","details":{"duplicate":false}}

JSON-ifying
-----------
In single user insert (testing) mode.
```
curl -i -XPUT 'http://localhost:9200/epl/duplicate_user_test/1' -d'{"fname":"Douglas", "lname":"Fir", "dob":"20010111", "email":"d.fur@gmail.com"}'
```
In batch mode.
```
curl -XPOST 'localhost:9200/epl/duplicate_user_test/_bulk?pretty&pretty' -H 'Content-Type: application/json' -d'
{"index":{"_id":"2"}}
{"fname":"Dave", "lname":"Fir", "dob":"20100111", "email":"dave.fur@gmail.com" }
{"index":{"_id":"3"}}
{"fname":"Jane", "lname":"Doe", "dob":"20100111", "email":"jdoe@gmail.com" }
'

{
  "took" : 39,
  "errors" : false,
  "items" : [
    {
      "index" : {
        "_index" : "epl",
        "_type" : "duplicate_user_test",
        "_id" : "2",
        "_version" : 1,
        "result" : "created",
        "_shards" : {
          "total" : 2,
          "successful" : 1,
          "failed" : 0
        },
        "created" : true,
        "status" : 201
      }
    },
    {
      "index" : {
        "_index" : "epl",
        "_type" : "duplicate_user_test",
        "_id" : "3",
        "_version" : 1,
        "result" : "created",
        "_shards" : {
          "total" : 2,
          "successful" : 1,
          "failed" : 0
        },
        "created" : true,
        "status" : 201
      }
    }
  ]
}
```

Deleting objects from the database
----------------------------------
```
curl -XGET 'http://localhost:9200/epl/duplicate_user_test/1382905?pretty'
{
  "_index" : "epl",
  "_type" : "duplicate_user_test",
  "_id" : "1382905",
  "_version" : 1,
  "found" : true,
  "_source" : {
    "fname" : "Balzac",
    "lname" : "Billy",
    "email" : "ilsadmins@hotmail.com",
    "dob" : "19751015"
  }
}
curl -XDELETE 'http://localhost:9200/epl/duplicate_user_test/1382905?pretty'
{
  "found" : true,
  "_index" : "epl",
  "_type" : "duplicate_user_test",
  "_id" : "1382905",
  "_version" : 2,
  "result" : "deleted",
  "_shards" : {
    "total" : 2,
    "successful" : 1,
    "failed" : 0
  }
}
curl -XGET 'http://localhost:9200/epl/duplicate_user_test/1382905?pretty'
{
  "_index" : "epl",
  "_type" : "duplicate_user_test",
  "_id" : "1382905",
  "found" : false
}
```
Example of setting properties on new index
------------------------------------------
From http://stackoverflow.com/questions/21876857/elasticsearch-index-creation-with-mapping
```
{
    "settings":{
        "analysis":{
            "analyzer":{
                "analyzer1":{
                    "type":"custom",
                    "tokenizer":"standard",
                    "filter":[ "standard", "lowercase", "stop", "kstem", "ngram" ]
                }
            },
            "filter":{
                "ngram":{
                    "type":"ngram",
                    "min_gram":2,
                    "max_gram":15
                }
            }
        }
    },
    "mappings": {
        "product": {
            "properties": {
                "title": {
                    "type": "string",
                    "search_analyzer" : "analyzer1",
                    "index_analyzer" : "analyzer1"
                }
            }
        }
    }
}
```
