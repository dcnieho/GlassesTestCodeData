#!/usr/bin/python

import sys
import argparse
import os
import math
import bisect

import cv2
import numpy as np
import csv
from csv import DictReader

from ffpyplayer.player import MediaPlayer
import time

class Gaze:
    def __init__(self, x, y, confidence):
        self.x = x
        self.y = y
        self.confidence = confidence
        self.ux = x
        self.uy = y
        self.xCm = -1
        self.yCm = -1


    def draw(self, img):
        x = int(self.x)
        y = int(self.y)
        g = 255 * self.confidence
        r = 255 * (1 - g)
        b = 0
        cv2.circle(img, (x, y), 15, (b, g, r), 5)



class Timestamp2Index:
    def __init__(self, fileName):
        self.indexes = []
        self.timestamps = []
        with open(fileName, 'r' ) as f:
            reader = DictReader(f, delimiter='\t')
            for entry in reader:
                self.indexes.append(int(float(entry['frameNum'])))
                self.timestamps.append(1e-3*float(entry['timestamp']))

    def find(self, ts):
        idx = min(bisect.bisect(self.timestamps, ts), len(self.indexes)-1)
        return self.indexes[idx]



def isOffsetMeaningful(offset):
    return abs(offset) > 0.1


def process(inputDir):
    cv2.namedWindow("frame",cv2.WINDOW_NORMAL)

    cap = cv2.VideoCapture( os.path.join(inputDir, 'worldCamera.mp4') )
    t2i = Timestamp2Index( os.path.join(inputDir, 'frame_timestamps.tsv') )
    ff_opts = {'vn' : False, 'volume': 1. }#{'sync':'video', 'framedrop':True}
    player = MediaPlayer(os.path.join(inputDir, 'worldCamera.mp4'), ff_opts=ff_opts)
    while player.get_metadata()['src_vid_size'] == (0, 0):
        time.sleep(0.01)
    frame_size = player.get_metadata()['src_vid_size']
    frateInfo  = player.get_metadata()['frame_rate']
    frate = float(frateInfo[0])/frateInfo[1]
    print(frateInfo,frate)
    width = int(frame_size[0])
    height = int(frame_size[1])
    val = ''
    cvImg = np.zeros((height, width, 3))
    print(np.shape(cvImg))

    # Read gaze data
    gazes = {}
    with open( os.path.join(inputDir, 'gazeData_world.tsv'), 'r' ) as f:
        reader = DictReader(f, delimiter='\t')
        for entry in reader:
            frame_idx = int(float(entry['frame_idx']))
            confidence = float(entry['confidence'])
            try:
                gx = float(entry['norm_pos_x']) * width
                gy = float(entry['norm_pos_y']) * height
                gaze = Gaze(gx, gy, confidence)
                if frame_idx in gazes:
                    gazes[frame_idx].append(gaze)
                else:
                    gazes[frame_idx] = [ gaze ]
            except Exception as e:
                sys.stderr.write(str(e) + '\n')
                sys.stderr.write('[WARNING] Problematic entry: %s\n' % (entry) )


    # Read ground truth and transformation
    gt = {}
    transformation = {}
    with open( os.path.join(inputDir, 'transformations.tsv'), 'r' ) as f:
        reader = csv.DictReader(f, delimiter='\t')
        for entry in reader:
            frame_idx = int(entry['frame_idx'])

            # ground truth pixel position in undistorted image
            tmp = entry['gt'].split(',')
            gt[frame_idx] = ( float(tmp[0]), float(tmp[1]) )

    lastIdx = None
    while val != 'eof':
        frame, val = player.get_frame(True)
        if val != 'eof' and frame is not None:
            img, video_pts = frame
            #cvImg = np.reshape(np.asarray(img.to_bytearray()[0]), (height, width, 3)).copy()
            #cvImg = cv2.cvtColor(cvImg, cv2.COLOR_RGB2BGR)
            audio_pts = player.get_pts()    # this is audio_pts because we're in default audio sync mode

            # assumes the frame rate is constant, which is dangerous (frame drops and what not)
            #idx = math.floor(video_pts*frate)

            # the audio is my shepherd and nothing shall I lack :-)
            # From the experience, PROP_POS_MSEC is utterly broken; let's use indexes instead
            idx = t2i.find(audio_pts) - 1   # opencv starts at 0; processed data at 1
            idxOffset = cap.get(cv2.CAP_PROP_POS_FRAMES) - idx
            if abs(idxOffset) > 0:
                cap.set(cv2.CAP_PROP_POS_FRAMES, idx)
            if lastIdx is None or lastIdx!=idx:
                # print(idx,cap.get(cv2.CAP_PROP_FRAME_COUNT))
                ret, cvImg = cap.read()

                if idx in gazes:
                    for gaze in gazes[idx]:
                        gaze.draw(cvImg)

                if idx in gt:
                    x = int(round(gt[idx][0]))
                    y = int(round(gt[idx][1]))
                    cv2.line(cvImg, (x,0), (x,int(height)),(0,255,0),2)
                    cv2.line(cvImg, (0,y), (int(width),y),(0,255,0),2)

                cv2.rectangle(cvImg,(0,int(height)),(int(0.25*width),int(height)-30), (0,0,0), -1)
                cv2.putText(cvImg, ("%8.2f [%6d]" % (audio_pts, idx) ), (0, int(height)-5), cv2.FONT_HERSHEY_PLAIN, 2, (0,255,255),2)

                cv2.imshow("frame", cvImg)
                if width>1280:
                    cv2.resizeWindow('frame', 1280,720)
                lastIdx = idx

            key = cv2.waitKey(1) & 0xFF
            if key == ord('k'):
                player.seek(audio_pts+10, relative=False)
            if key == ord('j'):
                player.seek(max(0,audio_pts-10), relative=False)
            if key == ord('l'):
                player.seek(audio_pts+5, relative=False)
            if key == ord('h'):
                player.seek(max(0,audio_pts-5), relative=False)
            if key == ord('p'):
                player.toggle_pause()
            if key == ord('q'):
                break

    cap.release()



if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('inputDir', help='path to the input dir')
    args = parser.parse_args()

    if not os.path.isdir(args.inputDir):
        print('Invalid input dir: {}'.format(args.inputDir))
        sys.exit()
    else:
        # run preprocessing on this data
        process(args.inputDir)
