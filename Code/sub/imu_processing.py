import pandas as pd
from magclassification import *
import numpy as np
from plotting import *


def plot_graph_lim(graph, ylim, title = "title"):
    plt.title(title)
    plt.plot(graph)
    plt.ylim(ylim[0], ylim[1])
    plt.axhline(y=0, color='b', linewidth=1)
    plt.show()
    

class IMU():
    def __init__(self, path):
        self.files = self._process(path)
    
    def _process(self, paths):
        path_lst = os.listdir(paths)
        res = []

        for p in path_lst:
          res.append(paths + "/" + p)

        res = self._path_process(res)
        return res
    
    def _path_process(self, paths):
        res = []

        # paths : NewDatas/Label
        for path in paths:
          label = path.split('/')[-1]
          plist = os.listdir(path)
          plist.sort()

          # plist : NewData/
          for p in plist:
            fp = path + "/" + p
            data = self._csv_to_dic(fp)
            res.append(Feature(label, data, fp))

        return res
    
    def _csv_to_dic(self, csvfile):
        data_dic = {'magX' : [], 'magY' : [], 'magZ' : [], 
                    'accX' : [], 'accY' : [], 'accZ' : [],
                    'gyroX' : [], 'gyroY' : [], 'gyroZ' : [],
                   }
        
        mag_data = pd.read_csv(csvfile + "/Magnetometer.csv")
        acc_data = pd.read_csv(csvfile + "/Accelerometer.csv")
        gyro_data = pd.read_csv(csvfile + "/Gyroscope.csv")
        
        xyz = ['X', 'Y', 'Z']
        
        for idx in xyz:
            name = 'mag' + idx
            mname = idx + ' (µT)'
            
            data_dic[name] = mag_data[mname]
        
        for idx in xyz:
            name = 'acc' + idx
            aname = idx + ' (m/s^2)'
            
            data_dic[name] = acc_data[aname]
        
        for idx in xyz:
            name = 'gyro' + idx
            gname = idx + ' (rad/s)'
            
            data_dic[name] = gyro_data[gname]
            
        return data_dic
    
    def __getitem__(self, index):
        return self.files[index]
    
    
def imu_to_lst(dic, key):
    axis = ['X', 'Y', 'Z']
    res = []
    
    for ax in axis:
        x = key + ax
        res.append(dic[x])
    
    return res
    
def plot_lst(datas, title):
    for i, data in enumerate(datas):
        plot_graph(data, title = title + "{}".format(i))

        
def plot_lst_lim(datas, ylim = [-1.0, 1.0], title = 'title'):
    for i, data in enumerate(datas):
        plot_graph_lim(data, ylim = ylim, title = title + "{}".format(i))
        
def plot_gyro(data):
    lst = ['gyro' + x for x in ['X', 'Y', 'Z']]
    
    for l in lst:
        plot_graph(data[l], title= l)
        
def plot_mag(data):
    lst = ['mag' + x for x in ['X', 'Y', 'Z']]
    
    for l in lst:
        plot_graph(data[l], title= l)

def plot_acc(data):
    lst = ['acc' + x for x in ['X', 'Y', 'Z']]
    
    for l in lst:
        plot_graph(data[l], title = l) 
    
def gyro_angle(imu, sr = 0.01):
    radian_to_angle = 57.29578
    gyro = imu_to_lst(imu, 'gyro')
    
    angle_value = [[] for _ in range(3)]
    angle_var = [[] for _ in range(3)]
    
    for i, axis in enumerate(gyro):
        angle = 0
        
        for f in axis:
            delta = f * radian_to_angle * sr
            angle_value[i].append(delta)
            angle = angle + delta
            angle_var[i].append(angle)
        print('angle {}: {}'.format(i, angle))
   
    return angle_value, angle_var

def get_gradient(data):
    g = []
    for axis in data:
        g.append(np.ediff1d(np.array(axis)))
    return g