#!/usr/bin/env python
# coding: utf-8

# In[ ]:


from matplotlib import pyplot as plt

def plot_graph(graph, title = "title", emp = []):
  fig, ax = plt.subplots()
  plt.title(title)
  ax.plot(graph)
  for points in emp:
    ax.plot(points[0], graph[points[0]], marker = 'o', markersize = 4, color = 'red')
    ax.plot(points[1], graph[points[1]], marker = 's', markersize = 4, color = 'green')
   
  plt.show()

def df_to_data(df, labels):
    '''
    in : DataFrame, labels
    out : data
    Convert DataFrame to dictionary for plotting data
    '''
    keys= ['magX', 'magY', 'magZ']
  
    res = {l : [[] for _ in range(3)] for l in labels}

    print('Total label : ', len(df['Label']))
    for i in range(len(df['Label'])):
    
      for j, key in enumerate(keys):
          if df['Label'][i] in labels:
              res[df['Label'][i]][j].append(df[key][i])
  
    return res


def prepare_data(datas, label, labels):
    '''
    in : DataProcess, label, labels
    out : target label's xyz
    '''
    data_dic = {k : [] for k in labels}
    for data in datas:
        if data[2] == label:
            data_dic[data[2]].append(data[1])
    

    for key, value in data_dic.items():
        if key != label:
            continue
    
        xyz = [[] for _ in range(3)]

        for lst in value:
            for i in range(3):
                xyz[i].append(lst[i])
    
    return xyz

def plot_data(datas, height = 10, angle = 30, colors = ['g', 'b', 'r', 'c', 'm', 'y'], title = "Title"):
    fig = plt.figure(figsize=(10, 10))
    ax = fig.add_subplot(projection='3d')

    for idx, data in enumerate(datas):
        ax.scatter(data[0], data[1], data[2], color = colors[idx])
    
    ax.view_init(height, angle)
    plt.title(title)
    plt.show()


def plot_df(df, color_dict, labels, title = "result", height = 30, angle = 30):
    '''
    labels --> labels that want to plot (list)
    '''
    
    dic = df_to_data(df, labels)
    fig = plt.figure(figsize=(10, 10))
    ax = fig.add_subplot(projection='3d')
    print('plot_df func')
    for key, data in dic.items():
        print('key is ', key, ' len is', len(data[0]), 'color : ', color_dict[key])
        ax.scatter(data[0], data[1], data[2], color = color_dict[key], label = key)

    ax.view_init(height, angle)
    plt.legend(loc='center left', bbox_to_anchor=(1, 0.5))
    plt.title(title)
    plt.show()
    

def plot_two(a, b, title = 'title', height = 30, angle = 30):
    '''
    plot two data
    '''
    fig = plt.figure(figsize=(10, 10))
    ax = fig.add_subplot(projection='3d')

    for idx, data in enumerate(a):
        ax.scatter(data[0], data[1], data[2], color = 'r')

    for idx, data in enumerate(b):
        ax.scatter(data[0], data[1], data[2], color = 'g')

    print('Len a : {} b : {}'.format(len(a[0][0]), len(b[0][0])))

    ax.view_init(height, angle)
    plt.title(title)
    plt.show()

def plot_two_dp(dp1, dp2, label, colors, height = 30, angle = 30, title = "Title"):
    p1 = prepared_data(dp1, label)
    p2 = prepared_data(dp2, label)

    fig = plt.figure(figsize=(10, 10))
    ax = fig.add_subplot(projection='3d')

    for idx, data in enumerate(p1):
        ax.scatter(data[0], data[1], data[2], color = colors[idx])
  
    for idx, data in enumerate(p2):
        ax.scatter(data[0], data[1], data[2], color = colors[idx])

    ax.view_init(height, angle)
    plt.title(title)
    plt.show()
    
def df_to_dic(df):
    data_dic = {}
    
    l = len(df['Label'])
    
    for idx in range(l):
        label = df['Label'][idx]
        
        if label not in data_dic:
            data_dic[label] = [[] for _ in range(3)]
        
        for i, mag in enumerate(['magX', 'magY', 'magZ']):
            data_dic[label][i].append(df[mag][idx])
    return data_dic
    
def plot_dics(dics, color_lst, func = None, title = 'title', height = 30, angle = 30):
    fig = plt.figure(figsize=(10, 10))
    ax = fig.add_subplot(projection='3d')
    
    for idx, dic in enumerate(dics):
        colors = color_lst[idx]
        cidx = 0
        for label, value in dic.items():
            print('{} color is {}'.format(label, colors[cidx]))
            ax.scatter(value[0], value[1], value[2], color = colors[cidx])
            cidx+=1
    
    ax.view_init(height, angle)
    plt.title(title)
    plt.show()
    
def plot_df_color_lst(df, colors, title = 'title', height = 30, angle = 30):
    '''
    plot dataframe
    '''
    fig = plt.figure(figsize=(10, 10))
    ax = fig.add_subplot(projection='3d')
    data_dic = {}
    
    l = len(df['Label'])
    
    for idx in range(l):
        label = df['Label'][idx]
        
        if label not in data_dic:
            data_dic[label] = [[] for _ in range(3)]
        
        for i, mag in enumerate(['magX', 'magY', 'magZ']):
            data_dic[label][i].append(df[mag][idx])
    
    idx = 0
    for ls, value in data_dic.items():
        ax.scatter(value[0], value[1], value[2], color = colors[idx])
        idx+=1
    
    ax.view_init(height, angle)
    plt.title(title)
    #plt.legend(loc="upper right")
    plt.show()
   
    
def plot_graphs(feature, key):
    '''
    in : Feature, key(acc, mag, gyro)
    out : none
    Plot imu's 3-axis data
    '''
    xyz = ['X', 'Y', 'Z']
    print(feature)
    
    for axis in xyz:
        name = key + axis
        print(name)
        plot_graph(feature.data[name], title = name)