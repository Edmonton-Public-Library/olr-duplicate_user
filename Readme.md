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
