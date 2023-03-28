#!/usr/bin/env python
# coding: utf-8

# In[ ]:


# Show Values
import numpy as np

def show_datas(datas, labels):
    '''
    in : DataProcess, labels
    out : none
    Show all label's mean, var in DataProcess (x, y, z)
    '''
    
    data_dic = {k : [] for k in labels}
    for data in datas:
        data_dic[data[2]].append(data[1])

    for key, value in data_dic.items():
        xyz = [[] for _ in range(3)]
    
        for lst in value:
            for i in range(3):
                xyz[i].append(lst[i])

        x = np.array(xyz[0])
        y = np.array(xyz[1])
        z = np.array(xyz[2])

        print("{} \nMean {}, {}, {}\nvar : {}, {}, {}".format(key,np.mean(x), np.mean(y), np.mean(z), np.var(x),np.var(y),np.var(z)))
        print()
    
def show_values(data, label, target_label):
    '''
    in : DataFrame, labels, target label
    out : none
    Show target label's values and mean, var
    '''
    lst = [[] for _ in range(3)]

    for i in range(len(label)):
        if label[i] == target_label:
            print(data['magX'][i], "   ", data['magY'][i], "   ", data['magZ'][i])

        for s, d in enumerate(['magX', 'magY', 'magZ']):
            lst[s].append(data[d][i])
        
    for i in range(3):
        tmp = np.array(lst[i])
        print('Mean : ', tmp.mean(), "  Var : ", tmp.var())


def show_df(df, labels):
    '''
    in : DataFrame, labels
    out : none
    Show all label's Mean, var(x, y, z)
    
    '''

    show_dict = {l : [] for l in labels}
    mag = ['magX', 'magY', 'magZ']
    
    l = len(df['Label'].tolist())
    
    for i in range(l):
        data = []
        for m in mag:
            data.append(df[m][i])
            
        show_dict[df['Label'][i]].append(data)
    
    for key, value in show_dict.items():
        xyz = [[] for _ in range(3)]
    
        for lst in value:
          for i in range(3):
            xyz[i].append(lst[i])

        x = np.array(xyz[0])
        y = np.array(xyz[1])
        z = np.array(xyz[2])
        
        print("{} \nMean {}, {}, {}\nvar : {}, {}, {}\n".
              format(key,np.mean(x),np.mean(y), np.mean(z), np.var(x),np.var(y),np.var(z)))

def show_labels_total(df):
    '''
    in : DataFrame
    out : none
    Show all label's total
    '''
    
    l = len(df['Label'].to_list())
    mag = ['magX', 'magY', 'magZ']
    
    for i in range(l):
        total = 0
        
        for m in mag:
            total += math.pow(df[m][i], 2)
        
        print('{} total : {}'.format(df['Label'][i], math.sqrt(total)))

def get_label_diff(dp, tar_label):
    '''
    in : DataProcess, Target label
    out : none
    Show Target label's difference of x,y,z
    '''
    
    for data in dp:
        if data[2] == tar_label:
            print(data[1])

