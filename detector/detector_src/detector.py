import numpy as np
import cv2
import redis
import pickle
import os
import torch
import time

r = redis.Redis(host=os.getenv("HOST"))
conf_treshold =float(os.getenv("CONFIDENCE_THRESHOLD"))
output_key_lst = os.getenv("OUTPUT_QUEUE").split(',')
input_key = str(os.getenv("INPUT_QUEUE"))
max_len = int(os.getenv("QUEUE_LENGTH"))
env_width = int(os.getenv("WIDTH"))
env_height = int(os.getenv("HEIGHT"))
modelPath = str(os.getenv("MODEL_FILE"))
net = cv2.dnn.readNet(modelPath)
inference_mode = str(os.getenv("INFERENCE_MODE"))

inference_mode = "cpu"  # if you wanna start with gpu, comment this line
if inference_mode == "gpu":
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu" )
                          
else:
    device =torch.device("cpu")

if device.type == 'cuda':
    net.setPreferableBackend(cv2.dnn.DNN_BACKEND_CUDA)
    net.setPreferableTarget(cv2.dnn.DNN_TARGET_CUDA)
else:
    net.setPreferableBackend(cv2.dnn.DNN_BACKEND_OPENCV)
    net.setPreferableTarget(cv2.dnn.DNN_TARGET_CPU)
    
def format_yolov5(frame):
    row, col, _ = frame.shape
    _max = max(col, row)
    result = np.zeros((_max, _max, 3), np.uint8)
    result[0:row, 0:col] = frame
    return result

def detect(image):
    input_image = format_yolov5(image) 
    blob = cv2.dnn.blobFromImage(input_image , 1/255.0, (640, 640), swapRB=True)
    net.setInput(blob)
    predictions = net.forward()


    class_ids = []
    confidences = []
    boxes = []

    output_data = predictions[0]

    image_width, image_height, _ = input_image.shape
    x_factor = image_width / env_width
    y_factor =  image_height / env_height

    for r in range(25200):
        row = output_data[r]
        confidence = row[4]
        if confidence >= conf_treshold:
            classes_scores = row[5:]
            _, _, _, max_indx = cv2.minMaxLoc(classes_scores)
            class_id = max_indx[1]
            if (classes_scores[class_id] > .25):

                confidences.append(confidence)

                class_ids.append(class_id)

                x, y, w, h = row[0].item(), row[1].item(), row[2].item(), row[3].item() 
                left = 180 - (x - 0.5 * w) * x_factor
                top = 90 - (y - 0.5 * h) * y_factor
                left = round(left, 5)
                top = round(top, 5)
                width = w * x_factor
                height = h * y_factor
                box = np.array([left, top, width, height])
                boxes.append(box)


    indexes = cv2.dnn.NMSBoxes(boxes, confidences, 0.25, 0.45) 

    result_class_ids = []
    result_confidences = []
    result_boxes = []

    for i in indexes:
        result_confidences.append(confidences[i])
        result_class_ids.append(class_ids[i])
        result_boxes.append(boxes[i])
    return result_class_ids, result_boxes, result_confidences


result_list = []
end=0
while True:
    start = time.time()
    pickled_imgList = r.rpop(input_key)
    if pickled_imgList == None:
        continue
    imageList = pickle.loads(pickled_imgList)

    for item in imageList:
        ts = item[0]
        image = item[1]
        result_class_ids, result_boxes, result_confidences = detect(image)
        lst = [result_class_ids, result_boxes, result_confidences]
        result_list.append([ts,lst])
        for key in output_key_lst:
            if r.llen(str(key)) > max_len:
                print("queue is full !!!!!")
                continue
            pickled_rstList = pickle.dumps(result_list)
            r.rpush(str(key), pickled_rstList)
            end = time.time()
    print("fps:"+str(1/(end-start)))
    