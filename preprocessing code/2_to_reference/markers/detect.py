#!/usr/bin/python

import sys
import argparse
import os

import cv2
import numpy as np
import csv


class Marker:
    def __init__(self, key, center, corners):
        self.key = key
        self.center = center
        self.corners = corners

    def __str__(self):
        ret = '[%s] (%.2f x %.2f)' % (self.key, self.center[0], self.center[1])
        return ret

    def drawCenter(self, frame):
        cv2.circle(frame, (int(round(self.center[0])), int(round(self.center[1]))), 5, (0,255,0), -1)

def getKnownMarkers():
    """ 0,0 is at bottom left"""
    cellSizeCm = 2.61618
    markerHalfSizeCm = 5.9
    markerCenterInGrid = {
            '0'  : (  3,  3 ),
            '1'  : (  3, 14 ),
            '2'  : (  3, 25 ),
            '3'  : ( 20, 25 ),
            '4'  : ( 37, 25 ),
            '5'  : ( 37, 14 ),
            '6'  : ( 37,  3 ),
            '7'  : ( 20,  3 ),
            'gt' : ( 20, 14 ),
            'bl' : (  0,  0 ),
            'tr' : ( 40, 28 ),
        }
    markers = {}
    for key,center in markerCenterInGrid.items():
        c = cellSizeCm * np.array( [ center[0], center[1] ], dtype=np.float )
        # top left and clockwise
        tl = c + np.array( [ -markerHalfSizeCm , markerHalfSizeCm  ] )
        tr = c + np.array( [ markerHalfSizeCm  , markerHalfSizeCm  ] )
        bl = c + np.array( [ -markerHalfSizeCm , -markerHalfSizeCm ] )
        br = c + np.array( [ markerHalfSizeCm  , -markerHalfSizeCm ] )
        markers[key] = Marker(key, c, [ tl, tr, bl, br ])
    return markers

def corners_intersection(corners):
    line1 = ( corners[0], corners[2] )
    line2 = ( corners[1], corners[3] )
    xdiff = (line1[0][0] - line1[1][0], line2[0][0] - line2[1][0])
    ydiff = (line1[0][1] - line1[1][1], line2[0][1] - line2[1][1])

    def det(a, b):
        return a[0] * b[1] - a[1] * b[0]

    div = det(xdiff, ydiff)
    if div == 0:
       raise Exception('lines do not intersect')

    d = (det(*line1), det(*line2))
    x = det(d, xdiff) / div
    y = det(d, ydiff) / div
    return np.array( [x,y], dtype=float)


def makeDetectedMarkers(corners, ids):
    markers = {}
    for i in range(0, len(ids)):
        key = str(ids[i][0])
        c = corners_intersection(corners[i][0])
        markers[key] = Marker(key, c, corners[i][0])
    return markers

def estimateTransform(known, detected):
    pts_src = []
    pts_dst = []
    keys = []
    for key in known.iterkeys():
        if key in detected:
            keys.append(key)
            #pts_src.append( detected[key].center )
            #pts_dst.append( known[key].center )
            pts_src.extend( detected[key].corners )
            pts_dst.extend( known[key].corners )

    if len(pts_src) < 4:
        return None, False

    pts_src = np.float32(pts_src)
    pts_dst = np.float32(pts_dst)

    h, mask = cv2.findHomography(pts_src, pts_dst)

    return h, True


def transform(h, x, y):
    src = np.float32([[ [x,y] ]])
    dst = cv2.perspectiveTransform(src,h)
    return dst[0][0]


