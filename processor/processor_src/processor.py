import redis
import pickle
import os
from elasticsearch import Elasticsearch
from datetime import datetime

r = redis.Redis(host=os.getenv("HOST")) 
input_key = str(os.getenv("INPUT_QUEUE"))
es_url = str(os.getenv("ELASTICSEARCH_HOSTS"))

es = Elasticsearch(es_url)
es.info()

index_name = "coords" #elasticsearch index name


# Elasticsearch index mapping properties
mapping = {
    "properties": {
        "timestamp": {"type": "date"},
        "coordinates": {"type": "geo_shape"},
        "class_name": {"type": "text"},
    }
}

#Elasticsearch index template creating
es.options(ignore_status=[400]).indices.create(index=index_name, mappings=mapping)


class_list = []
with open("./processor_src/config_files/classes.txt", "r") as f:
    class_list = [cname.strip() for cname in f.readlines()]

while True:
    pickled_results = r.lpop(input_key)
    if pickled_results == None:
        continue
    resultList = pickle.loads(pickled_results)
    item = resultList[-1]
    box = item[1][1]
    if len(box) > 0:
        last_box = box[-1]
        print(last_box)
    else:
        print("The list 'box' is empty.")
        continue
    top, left, width, height = last_box
    
    polygon_shape = {
        "type": "polygon",
        "coordinates": [  
            [[top, left], [top, left + width], [top + height, left + width], [top + height, left], [top, left]]
        ]
    }

    center_x = round(left+width/2, 5)
    center_y = round(top+height/2, 5)
    point_shape = {
        "type": "point",
        "coordinates": [center_x, center_y]
    }

    key = item[0]
    iso_timestamp = datetime.strptime(key, "%d-%b-%Y(%H.%M.%S.%f)").isoformat()

    class_ids = item[1][0]
    class_counts = {}
    print(f'Timestamp: {key}')
    print('Object Counts:')
    for class_id in class_ids:
        class_name = class_list[class_id]
        if class_name in class_counts:
            class_counts[class_name] += 1
        else:
            class_counts[class_name] = 1
            
        
        for class_name, count in class_counts.items():
            print(f'{class_name}: {count}')
            # Adding element thorough Elasticsearch index element
            response = es.index(
                index=index_name,
                id=key, 
                document={
                    "timestamp": iso_timestamp,
                    "coordinates": point_shape, # polygon_shape
                    "class_name": class_name,
                }
            )
        print(response["result"])