import cv2
import json
import threading
import numpy as np
import os
import time

os.environ["OPENCV_FFMPEG_CAPTURE_OPTIONS"] = "rtsp_transport;tcp|probesize;32|analyzeduration;0|fflags;nobuffer"

class VideoStream:
    def __init__(self, url, name, crop_mode="none"):
        self.url = url
        self.name = name
        self.crop_mode = crop_mode # "top_half", "bottom_half", "left_half", "right_half" or "none"
        self.stream = None
        self.frame = None
        self.stopped = False
        self.connected = False

    def start(self):
        t = threading.Thread(target=self.update, args=(), daemon=True)
        t.start()
        return self

    def update(self):
        while not self.stopped:
            if not self.connected:
                cap = cv2.VideoCapture(self.url, cv2.CAP_FFMPEG)
                if cap.isOpened():
                    self.stream = cap
                    self.connected = True
                else:
                    time.sleep(2)
                    continue
            ret, frame = self.stream.read()
            if ret:
                self.frame = frame
            else:
                self.connected = False
                if self.stream: self.stream.release()
                time.sleep(1)

    def get_frame(self, target_size):
        if self.frame is not None:
            h, w = self.frame.shape[:2]
            
            if self.crop_mode == "top_half":
                temp_frame = self.frame[0:h//2, 0:w]
            elif self.crop_mode == "bottom_half":
                temp_frame = self.frame[h//2:h, 0:w]
            elif self.crop_mode == "left_half":
                temp_frame = self.frame[0:h, 0:w//2]
            elif self.crop_mode == "right_half":
                temp_frame = self.frame[0:h, w//2:w]
            else:
                temp_frame = self.frame

            return cv2.resize(temp_frame, target_size)
        
        black_frame = np.zeros((target_size[1], target_size[0], 3), np.uint8)
        cv2.putText(black_frame, f"Loading: {self.name}", (20, target_size[1]//2), 
                    cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)
        return black_frame

def main():
    with open('config.json') as f:
        config = json.load(f)

    streams = []
    for s_config in config['streams']:
        s = VideoStream(
            url=s_config['url'], 
            name=s_config.get('name', 'Cam'),
            crop_mode=s_config.get('crop', 'none')
        ).start()
        streams.append(s)

    grid_w = config.get('grid_width', 2)
    is_fullscreen = config.get('fullscreen', False)
    tile_w, tile_h = 640, 360
    
    window_name = "SEEGRID"
    cv2.namedWindow(window_name, cv2.WINDOW_NORMAL)
    
    if is_fullscreen:
        cv2.setWindowProperty(window_name, cv2.WND_PROP_FULLSCREEN, cv2.WINDOW_FULLSCREEN)

    while True:
        frames = [s.get_frame((tile_w, tile_h)) for s in streams]
        
        while len(frames) % grid_w != 0:
            frames.append(np.zeros((tile_h, tile_w, 3), np.uint8))

        rows = []
        for i in range(0, len(frames), grid_w):
            row = np.hstack(frames[i:i+grid_w])
            rows.append(row)
        
        grid = np.vstack(rows)
        cv2.imshow(window_name, grid)

        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    for s in streams:
        s.stopped = True
    cv2.destroyAllWindows()

if __name__ == "__main__":
    main()