def distortPoint(p, cameraMatrix, distCoeffs):
    fx = cameraMatrix[0][0]
    fy = cameraMatrix[1][1]
    cx = cameraMatrix[0][2]
    cy = cameraMatrix[1][2]

    k1 = distCoeffs[0]
    k2 = distCoeffs[1]
    k3 = 0
    k4 = 0
    p1 = 0
    p2 = 0

    x = (p[0] - cx) / fx
    y = (p[1] - cy) / fy

    r2 = x*x + y*y

    dx = x * (1 + k1 * r2 + k2 * r2 * r2 + k3 * r2 * r2 * r2)
    dy = y * (1 + k1 * r2 + k2 * r2 * r2 + k3 * r2 * r2 * r2)

    dx = dx + (2 * p1 * x * y + p2 * (r2 + 2 * x * x))
    dy = dy + (p1 * (r2 + 2 * y * y) + 2 * p2 * x * y)

    p[0] = dx * fx + cx;
    p[1] = dy * fy + cy;

    return p


def process(inputDir):

    save = True
    doUndistort = '/eyerec/' in inputDir or '/pupil-labs/' in inputDir or '/grip/' in inputDir
    cap = cv2.VideoCapture( os.path.join(inputDir, 'worldCamera.mp4') )
    width = float( cap.get(cv2.CAP_PROP_FRAME_WIDTH ) )
    height = float( cap.get(cv2.CAP_PROP_FRAME_HEIGHT ) )

    aruco_dict = cv2.aruco.Dictionary_get(cv2.aruco.DICT_4X4_250)
    parameters = cv2.aruco.DetectorParameters_create()
    parameters.markerBorderBits = 2
    parameters.cornerRefinementMethod = cv2.aruco.CORNER_REFINE_SUBPIX;

    knownMarkers = getKnownMarkers()
    gt = knownMarkers['gt'].center

    fs = cv2.FileStorage("calibration.xml", cv2.FILE_STORAGE_READ)
    cameraMatrix = fs.getNode("cameraMatrix").mat()
    distCoeffs = fs.getNode("distCoeffs").mat()

    w = int(width)
    h = int(height)
    #newCameraMatrix, roi = cv2.getOptimalNewCameraMatrix(cameraMatrix,distCoeffs,(w,h),0)
    #mapx,mapy = cv2.initUndistortRectifyMap(cameraMatrix,distCoeffs,None,newCameraMatrix,(w,h),cv2.CV_16SC2)

    frame_idx = 0
    if save:
        csv_file = open(os.path.join(inputDir, 'transformations.tsv'), 'w')
        csv_writer = csv.writer(csv_file, delimiter='\t')
        csv_writer.writerow( ['frame_idx', 'transformation', 'gt'] ) 

    while(True):
        # Capture frame-by-frame
        ret, frame = cap.read()
        if not ret:
            break

        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY);

        if doUndistort:
            #gray = cv2.remap(gray,mapx,mapy,cv2.INTER_LINEAR)
            gray = cv2.undistort(gray, cameraMatrix, distCoeffs)

        corners, ids, rejectedImgPoints = cv2.aruco.detectMarkers(gray,
                aruco_dict, parameters=parameters)

        if np.all(ids != None):
            if len(ids) >= 4:
                detectedMarkers = makeDetectedMarkers(corners, ids)

                H, status = estimateTransform(knownMarkers, detectedMarkers);
                if status:
                    iH = np.linalg.inv(H)
                    target = transform(iH, gt[0], gt[1])
                    if doUndistort:
                        target = distortPoint( target, cameraMatrix, distCoeffs)
                    if target[0] >= 0 and target[0] < width and target[1] >= 0 and target[1] < height:
                        H_str = '' 
                        for row in H:
                            for col in row:
                                H_str += '%f,' % (col)
                        gt_str = '%f,%f,' % ( target[0], target[1] )
                        if save:
                            csv_writer.writerow([ frame_idx, H_str, gt_str] )
                        x = int(round(target[0]))
                        y = int(round(target[1]))
                        cv2.line(frame, (x,0), (x,h),(0,255,0),1)
                        cv2.line(frame, (0,y), (w,y),(0,255,0),1)
                        #cv2.circle(frame, (target[0], target[1]), 5, (0,255,0), -1)

                cv2.aruco.drawDetectedMarkers(frame, corners, ids)

        #cv2.imshow('frame',frame)


        frame_idx += 1
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    if save:
        csv_file.close()
    cap.release()
    cv2.destroyAllWindows()


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
