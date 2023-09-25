import cv2
import time
from datetime import datetime
import redis
import pickle
import os

r = redis.Redis(host=os.getenv("HOST"))

output_key = str(os.getenv("OUTPUT_QUEUE"))
max_len = int(os.getenv("QUEUE_LENGTH"))
frame_dim = os.getenv("FRAME_DIM").split(',')
fps = os.getenv("FPS")

fps = 50 if fps == None else float(fps)

assert len(frame_dim) == 2
assert max_len > 0


RTSP_URL = '**********************************'

capturetime = 1
last_recorded_time = time.time()
cap = cv2.VideoCapture(RTSP_URL)

if not cap.isOpened():
    print('Cannot open RTSP stream')
    exit(-1)
    
real_fps_time= 0
while True:
    _, frame = cap.read()
    curr_time = time.time()

    if r.llen(output_key) > max_len:
        continue

    frame = cv2.resize(frame, (int(frame_dim[0]), int(frame_dim[1])))
    cur_fps = 1/ (curr_time - last_recorded_time)

    while cur_fps > fps:
      curr_time = time.time()
      cur_fps  = 1 / (curr_time - last_recorded_time)
    
    if curr_time - real_fps_time >=30:
        print(cur_fps)
        real_fps_time = curr_time

    imageList = []
    now = datetime.now()

    timestampStr = now.strftime("%d-%b-%Y(%H.%M.%S.%f)")
    imageList.append([timestampStr,frame])
    pickled_imgList = pickle.dumps(imageList)
    
    r.lpush(output_key, pickled_imgList)
    last_recorded_time = time.time()