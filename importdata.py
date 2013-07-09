import leveldb
import json

db = leveldb.LevelDB("adhl.leveldb", error_if_exists=True)

count = 0;

for line in file("adhl.json"):
    line = json.loads(line)

    count = count + 1
    if count % 1000 == 0:
        print count

    if line[0] == "faust":
        db.Put("faust:" + str(line[1]), '{"klynge":"' + (str(line[2])) + '"}')
        try:
            klynge = json.loads(db.Get("klynge:" + str(line[2])))
        except:
            klynge = {}
            klynge["faust"] = []
        klynge["faust"].append(str(line[1]))
        db.Put("klynge:" + str(line[2]), json.dumps(klynge))
    elif line[0] == "adhl":
        try:
            obj = json.loads(db.Get("klynge:" + str(line[1])))
            obj["adhl"] = line[2]
            db.Put("klynge:" + str(line[1]), json.dumps(obj))
        except:
            pass

for key, val in db.RangeIter("klynge:10046065", "klynge:10046105"):
        print key, val
